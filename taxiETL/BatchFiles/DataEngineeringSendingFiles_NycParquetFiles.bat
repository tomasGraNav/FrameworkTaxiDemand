echo Envío de archivos a Rstudio
robocopy "C:\Users\tgran\Desktop\TFM_WorkFlow\taxiETL\data\parquetFiles\Taxis.parquet" "C:\Users\tgran\Desktop\TFM_WorkFlow\taxi_R_Project\input\inputData\Taxis.parquet" /move /s /z /r:1 /w:5 /v

echo Envío de archivos al DataStorage
robocopy "C:\Users\tgran\Desktop\TFM_WorkFlow\taxiETL\data\parquetFiles\TaxisLocation.parquet" "F:\backupStorage\NycTaxiData" /move /s /z /r:1 /w:5 /v

echo Envío de archivos a Tableau Prep Builder
robocopy "C:\Users\tgran\Desktop\TFM_WorkFlow\taxiETL\data\csvFiles\TableauLocationData" "C:\Users\tgran\Documents\Mi Repositorio de Tableau Prep\Fuentes de datos" /move /s /z /r:1 /w:5 /v

PAUSE