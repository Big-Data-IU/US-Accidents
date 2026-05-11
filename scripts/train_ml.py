#!/usr/bin/env python3
"""Stage III: multiclass severity prediction."""

import os
import sys
from pathlib import Path
from typing import List, NamedTuple, Tuple

_SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(_SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_ROOT))

# pylint: disable=wrong-import-position,import-error
from ml.transformers import CyclicalTimestampTransformer, LatLngToEcefTransformer
from pyspark import StorageLevel
from pyspark.ml import Pipeline
from pyspark.ml.classification import LogisticRegression, RandomForestClassifier
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.ml.feature import StandardScaler, StringIndexer, VectorAssembler
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.dataframe import DataFrame


BOOL_FEATURES = [
    "amenity",
    "bump",
    "crossing",
    "give_way",
    "junction",
    "no_exit",
    "railway",
    "roundabout",
    "station",
    "stop",
    "traffic_calming",
    "traffic_signal",
    "turning_loop",
]

CAT_FEATURES = [
    "source",
    "timezone",
    "airport_code",
    "wind_direction",
    "weather_condition",
    "sunrise_sunset",
    "civil_twilight",
    "nautical_twilight",
    "astronomical_twilight",
    "state",
]

NUM_FEATURES = [
    "distance_mi",
    "temperature_f",
    "wind_chill_f",
    "humidity_pct",
    "pressure_in",
    "visibility_mi",
    "wind_speed_mph",
    "precipitation_in",
]

CYCLICAL_COLS = [
    "year_num",
    "month_sin",
    "month_cos",
    "day_sin",
    "day_cos",
    "hour_sin",
    "hour_cos",
]

ECEF_COLS = ["ecef_x", "ecef_y", "ecef_z"]


class _MlDataContext(NamedTuple):
    """Train/test frames, feature columns, HDFS paths for JSON splits."""

    train_df: DataFrame
    test_df: DataFrame
    cats: List[str]
    nums: List[str]
    bools: List[str]
    hdfs_prefix: str
    train_json: str
    test_json: str


def _spark_session() -> SparkSession:
    team = os.getenv("SPARK_TEAM_NAME", "team31")
    warehouse = os.getenv("SPARK_WAREHOUSE_DIR", "project/hive/warehouse")
    metastore = os.getenv(
        "HIVE_METASTORE_URIS",
        "thrift://hadoop-02.uni.innopolis.ru:9883",
    )
    return (
        SparkSession.builder.appName(f"{team} - spark ML")
        .master("yarn")
        .config("hive.metastore.uris", metastore)
        .config("spark.sql.warehouse.dir", warehouse)
        .config("spark.sql.avro.compression.codec", "snappy")
        .enableHiveSupport()
        .getOrCreate()
    )


def _prepare_frame(spark: SparkSession, db: str, table: str):
    """Load Hive table and apply lightweight cleaning (no fitted estimators yet)."""
    full_name = f"{db}.{table}"
    frame = spark.table(full_name)

    existing_cols = set(frame.columns)
    cats = [c for c in CAT_FEATURES if c in existing_cols]
    nums = [c for c in NUM_FEATURES if c in existing_cols]
    bools = [c for c in BOOL_FEATURES if c in existing_cols]

    needed = {"severity", "start_time", "start_lat", "start_lng"}
    missing = needed - existing_cols
    if missing:
        raise ValueError(f"Hive table {full_name} missing columns: {sorted(missing)}")

    selected = ["severity", "start_time", "start_lat", "start_lng"] + cats + nums + bools
    frame = frame.select(*selected)

    frame = frame.filter(F.col("severity").isNotNull())
    frame = frame.filter(F.col("start_time").isNotNull())
    frame = frame.filter(F.col("start_lat").isNotNull())
    frame = frame.filter(F.col("start_lng").isNotNull())
    frame = frame.filter(F.col("severity").between(1, 4))

    for name in cats:
        frame = frame.withColumn(name, F.coalesce(F.col(name), F.lit("unknown")))
    if nums:
        frame = frame.na.fill(0.0, subset=nums)
    for name in bools:
        frame = frame.withColumn(name, F.coalesce(F.col(name), F.lit(False)))

    for name in bools:
        frame = frame.withColumn(name, F.col(name).cast("double"))

    frame = frame.withColumn("label", F.col("severity").cast("double") - F.lit(1.0))

    cast_nums = [F.col(c).cast("double").alias(c) for c in nums]
    frame = frame.select(
        *[F.col(c) for c in cats],
        *cast_nums,
        *[F.col(c) for c in bools],
        F.col("severity"),
        F.col("label"),
        F.col("start_time"),
        F.col("start_lat"),
        F.col("start_lng"),
    )
    return frame, cats, nums, bools


