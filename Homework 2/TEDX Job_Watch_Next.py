#FILTRAGGIO TAGS
filtered_dataset=tedx_dataset_agg
filtered_dataset=tedx_dataset_agg.filter(size(array_intersect(col("tags"),array(lit("music"),lit("performance"))))==2)

#PRINT FILTERED DATASET
filtered_dataset.printSchema()
filtered_dataset.show()

filtered_dataset = filtered_dataset.withColumn("duration_int", col("duration").cast(IntegerType()))

#CONVERT DURATION INTO MINUTES:SECONDS
def convert_safe(seconds):
    if seconds is None:
        return None
    try:
        seconds = int(seconds)
        minutes = seconds // 60
        seconds %= 60
        return f"{minutes:02d}:{seconds:02d}"
    except Exception as e:
        return None

#convertUDF=udf(lambda m:convert(m))
convertUDF = udf(convert_safe, StringType())
filtered_dataset = filtered_dataset.withColumn("duration", convertUDF(col("duration_int"))).drop("duration_int")
#filtered_dataset_converted=filtered_dataset.select(col("*"),convertUDF(col("duration").alias("duration_Sec")))
filtered_dataset.show()

write_mongo_options = {
    "connectionName": "TEDX",
    "database": "unibg_tedx_2025",
    "collection": "tedify",
    "ssl": "true",
    "ssl.domain_match": "false"}
from awsglue.dynamicframe import DynamicFrame
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(filtered_dataset, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)