library(tidyverse)
library(zoo)
library(lubridate)
library(plotly)
library(glmnet)
library(forecast)
library(tseries)
library(dplyr)


###Archivo para armar la data del algoritmo de nowcasting en excel

df_raw_data <- read.csv("data/data1.csv")

df_raw_data <-df_raw_data%>%dplyr::select(-X)


imae <- df_raw_data%>%dplyr::select(ANO,MES,IMAE)%>% drop_na()

imae <- imae%>%mutate(IMAE_yoy_log=log(IMAE/dplyr::lag(IMAE,12))*100)

#Exploraci?n univariable

#Plot

imae_plot <- imae %>%
  mutate(Fecha = make_date(ANO, MES, 1))%>%
  drop_na()


COVID <- data.frame(
  start = as.Date("2020-03-01"),
  end   = as.Date("2021-02-01")
)

Rebote <- data.frame(
  start = as.Date("2021-03-01"),
  end   = as.Date("2022-02-01")
)

fig <- plot_ly(imae_plot, x = ~Fecha)

y_ref <- 5

fig <- fig %>%
  add_lines(
    x = ~Fecha,
    y = ~rep(y_ref, length(Fecha)),
    name = "Crecimiento 5%",
    line = list(color = "black", dash = "dash")
  )


fig <- fig %>% 
  add_lines(y = ~IMAE_yoy_log, name = "IMAE YoY",
            line = list(color = "blue"))

# Dummy legend traces
x0 <- imae_plot$Fecha[1]
y0 <- imae_plot$IMAE_yoy_log%>%na.omit()%>%first()

fig <- fig %>%
  add_trace(
    x = x0,
    y = y0,
    type = "scatter",
    mode = "markers",
    marker = list(size = 12, color = "lightgray", symbol = "square"),
    name = "COVID",
    showlegend = TRUE,
    visible = "legendonly"
  ) %>%
  add_trace(
    x = x0,
    y = y0,
    type = "scatter",
    mode = "markers",
    marker = list(size = 12, color = "pink", symbol = "square"),
    name = "Rebote",
    showlegend = TRUE,
    visible = "legendonly"
  )



# Proper shapes list
shapes_list <- list(
  list(
    type = "rect",
    x0 = COVID$start,
    x1 = COVID$end,
    y0 = 0,
    y1 = 1,
    xref = "x",
    yref = "paper",
    fillcolor = "lightgray",
    opacity = 0.3,
    line = list(width = 0)
  ),
  list(
    type = "rect",
    x0 = Rebote$start,
    x1 = Rebote$end,
    y0 = 0,
    y1 = 1,
    xref = "x",
    yref = "paper",
    fillcolor = "pink",
    opacity = 0.3,
    line = list(width = 0)
  )
)

fig <- fig %>%
  layout(
    title = "Variaci?n Interanual IMAE",
    xaxis = list(title = "Fecha"),
    yaxis = list(title = "Valor"),
    hovermode = "x unified",
    shapes = shapes_list,
    showlegend=T
  )

fig



acf(imae_plot$IMAE_yoy_log, na.action = na.omit)
pacf(imae_plot$IMAE_yoy_log)


adf.test(imae_plot$IMAE_yoy_log)
pp.test(imae_plot$IMAE_yoy_log)
kpss.test(imae_plot$IMAE_yoy_log)



acf_obj <- acf(imae_plot$IMAE_yoy_log,
               plot = FALSE,
               na.action = na.omit)

acf_df <- data.frame(
  lag = acf_obj$lag[,1,1],
  acf = acf_obj$acf[,1,1]
)
acf_df <- acf_df[-1, ]

fig_acf <- plot_ly(acf_df,
                   x = ~lag,
                   y = ~acf,
                   type = "bar",
                   name = "ACF")

fig_acf <- fig_acf %>%
  layout(
    title = "Funci?n de Autocorrelaci?n",
    xaxis = list(title = "Rezago"),
    yaxis = list(title = "ACF")
  )

fig_acf

n <- sum(!is.na(imae_plot$IMAE_yoy_log))
conf <- 1.96 / sqrt(n)

fig_acf <- fig_acf %>%
  add_lines(x = ~lag, y = conf, name = "Banda superior",
            line = list(dash = "dash", color = "red")) %>%
  add_lines(x = ~lag, y = -conf, name = "Banda inferior",
            line = list(dash = "dash", color = "red"))

fig_acf



df_transformed_data <- df_raw_data %>%
  arrange(ANO, MES) %>%
  mutate(lag_IMAE = dplyr::lag(IMAE, 1))


df_transformed_data <- df_transformed_data%>%
  arrange(ANO, MES) %>%
  mutate(lag_OCUPACION_HOT = dplyr::lag(OCUPACION_HOT, 1))


df_transformed_data <- df_transformed_data %>%
  arrange(ANO, MES) %>%
  mutate(across(-c(ANO, MES,OCUPACION_HOT,VAR_INTERANUAL_IPC,lag_OCUPACION_HOT),
                ~ (log(.x) - log(dplyr::lag(.x, 12)))*100,
                .names = "{.col}_yoy_log"))



df_transformed_data <-df_transformed_data%>%filter(ANO>=2015)%>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date<as.Date("2025-11-01"))%>%
  select(-date)