def _feature_pipeline(indexed_cols: List[str], nums: List[str], bools: List[str]) -> Pipeline:
    """Featurisation only (cyclical time, ECEF, categoricals, scaling)."""
    cyclical = CyclicalTimestampTransformer(inputCol="start_time")
    ecef = LatLngToEcefTransformer(latCol="start_lat", lngCol="start_lng")
    indexers = [
        StringIndexer(inputCol=c, outputCol=f"{c}_idx", handleInvalid="keep")
        for c in indexed_cols
    ]
    assembler_inputs = (
        [f"{c}_idx" for c in indexed_cols]
        + CYCLICAL_COLS
        + ECEF_COLS
        + nums
        + bools
    )
    assembler = VectorAssembler(
        inputCols=assembler_inputs,
        outputCol="features",
        handleInvalid="skip",
    )
    scaler = StandardScaler(
        inputCol="features",
        outputCol="scaledFeatures",
        withStd=True,
        withMean=False,
    )
    return Pipeline(stages=[cyclical, ecef] + indexers + [assembler, scaler])


def _full_pipeline_classifier(
    classifier_stage,
    indexed_cols: List[str],
    nums: List[str],
    bools: List[str],
):
    """Append a classifier stage to the featurisation pipeline."""
    feat_pipe = _feature_pipeline(indexed_cols, nums, bools)
    stages = list(feat_pipe.getStages()) + [classifier_stage]
    return Pipeline(stages=stages)


def _evaluate(pred_df) -> Tuple[float, float]:
    acc_ev = MulticlassClassificationEvaluator(
        labelCol="label",
        predictionCol="prediction",
        metricName="accuracy",
    )
    f1_ev = MulticlassClassificationEvaluator(
        labelCol="label",
        predictionCol="prediction",
        metricName="f1",
    )
    return float(acc_ev.evaluate(pred_df)), float(f1_ev.evaluate(pred_df))


def _cross_val_parallelism() -> int:
    """Worker threads/processes passed to Spark CrossValidator.parallelism."""
    return int(os.getenv("CV_PARALLELISM", "4"))


def _write_json_feature_splits(
    model,
    ctx: _MlDataContext,
    json_parts: int,
) -> None:
    """Persist train/test rows as JSON with `features` + `label` (best RF pipeline)."""
    feat_cols = (
        F.col("scaledFeatures").alias("features"),
        F.col("label"),
    )
    model.transform(ctx.train_df).select(*feat_cols).coalesce(
        json_parts,
    ).write.mode("overwrite").json(ctx.train_json)
    model.transform(ctx.test_df).select(*feat_cols).coalesce(
        json_parts,
    ).write.mode("overwrite").json(ctx.test_json)


def _fit_random_forest(
    ctx: _MlDataContext,
    f1_evaluator: MulticlassClassificationEvaluator,
):
    """Cross-validate RF, write JSON splits, model, CSV predictions; return metrics."""
    rf_base = RandomForestClassifier(
        labelCol="label",
        featuresCol="scaledFeatures",
        predictionCol="prediction",
        seed=42,
    )
    rf_pipeline = _full_pipeline_classifier(
        rf_base, ctx.cats, ctx.nums, ctx.bools,
    )
    rf_estimator = rf_pipeline.getStages()[-1]
    rf_grid = (
        ParamGridBuilder()
        .addGrid(rf_estimator.numTrees, [40, 80, 120])
        .addGrid(rf_estimator.maxDepth, [6, 10])
        .build()
    )
    assert len(rf_grid) >= 6
    rf_cv = CrossValidator(
        estimator=rf_pipeline,
        estimatorParamMaps=rf_grid,
        evaluator=f1_evaluator,
        numFolds=3,
        parallelism=_cross_val_parallelism(),
        seed=91,
    )
    best_rf_model = rf_cv.fit(ctx.train_df).bestModel

    json_parts = int(os.getenv("JSON_PARTITIONS", "8"))
    _write_json_feature_splits(best_rf_model, ctx, json_parts)

    models_path = f"{ctx.hdfs_prefix}/models/model1"
    best_rf_model.write().overwrite().save(models_path)
    test_predictions = best_rf_model.transform(ctx.test_df)
    rf_acc, rf_f1 = _evaluate(test_predictions)
    preds = test_predictions.select("label", "prediction").coalesce(1)
    out_path = f"{ctx.hdfs_prefix}/output/model1_predictions"
    preds.write.mode("overwrite").option("header", True).csv(out_path)

    return best_rf_model, rf_acc, rf_f1


