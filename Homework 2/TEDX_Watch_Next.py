###### TEDx-Load-Aggregate-Model
######

import sys
import json
import pyspark
from pyspark.sql.functions import col, collect_list, array_join, array_intersect, size, array, lit, udf
from pyspark.sql.types import StringType, IntegerType
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

from pyspark.sql.functions import array_contains
from functools import reduce


##### FROM FILES
tedx_dataset_path = "s3://dc-data-2025/final_list.csv"

###### READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

##### START JOB CONTEXT AND JOB
sc = SparkContext()


glueContext = GlueContext(sc)
spark = glueContext.spark_session


    
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


#### READ INPUT FILES TO CREATE AN INPUT DATASET
tedx_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)
    
tedx_dataset.printSchema()


#### FILTER ITEMS WITH NULL POSTING KEY
count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()

print(f"Number of items from RAW DATA {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY {count_items_null}")

## READ THE DETAILS
details_dataset_path = "s3://dc-data-2025/details.csv"
details_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path)

details_dataset = details_dataset.select(col("id").alias("id_ref"),
                                         col("description"),
                                         col("duration"),
                                         col("publishedAt"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_main = tedx_dataset.join(details_dataset, tedx_dataset.id == details_dataset.id_ref, "left") \
    .drop("id_ref")

tedx_dataset_main.printSchema()

## READ TAGS DATASET
tags_dataset_path = "s3://dc-data-2025/tags.csv"
tags_dataset = spark.read.option("header","true").csv(tags_dataset_path)


# CREATE THE AGGREGATE MODEL, ADD TAGS TO TEDX_DATASET
tags_dataset_agg = tags_dataset.groupBy(col("id").alias("id_ref")).agg(collect_list("tag").alias("tags"))
tags_dataset_agg.printSchema()
tedx_dataset_agg = tedx_dataset_main.join(tags_dataset_agg, tedx_dataset.id == tags_dataset_agg.id_ref, "left") \
    .drop("id_ref") \
    .select(col("id").alias("_id"), col("*")) \
    .drop("id") \

tedx_dataset_agg.printSchema()

#READ RELATED VIDEOS AND REMOVE DUPLICATES
related_videos_path = "s3://dc-data-2025/related_videos.csv"
related_videos_dataset = spark.read.option("header", "true").csv(related_videos_path).dropDuplicates()

# Fai un self-join tra related_videos e i video effettivamente presenti nel dataset
# cioè: tieni solo i related_id che sono presenti in tedx_dataset_agg._id

# Prima rinominiamo le colonne per chiarezza
related_videos_dataset = related_videos_dataset.withColumnRenamed("id", "main_id").withColumnRenamed("related_id", "related_id_raw")

# Teniamo solo i related_id che sono presenti nel dataset
related_videos_filtered = related_videos_dataset.join(
    tedx_dataset_agg.select(col("_id").alias("valid_related_id")),
    related_videos_dataset.related_id_raw == col("valid_related_id"),
    "inner"
).drop("valid_related_id")

# Ora possiamo aggregare i related_id filtrati
related_videos_dataset_agg = related_videos_filtered.groupBy(col("main_id").alias("id_watch_next")) \
    .agg(collect_list("related_id_raw").alias("Watch_next_id"))

#ADD RELATED VIDEOS TO AGGREGATE MODEL
tedx_dataset_agg = tedx_dataset_agg.join(
    related_videos_dataset_agg,
    tedx_dataset_agg._id == related_videos_dataset_agg.id_watch_next,
    "left"
).drop("id_watch_next")


write_mongo_options = {
    "connectionName": "TEDX",
    "database": "unibg_tedx_2025",
    "collection": "tedx_data",
    "ssl": "true",
    "ssl.domain_match": "false"}
from awsglue.dynamicframe import DynamicFrame
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)