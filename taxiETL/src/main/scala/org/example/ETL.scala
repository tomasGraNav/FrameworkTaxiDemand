package org.example

import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types.{DoubleType, IntegerType}
import scala.util.Try
import org.apache.commons.io.FileUtils
import java.io.File


object ETL {

  def main(args: Array[String]): Unit = {

    implicit val spark: SparkSession = SparkSession
      .builder()
      .master("local[*]")
      .appName("taxiETL")
      .getOrCreate()

    spark.sparkContext.setLogLevel("ERROR")

    val csvFiles = "data/csvFiles/NYCYellowCabs/*.csv"
    val taxisParquet = "data/parquetFiles/Taxis.parquet"
    val dataYear = "2019"


    extractionTransformationLoad(csvFiles, taxisParquet, dataYear)

  }

  def extractionTransformationLoad(readPath: String, parquetPath: String, dataYear: String)
                                  (implicit spark: SparkSession): Unit = {

    val taxisLocationParquet = "data/parquetFiles/TaxisLocation.parquet"
    val pathWritePickupCSV = "data/csvFiles/TableauLocationData/pickupLocation.csv"
    val pathWriteDropoffCSV = "data/csvFiles/TableauLocationData/dropoffLocation.csv"

    val deleteCSVEntryFiles = "data/csvFiles/NYCYellowCabs"

    //EXTRACTION
    val dfTmp = spark.read
      .format("csv")
      .option("header", "true")
      .option("inferSchema", "true")
      .option("delimiter", ",")
      .load(readPath)

    //TRANSFORMATION
    val df = dfTmp.select(dfTmp.columns.map(x => col(x).as(x.toLowerCase)): _*)
      .withColumn("date", concat(lit(dataYear),
        date_format(col("pickup_datetime"), "yyyy-MM-dd").substr(5, 11)))
      .withColumn("year", col("date").substr(0, 4))
      .withColumn("month", col("date").substr(6, 2))
      .withColumn("passengers", col("passenger_count").cast(IntegerType))
      .withColumn("payment",
        when(col("payment_type") === "CASH" || col("payment_type") === "Cash" ||
          col("payment_type") === "CSH" || col("payment_type") === 2, "cash")
          .when(col("payment_type") === "CREDIT" || col("payment_type") === "Credit" ||
            col("payment_type") === "CRD" || col("payment_type") === 1, "credit")
          .when(col("payment_type") === "No Charge" || col("payment_type") === "NOC" ||
            col("payment_type") === 3, "no charge")
          .when(col("payment_type") === "Dispute" || col("payment_type") === "DIS" ||
            col("payment_type") === 4, "dispute")
          .otherwise("unknown"))

    if (columnExist(df, "pickup_longitude") == false) {

      //Analisis
      df.select("date", "passengers", "trip_distance", "payment", "year", "month")
        .filter(df("date").isNotNull)
        //LOAD
        .write
        .partitionBy("year")
        .mode("append")
        .parquet(parquetPath)

    } else {

      //1_Analisis
      df.select("date", "passengers", "trip_distance", "payment", "year", "month")
        .filter(df("date").isNotNull)
        //LOAD
        .write
        .partitionBy("year")
        .mode("append")
        .parquet(parquetPath)

      //2_Location
      df.withColumn("trip_distance", col("trip_distance").cast(DoubleType))
        .withColumn("pickup_lon", col("pickup_longitude").substr(0, 7).cast(DoubleType))
        .withColumn("pickup_lat", col("pickup_latitude").substr(0, 6).cast(DoubleType))
        .withColumn("dropoff_lon", col("dropoff_longitude").substr(0, 7).cast(DoubleType))
        .withColumn("dropoff_lat", col("dropoff_latitude").substr(0, 6).cast(DoubleType))
        .select("pickup_lon", "pickup_lat", "dropoff_lon", "dropoff_lat", "year")
        .filter(col("pickup_lon").isNotNull && col("pickup_lat").isNotNull &&
          col("dropoff_lon").isNotNull && col("dropoff_lat").isNotNull)
        .filter(col("pickup_lon") > -75 && col("pickup_lon") < -73.3 &&
          col("dropoff_lon") > -75 && col("dropoff_lon") < -73.3 &&
          col("pickup_lat") > 40 && col("pickup_lat") < 41.5 &&
          col("dropoff_lat") > 40 && col("dropoff_lat") < 41.5)
        //LOAD
        .write.partitionBy("year")
        .mode("append")
        .parquet(taxisLocationParquet)
    }

    if (dataYear = "2019") {
      val dfLocation = readParquet(taxisLocationParquet)

      dfLocation.select(col("pickup_lon"), col("pickup_lat"))
        .groupBy(col("pickup_lon"), col("pickup_lat"))
        .count()
        .filter(col("count") > 25)
        .repartition(1)
        .write
        .option("header", "true")
        .csv(pathWritePickupCSV)

      dfLocation.select(col("dropoff_lon"), col("dropoff_lat"))
        .groupBy(col("dropoff_lon"), col("dropoff_lat"))
        .count()
        .filter(col("count") > 25)
        .repartition(1)
        .write
        .option("header", "true")
        .csv(pathWriteDropoffCSV)
    }


//    Deleting csv files on Read Path
    FileUtils.cleanDirectory(new File(deleteCSVEntryFiles))

  }

  def columnExist(dframe: DataFrame, nameCol: String) = Try(dframe(nameCol)).isSuccess

  def readParquet(pathRead: String)(implicit spark: SparkSession): DataFrame = {
    spark.read
      .option("mergeSchema", "true")
      .parquet(pathRead)
  }

}