#HOLT-WINTERS 

holt_wint <- HoltWinters(tsTrainingdata)
fitted(holt_wint)

forecast <- predict(holt_wint, n.ahead = dim(test_data)[1])
plot(holt_wint, forecast,xlab=NULL,main=NULL)

accuracy(forecast,tsTestdata) 



#SARIMA

autoArimaModel <- auto.arima(tsTrainingdata, D = 1, trace = TRUE)

summary(autoArimaModel)
# Best model: ARIMA(1,1,2)(0,1,0)[365]     


sarimaForecast <- autoArimaModel %>% forecast(h = dim(test_data)[1])
summary(sarimaForecast)

sarimaForecast %>% autoplot() + 
  labs(x = "", y = "", title = "") +
  scale_x_continuous(expand = c(0, 0)) +
  theme_classic() +
  theme(axis.text.x = elementTextY,
        axis.text.y = elementTextY)
  

accuracy(sarimaForecast, tsTestdata)



#TBATS

fitTrainTBATS <- tbats(tsTrainingdata)

plot(fitTrainTBATS)

demand_forecast <- forecast(fitTrainTBATS, h = 730)

autoplot(demand_forecast) + 
  labs(x = "", y = "", title = "") +
  scale_x_continuous(expand = c(0, 0)) +
  theme_classic() +
  theme(axis.text.x = elementTextY,
        axis.text.y = elementTextY)

accuracy(demand_forecast, tsTestdata)



#RRNN
fit <- nnetar(tsTrainingdata)

nnetarForecast <- forecast(fit, h = 730, PI = FALSE)

autoplot(nnetarForecast) + 
  labs(x = "", y = "", title = "") +
  scale_x_continuous(expand = c(0, 0)) +
  theme_classic() +
  theme(axis.text.x = elementTextY,
        axis.text.y = elementTextY)

accuracy(nnetarForecast, tsTestdata)


#PROPHET

phtTraining_data <- training_data %>% rename(ds = date, y = cantidad)

USholidays <- prophet()

USholidays <- add_country_holidays(USholidays,country_name = 'US')

jesus <- fit.prophet(USholidays, phtTraining_data)

future <- make_future_dataframe(jesus, periods = 730)
tail(future)

frcst <- predict(jesus, future)
tail(frcst[c("ds", "yhat", "yhat_lower", "yhat_upper")])

plot(jesus, frcst)  + 
  labs(x = "", y = "", title = "") +
  theme_classic() +
  theme(axis.text.x = elementTextY,
        axis.text.y = elementTextY)


prophet_plot_components(jesus, frcst)

df.cv <- cross_validation(jesus, initial = 730, period = 180, horizon = 730, units = 'days')
head(df.cv)

df.p <- performance_metrics(df.cv)
head(df.p)
mean(df.p$mae)



#PREDICTITION COMPARISON

predictionComparison <- test_data

predictionComparison$HoltWinters <- as.numeric(forecast)#HW
predictionComparison$Sarima <- sarimaForecast$mean#SARIMA 
predictionComparison$Tbats <- demand_forecast$mean#TBATS  
predictionComparison$Nnetar <- nnetarForecast$mean#NNETAR
predictionComparison$Prophet <- frcst$yhat[3288:4017]#PROPHET


#Graph with predictions

predictionComparison %>% 
  rename(TestData = cantidad) %>% 
  gather(key = "variable", value = "value", -date) %>% 
  ggplot(aes(x=date, y = value)) + 
  geom_line(aes(color = variable)) +
  labs(x = "", y = "") +
  theme_classic() + 
  theme(legend.title = element_blank(),
        legend.position = c(0.5, 0.08),
        axis.text.x = elementTextY,
        axis.text.y = elementTextY,
        legend.text = element_text(size=13, face="bold")) + 
  guides(colour = guide_legend(nrow = 1)) +
  scale_color_manual(values=c("olivedrab", "darksalmon", "steelblue", 
                              "deeppink2","darkgrey", "black"))

