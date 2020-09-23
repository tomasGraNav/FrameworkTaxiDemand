# Data Sets ----------------------------------------------------------------

# Training and Test Sets
tmpTrainingYears <- c(seq(2009,2017, by = 1))

training_data <- aggTaxiData %>% 
  filter(year %in% tmpTrainingYears) %>% 
  select(-year) %>% arrange(date)

'%!in%' <- function(x,y)!('%in%'(x,y))
test_data <- aggTaxiData %>%
  filter(year %!in% tmpTrainingYears) %>%
  select(-year) %>% arrange(date)


#ts data
tsTrainingdata <- ts(training_data$cantidad, frequency = 365,
                     start = c(2009, 1), end = c(2017, 365))

tsTestdata <- ts(test_data$cantidad, frequency = 365,
                 start = c(2018, 1), end = c(2019, 365))

tsCompleto <- aggTaxiData %>% arrange(date) %>% 
  select(cantidad) %>% ts(frequency = 365, 
                          start = c(2009, 1), end = c(2019, 365))


# Plotting ----------------------------------------------------------------

#Autocorrelation graph
autoplot(acf(tsTrainingdata, plot = FALSE)) +
  labs(title = "", x = "") +
  theme_classic()


#Seasonality
ggseasonplot(tsCompleto) + 
  labs(x = "", title = "") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(values=c("steelblue", "olivedrab", "darksalmon", 
                              "blueviolet","cornflowerblue", "chocolate1", 
                              "darkred", "deeppink2", "lightcyan4", "darkgrey", 
                              "burlywood4"))  +
  theme_classic() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        legend.position = c(0.25, 0.85), legend.direction = "horizontal",
        legend.title = element_text(size=13, face="bold"),
        legend.text = element_text(size=13, face="bold"))


# DESCRIPTIVE PLOTS
elementTextX <- element_text(angle = 25, hjust = 1, 
                            face = "bold", size = 13)
elementTextY <- element_text(face = "bold", size = 13)

elementTextTitle <- element_text(face = "bold", size = 13)

aggTaxiData %>% ggplot(aes(x = date, y = cantidad)) +
  geom_line( color = "steelblue") + 
  labs(x = "", y = "Sevicios") + 
  scale_x_date(date_breaks = "1 year") + 
  theme_classic()+
  theme(axis.text.x = elementTextX,
        axis.text.y = elementTextY,
        axis.title.y = elementTextTitle)

aggTaxiData %>% ggplot(aes(x = year, y = cantidad)) +
  geom_boxplot(fill = "steelblue") + 
  labs(x = "", y = "Sevicios") +
  theme_classic() +
  theme(axis.text.x = elementTextX,
        axis.text.y = elementTextY,
        axis.title.y = elementTextTitle)

aggTaxiData %>% ggplot(aes(x = date, y=cantidad)) +
  geom_line(color = "steelblue") + 
  labs(title = "Distribución de los servicios por año",x = "", y = "") +
  facet_wrap(~year, scales = "free", ncol = 3) +
 scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1),
        axis.text.y = element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major.x = element_line(colour = "red", linetype = "dotted"))



############CALCULAR NÚMERO DE VIAJES POR AÑO#####################

#PAYMENT
paymentType %>% filter(payment == "cash" | payment == "credit") %>% 
  ggplot(aes(x = as.character(year), y = cantidad, fill = factor(payment))) +
  geom_bar(stat="identity", position=position_dodge()) +
  labs(x = "", y = "Pagos realizados", color = "Forma de pago") +
  theme_classic() + 
  theme(legend.position = c(0.8, 0.85), legend.direction = "horizontal",
        legend.title = element_text(size=13, face="bold"),
        legend.text = element_text(size=13, face="bold"),
        axis.text.x = elementTextY,
        axis.text.y = elementTextY,
        axis.title.y = elementTextTitle) +
  guides(fill = guide_legend(title = "Forma de pago")) +
  scale_fill_manual(values = c("steelblue", "olivedrab"))


#PASSENGERS por año quizá
passengers %>% filter(passengers > 0) %>% ggplot(aes(x = factor(passengers), y = cantidad)) +
  geom_bar(stat="identity", fill = "steelblue") +
  facet_wrap(~year , scales = "free") +
  labs(x = "Pasajeros por servicio",
       y = "") +
  theme_classic() +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text.x = element_text(face = "bold", size = 12),
        strip.background = element_rect(fill="tan"),
        strip.text = element_text(size = 12, face = "bold"))

#TRIP DISTANCE

TripDistance %>% ggplot(aes(x = factor(year), 
                                  y=cantidad)) +
  geom_bar(position = "dodge", stat = "identity", fill = "steelblue") + 
  labs(title = "Distancia recorrida por año", x = "", y = "Distancia recorrida") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))
