"""Custom Spark ML transformers for cyclical time encoding and lat/lng → ECEF."""

from __future__ import annotations

import math

from pyspark import keyword_only
from pyspark.ml import Transformer
from pyspark.ml.param.shared import HasInputCol, Param, Params, TypeConverters
from pyspark.ml.util import DefaultParamsReadable, DefaultParamsWritable
import pyspark.sql.functions as F


class CyclicalTimestampTransformer(
    Transformer,
    DefaultParamsReadable,
    DefaultParamsWritable,
    HasInputCol,
):
    """Expand a timestamp column into year + sin/cos pairs for month, day-of-month, hour."""

    @keyword_only
    def __init__(self, inputCol="start_time"):  # noqa: N803 — Spark ML naming
        super().__init__()
        kwargs = self._input_kwargs
        self._setDefault(inputCol=inputCol)
        self._set(**kwargs)

    def _transform(self, dataset):
        col_name = self.getInputCol()
        pi2 = F.lit(2 * math.pi)
        month = F.month(F.col(col_name)).cast("double")
        day = F.dayofmonth(F.col(col_name)).cast("double")
        hour = F.hour(F.col(col_name)).cast("double")
        return (
            dataset.withColumn("year_num", F.year(F.col(col_name)).cast("double"))
            .withColumn("month_sin", F.sin(pi2 * (month - F.lit(1)) / F.lit(11.0)))
            .withColumn("month_cos", F.cos(pi2 * (month - F.lit(1)) / F.lit(11.0)))
            .withColumn("day_sin", F.sin(pi2 * (day - F.lit(1)) / F.lit(30.0)))
            .withColumn("day_cos", F.cos(pi2 * (day - F.lit(1)) / F.lit(30.0)))
            .withColumn("hour_sin", F.sin(pi2 * hour / F.lit(23.0)))
            .withColumn("hour_cos", F.cos(pi2 * hour / F.lit(23.0)))
        )


class LatLngToEcefTransformer(Transformer, DefaultParamsReadable, DefaultParamsWritable):
    """Convert geodetic WGS84 latitude/longitude (degrees) with altitude 0 into ECEF (x,y,z)."""

    latCol = Param(Params._dummy(), "latCol", "latitude column", typeConverter=TypeConverters.toString)
    lngCol = Param(Params._dummy(), "lngCol", "longitude column", typeConverter=TypeConverters.toString)

    @keyword_only
    def __init__(self, latCol="start_lat", lngCol="start_lng"):  # noqa: N803
        super().__init__()
        kwargs = self._input_kwargs
        self._setDefault(latCol=latCol, lngCol=lngCol)
        self._set(**kwargs)

    def setLatCol(self, value):  # noqa: N802
        return self._set(latCol=value)

    def setLngCol(self, value):  # noqa: N802
        return self._set(lngCol=value)

    def getLatCol(self):  # noqa: N802
        return self.getOrDefault(self.latCol)

    def getLngCol(self):  # noqa: N802
        return self.getOrDefault(self.lngCol)

    def _transform(self, dataset):
        lat_c = self.getLatCol()
        lng_c = self.getLngCol()

        rad_lat = F.radians(F.col(lat_c))
        rad_lon = F.radians(F.col(lng_c))
        a = F.lit(6378137.0)
        e2 = F.lit(6.6943799901413165e-3)
        h = F.lit(0.0)

        sin_lat = F.sin(rad_lat)
        cos_lat = F.cos(rad_lat)
        cos_lon = F.cos(rad_lon)
        sin_lon = F.sin(rad_lon)
        n_den = F.sqrt(F.lit(1.0) - e2 * sin_lat * sin_lat)
        n = a / n_den
        x = (n + h) * cos_lat * cos_lon
        y = (n + h) * cos_lat * sin_lon
        z = (n * (F.lit(1.0) - e2) + h) * sin_lat
        return dataset.withColumn("ecef_x", x).withColumn("ecef_y", y).withColumn("ecef_z", z)
