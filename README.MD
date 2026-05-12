# Predicting The Severity of Traffic Accidents

## Overview
  

This project implements a comprehensive big data pipeline for predicting the severity of traffic accidents in the United States. Using the US Accidents dataset (2016-2023) from Kaggle, we build machine learning models to classify accident severity based on various features including weather conditions, time, location, and road characteristics.

  

The pipeline processes approximately 7.7 million accident records through multiple stages: data collection and preprocessing, storage in PostgreSQL and HDFS, analysis with Hive and Spark SQL, machine learning model training, and visualization via Streamlit dashboard.

## Team

- **Anna Belyakova** - [a.belyakova@innopolis.university](mailto:a.belyakova@innopolis.university)

- **Sofia Pushkareva** - [s.pushkareva@innopolis.university](mailto:s.pushkareva@innopolis.university)

- **Daria Alexandrova** - [d.alexandrova@innopolis.university](mailto:d.alexandrova@innopolis.university)

- **Aisylu Fattakhova** - [a.fattakhova@innopolis.university](mailto:a.fattakhova@innopolis.university)

  

## Technologies Used

  

- **Big Data Tools**: Hadoop HDFS, Apache Hive, Apache Spark

- **Databases**: PostgreSQL

- **Data Transfer**: Apache Sqoop

- **Machine Learning**: PySpark MLlib, Random Forest Classifier

- **Visualization**: Streamlit

- **Programming**: Python, Bash

- **Data Processing**: Pandas

- **Quality Assurance**: Pylint

  

## Pipeline Stages

  

The project consists of four main stages:

### Stage 1: Data Collection and Storage

- Download US Accidents dataset from Kaggle

- Preprocess and clean the data

- Store in PostgreSQL database

- Import data to HDFS using Sqoop

  

### Stage 2: Data Analysis with Hive

- Create Hive database and external Avro tables

- Perform analytical queries on accident data

- Generate partitioned and bucketed tables for optimization

  

### Stage 3: Machine Learning

- Train Random Forest models for severity prediction

- Feature engineering with custom transformers

- Model evaluation and performance metrics

- Save trained models to HDFS

  

### Stage 4: Visualization

- Streamlit dashboard for exploring predictions

- Interactive interface for model results

  

## Project Structure

  

```

├── data/                          # Dataset files and processed data

├── models/                        # Trained Spark ML models

│   ├── model1/                    # First ML model

│   └── model2/                    # Second ML model

├── notebooks/                     # Jupyter notebooks (for learning only)

├── output/                        # Pipeline outputs and results

│   ├── evaluation.csv            # Model evaluation metrics

│   ├── model1_predictions.csv    # Predictions from model 1

│   ├── model2_predictions.csv    # Predictions from model 2

│   ├── q1.csv - q7.csv           # Results from Hive queries

│   └── sqoop_generated/          # Sqoop-generated schema files

├── report/                        # LaTeX report and documentation

├── scripts/                       # Pipeline scripts

│   ├── ml/                       # Custom ML transformers

│   ├── build_projectdb.py        # PostgreSQL database setup

│   ├── data_collection.sh        # Dataset download script

│   ├── data_storage.sh           # PostgreSQL data loading

│   ├── import_to_hdfs.sh         # Sqoop import to HDFS

│   ├── postprocess.sh            # Post-processing tasks

│   ├── preprocess_data.py        # Data preprocessing

│   ├── preprocess.sh             # Preprocessing wrapper

│   ├── stage1.sh - stage4.sh     # Pipeline stage scripts

│   └── train_ml.py               # ML model training

├── sql/                          # SQL scripts for database operations

├── main.sh                       # Main pipeline execution script

├── requirements.txt              # Python dependencies

└── README.MD                     # This file

```

  

## Prerequisites

  

- Hadoop cluster access

- Hive server access

- PostgreSQL database

- Spark cluster

- Kaggle API credentials (for dataset download)

- Python 3.7+

  

## Installation

  

1. Clone the repository:
```

   git clone https://github.com/Big-Data-IU/US-Accidents

   cd US-Accidents
```

  

2. Install Python dependencies:

```
   pip install -r requirements.txt
```

  

3. Set up Kaggle credentials for dataset download:

```

   # Place kaggle.json in ~/.kaggle/ or set environment variables

   export KAGGLE_USERNAME=your_username

   export KAGGLE_KEY=your_key

```
  

4. Configure environment variables for Hive and HDFS access (see scripts for details)


## Usage

  

Run the complete pipeline using the main script:

  

```bash

bash main.sh

```

  

This will execute all stages sequentially:

- Preprocessing

- Stage 1: PostgreSQL + Sqoop

- Stage 2: Hive + Spark SQL

- Stage 3: Spark ML

- Stage 4: Streamlit

- Post-processing

- Code quality check with Pylint

  

### Individual Stages

You can run individual stages if needed:


```bash

# Stage 1: Data collection and storage

bash scripts/stage1.sh


# Stage 2: Hive analysis

bash scripts/stage2.sh


# Stage 3: ML training

bash scripts/stage3.sh


# Stage 4: Visualization

bash scripts/stage4.sh

```
  

## Dataset

The project uses the [US Accidents (2016-2023)](https://www.kaggle.com/datasets/sobhanmoosavi/us-accidents) dataset from Kaggle, containing:

- 7.7 million accident records

- 49 US states coverage

- Features: location, weather, time, road conditions, severity, etc.


## Machine Learning Models

Two Random Forest classifiers are trained:

- **Model 1**: Basic features

- **Model 2**: Enhanced with custom transformers (cyclical timestamp, ECEF coordinates)


Custom transformers include:

- CyclicalTimestampTransformer: Converts timestamps to cyclical features

- LatLngToEcefTransformer: Converts lat/lng to Earth-Centered Earth-Fixed coordinates


## Output Files
After running the pipeline, the following outputs are generated in the `output/` directory:

- `evaluation.csv`: Model performance metrics

- `model1_predictions.csv` & `model2_predictions.csv`: Prediction results

- `q1.csv` - `q7.csv`: Results from analytical queries

- `data_quality_stage1.txt`: Data quality assessment


## Quality Assurance

The pipeline includes automated code quality checks using Pylint for all Python scripts.

## License

This project is part of the Big Data course at Innopolis University.