df_transformed_data <- df_transformed_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  mutate(
    dummy_covid1 = if_else(date >= as.Date("2020-03-01") &
                             date <= as.Date("2021-02-01"), 1, 0),
    
    dummy_covid2 = if_else(date >= as.Date("2021-03-01") &
                             date <= as.Date("2022-03-01"), 1, 0)
  )%>%select(-date)


df_forecast_data <- df_transformed_data


consumo_tc_transformada <- read.csv("data/data1_variable.csv")

df_forecast_data <-df_forecast_data%>%join(consumo_tc_transformada, by = c("ANO" = "ANO","MES" = "MES"))


df_forecast_data <- df_forecast_data[complete.cases(df_forecast_data),]


  
  

df_forecast_data$nowcast_imae <- NA

df_forecast_data$nowcast_consumotc <- NA

df_forecast_data$nowcast_ocupacion_hot <- NA



df_forecast_data <- df_forecast_data%>%
  dplyr::filter(!is.na(lag_IMAE_yoy_log))



start_window <- 30
n <- nrow(df_forecast_data)

for (t in seq(start_window, n - 1)) {
  
  # Expanding sample (1 ??? t)
  train_data <- df_forecast_data[1:t, ]
  
  
  # Estimate model
  model_imae <- lm(IMAE_yoy_log ~ lag_IMAE_yoy_log + dummy_covid1 + dummy_covid2, data = train_data)
  
  # Forecast t+1 using info available at time t
  new_data <- df_forecast_data[t + 1, ]
  
  df_forecast_data$nowcast_imae[t + 1] <- predict(model_imae, newdata = new_data)
  
  model_consumotc <- lm(IMAE_yoy_log ~ lag_IMAE_yoy_log + z_TOTAL_CONSUMO_TC_yoy_log+ dummy_covid1 + dummy_covid2, data = train_data)


  # Prediction
  df_forecast_data$nowcast_consumotc[t + 1] <-
    predict(model_consumotc, newdata = new_data)

  model_ocupacion_hot <- lm(IMAE_yoy_log ~ lag_IMAE_yoy_log+ z_TOTAL_CONSUMO_TC_yoy_log + OCUPACION_HOT+ dummy_covid1 + dummy_covid2, data = train_data)

  # Prediction
  df_forecast_data$nowcast_ocupacion_hot[t + 1] <-
    predict(model_ocupacion_hot, newdata = new_data)
  
}


df_forecast_data<-df_forecast_data%>%mutate(
  forecast_error_imae=IMAE_yoy_log-nowcast_imae ,
  forecast_error_consumotc=IMAE_yoy_log-nowcast_consumotc,
  forecast_error_ocupacion_hot=IMAE_yoy_log-nowcast_ocupacion_hot
  )

rmse <- df_forecast_data %>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
    
    RMSE_consumotc = sqrt(mean(forecast_error_consumotc^2, na.rm = TRUE)),
    RMSE_ocupacion_hot = sqrt(mean(forecast_error_ocupacion_hot^2, na.rm = TRUE))
  ) %>%
  unlist()


rmse



rmse_post_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date>as.Date("2022-03-01"))%>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
    
    RMSE_consumotc = sqrt(mean(forecast_error_consumotc^2, na.rm = TRUE)),
    RMSE_ocupacion_hot = sqrt(mean(forecast_error_ocupacion_hot^2, na.rm = TRUE))
  ) %>%
  unlist()

rmse_post_covid





df_transformed_data <- df_raw_data %>%
  arrange(ANO, MES) %>%
  mutate(lag_IMAE = dplyr::lag(IMAE, 1))


df_transformed_data <- df_transformed_data%>%
  arrange(ANO, MES) %>%
  mutate(lag_OCUPACION_HOT = dplyr::lag(OCUPACION_HOT, 1))


df_transformed_data <- df_transformed_data %>%
  arrange(ANO, MES) %>%
  mutate(across(-c(ANO, MES,OCUPACION_HOT,VAR_INTERANUAL_IPC),
                ~ (log(.x) - log(dplyr::lag(.x, 12)))*100,
                .names = "{.col}_yoy_log"))



df_transformed_data <-df_transformed_data%>%filter(ANO>=2007)%>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date<as.Date("2025-11-01"))%>%
  select(-date)



df_forecast_data <- df_transformed_data


df_forecast_data$nowcast_imae <- NA


df_forecast_data <- df_forecast_data%>%
  filter(!is.na(lag_IMAE_yoy_log))



start_window <- 30
n <- nrow(df_forecast_data)

for (t in seq(start_window, n - 1)) {
  
  # Expanding sample (1 ??? t)
  train_data <- df_forecast_data[1:t, ]
  
  
  # Estimate model
  model_imae <- lm(IMAE_yoy_log ~ lag_IMAE_yoy_log , data = train_data)
  
  # Forecast t+1 using info available at time t
  new_data <- df_forecast_data[t + 1, ]
  
  df_forecast_data$nowcast_imae[t + 1] <- predict(model_imae, newdata = new_data)
  
}

df_forecast_data<-df_forecast_data%>%mutate(
  forecast_error_imae=IMAE_yoy_log-nowcast_imae ,
)


rmse_pre_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date<=as.Date("2020-02-01")&date>=as.Date("2017-01-01"))%>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
  ) %>%
  unlist()

rmse_pre_covid


rmse_pre_covid_comparacion_factor_model <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date>=as.Date("2019-01-01")&date<=as.Date("2020-02-01"))%>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
  ) %>%
  unlist()

rmse_pre_covid_comparacion_factor_model


