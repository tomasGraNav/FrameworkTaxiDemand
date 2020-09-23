# Sparklyr Connection -----------------------------------------------------

#Installing Spark
# spark_install("2.3")

#Increasing memory
conf  <-  spark_config()
conf$`sparklyr.shell.driver-memory` <- "10G"

#Spark Cluster connection
sc <- spark_connect(master = "local", version = "2.3", config = conf)



# Reading and Preprocesing Taxis.parquet ----------------------------------

taxiPrqt <- spark_read_parquet(sc, name = "Taxis",
                               path = "input/inputData/Taxis.parquet")

glimpse(taxiPrqt)

#Análisis variable year
taxiPrqt %>% group_by(date, year) %>%
  summarise("cantidad" = n()) %>% 
  group_by(year) %>% 
  count(name = "cantidad") %>% 
  arrange(desc(year))
#Aparecen 3 años bisiestos: 2012, 2016 y 2019. Este úlimo no es bisiesto

taxiPrqt %>% group_by(date, year) %>%
  summarise("cantidad" = n()) %>% 
  filter(date == "2019-02-29") #En efecto, existe un 29 de feb con 7 servicios




#Análisis variable passengers
taxiPrqt %>% select(passengers) %>% 
  group_by(passengers) %>% 
  summarise("cantidad" = n()) %>% 
  arrange(desc(passengers))
#Existen na's y cantidades enormes de pasajeros, se filtran >16
#las limousinas pueden llevar __ pasajeros


taxiPrqt %>% select(passengers) %>% 
  filter(is.na(passengers) | passengers > 16) %>% 
  count()
#Se filtran 248216 registros



#Análisis variable trip_distance
taxiPrqt %>% select(trip_distance) %>% 
  summarise(Maximum = max(trip_distance, na.rm = TRUE),
            Minimum = min(trip_distance, na.rm = TRUE))
#Existen distancias superiores a los kms de la circunferencia del planeta
#Se filtran aquellos viajes > 311 millas, unos 500kms

taxiPrqt %>% select(trip_distance) %>% 
  filter(trip_distance > 311 | trip_distance < 0) %>% 
  count() #Se filtran 11022 registros



#Análisis variable payment
taxiPrqt %>% select(payment) %>% 
  group_by(payment) %>% 
  summarise("cantidad" = n())



# Aggregated dataset and clean parquet tbl_df creation  -------------------

taxiPrqtClean <- taxiPrqt %>% 
  filter(date != "2019-02-29") %>% 
  filter(!is.na(passengers)) %>% 
  filter(passengers < 16) %>% 
  filter(trip_distance < 311) %>% 
  filter(trip_distance > 0)



aggTaxiData <- as_tibble(taxiPrqtClean %>% 
                           group_by(date, year) %>% 
                           summarise(cantidad = n()) %>% 
                           ungroup()) %>% 
  mutate(year = as.factor(year)) %>% 
  mutate(date = as.Date(date, "%Y-%m-%d"))


paymentType <- as_tibble(taxiPrqtClean %>% select(payment, year) %>% 
                           group_by(year, payment) %>% 
                           summarise("cantidad" = n())) 



passengers <- as_tibble(taxiPrqtClean %>% select(passengers, year) %>% 
                          filter(passengers > 0) %>% 
                          group_by(year, passengers) %>%
                          summarise("cantidad" = n()))


tripDistance <- as_tibble(taxiPrqtClean %>% select(trip_distance, year) %>% 
                            group_by(year) %>%
                            summarise("cantidad" = n()))
summary(TripDistance)


#Local Cluster disconnection
spark_disconnect(sc)