def _fit_logistic_regression(
    ctx: _MlDataContext,
    f1_evaluator: MulticlassClassificationEvaluator,
):
    """Cross-validate multinomial logistic model; persist model and predictions."""
    lr_base = LogisticRegression(
        family="multinomial",
        labelCol="label",
        featuresCol="scaledFeatures",
        predictionCol="prediction",
        maxIter=100,
        standardization=False,
    )
    lr_pipeline = _full_pipeline_classifier(
        lr_base, ctx.cats, ctx.nums, ctx.bools,
    )
    lr_estimator = lr_pipeline.getStages()[-1]
    lr_grid = (
        ParamGridBuilder()
        .addGrid(lr_estimator.regParam, [1e-3, 1e-2, 5e-2])
        .addGrid(lr_estimator.elasticNetParam, [0.0, 0.5])
        .build()
    )
    assert len(lr_grid) >= 6
    lr_cv = CrossValidator(
        estimator=lr_pipeline,
        estimatorParamMaps=lr_grid,
        evaluator=f1_evaluator,
        numFolds=3,
        parallelism=_cross_val_parallelism(),
        seed=92,
    )
    best_lr_model = lr_cv.fit(ctx.train_df).bestModel
    models_path = f"{ctx.hdfs_prefix}/models/model2"
    best_lr_model.write().overwrite().save(models_path)

    test_pred = best_lr_model.transform(ctx.test_df)
    lr_acc, lr_f1 = _evaluate(test_pred)
    lr_csv = test_pred.select("label", "prediction").coalesce(1)
    out_path = f"{ctx.hdfs_prefix}/output/model2_predictions"
    lr_csv.write.mode("overwrite").option("header", True).csv(out_path)

    return best_lr_model, lr_acc, lr_f1


def _run_models_and_eval(spark: SparkSession, ctx: _MlDataContext) -> None:
    """Run both model pipelines and write the evaluation summary to HDFS."""
    f1_evaluator = MulticlassClassificationEvaluator(
        labelCol="label",
        predictionCol="prediction",
        metricName="f1",
    )
    best_rf_model, rf_acc, rf_f1 = _fit_random_forest(ctx, f1_evaluator)
    best_lr_model, lr_acc, lr_f1 = _fit_logistic_regression(ctx, f1_evaluator)
    comparison = spark.createDataFrame(
        [
            (str(best_rf_model.stages[-1]), rf_acc, rf_f1),
            (str(best_lr_model.stages[-1]), lr_acc, lr_f1),
        ],
        ["model", "accuracy", "f1"],
    )
    eval_path = f"{ctx.hdfs_prefix}/output/evaluation"
    comparison.coalesce(1).write.mode("overwrite").option("header", True).csv(
        eval_path,
    )


def main() -> None:
    """Tune RF and logistic models on train, persist splits, artefacts, and metrics."""
    hdfs_prefix = os.getenv("HDFS_PREFIX", "project").rstrip("/")
    spark = _spark_session()
    spark.sparkContext.setLogLevel(os.getenv("SPARK_LOG_LEVEL", "WARN"))
    hive_db = os.getenv("HIVE_DB_NAME", "team31_projectdb")
    hive_table = os.getenv("HIVE_TABLE_NAME", "us_accidents_part_buck")

    prepared, cats, nums, bools = _prepare_frame(spark, hive_db, hive_table)
    prepared = prepared.persist(StorageLevel.MEMORY_AND_DISK)
    train_df, test_df = prepared.randomSplit([0.6, 0.4], seed=17)

    ctx = _MlDataContext(
        train_df=train_df,
        test_df=test_df,
        cats=cats,
        nums=nums,
        bools=bools,
        hdfs_prefix=hdfs_prefix,
        train_json=f"{hdfs_prefix}/data/train",
        test_json=f"{hdfs_prefix}/data/test",
    )
    _run_models_and_eval(spark, ctx)
    spark.stop()


if __name__ == "__main__":
    main()
