library(openxlsx)
library(tidyverse)
library(zoo)
library(lubridate)
library(ROracle)        # Oracle DB connection
library(keyring)
library(plotly)
library(modelsummary)
library(glmnet)
library(forecast)
library(tseries)
library(dplyr)


###Extrayendo la data
df_raw_data <- read.csv("data_segundo_blogpost.csv")


###Transformando la data
df_transformed_data <- df_raw_data %>%
  arrange(ANO, MES) %>%
  mutate(lag_IMAE = lag(IMAE, 1))


df_transformed_data <- df_transformed_data %>%
  arrange(ANO, MES) %>%
  mutate(across(-c(ANO, MES,OCUPACION_HOT,VAR_INTERANUAL_IPC),
                ~ (log(.x) - log(lag(.x, 12)))*100,
                .names = "{.col}_yoy_log"))



df_transformed_data <- df_transformed_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  mutate(
    dummy_covid1 = if_else(date >= as.Date("2020-03-01") &
                             date <= as.Date("2021-02-01"), 1, 0),
    
    dummy_covid2 = if_else(date >= as.Date("2021-03-01") &
                             date <= as.Date("2022-03-01"), 1, 0)
  )%>%select(-date)


df_forecast_data <- df_transformed_data

df_forecast_data <- df_forecast_data[complete.cases(df_forecast_data),]


###data pre-COVID
pre_covid_data <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date<=as.Date("2020-02-01"))


####Haciendo seleccion de variables con Forward Gram-Schmidt
source("gram_schmidt_forward.R")




result <- gram_schmidt_forward(
  data = pre_covid_data,
  y_var = "IMAE_yoy_log",
  x_vars = c("lag_IMAE_yoy_log","OCUPACION_HOT","VAR_INTERANUAL_IPC",
             "VENTA_yoy_log","CREDITO_yoy_log"),
  r2_threshold = 0.01
)

result$selected_variables


#Creando columnas extra para poner las proyecciones
df_forecast_data$nowcast_imae <- NA

df_forecast_data$nowcast_imae2 <- NA


df_forecast_data$nowcast_ocupacion_hot <- NA

df_forecast_data$nowcast_ocupacion_hot_inflacion <- NA

df_forecast_data$nowcast_naive <- NA


df_forecast_data$lambda <- NA

df_forecast_data$nowcast_big_model <- NA

df_forecast_data$nowcast_gram_schmidt <- NA

df_forecast_data <- df_forecast_data%>%arrange(ANO,MES)




###Haciendo pseudo-out-of-sample
set.seed(123)
start_window <- 30
n <- nrow(df_forecast_data)

for (t in seq(start_window, n - 1)) {
  
  # Expanding sample (1 ??? t)
  train_data <- df_forecast_data[1:t, ]
  
  df_forecast_data$nowcast_naive[t + 1] <- train_data%>%summarise(mean(IMAE_yoy_log))%>%as.numeric()
  
  # Estimate model
  model_imae <- lm(IMAE_yoy_log ~ lag_IMAE_yoy_log + dummy_covid1 + dummy_covid2, data = train_data)
  
  # Forecast t+1 using info available at time t
  new_data <- df_forecast_data[t + 1, ]
  
  df_forecast_data$nowcast_imae[t + 1] <- predict(model_imae, newdata = new_data)
  
  
  
  x_train <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + dummy_covid1 + dummy_covid2,
                          data = train_data)[, -1]
  
  y_train <- train_data$IMAE_yoy_log
  
  # Cross-validated ridge
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  # Prepare new observation
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  
  x_new <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + dummy_covid1 + dummy_covid2,
                        data = new_data)[, -1]
  
  # Prediction
  df_forecast_data$nowcast_imae2[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  # Prepare training data
  x_train <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + OCUPACION_HOT + dummy_covid1 + dummy_covid2,
                          data = train_data)[, -1]
  
  y_train <- train_data$IMAE_yoy_log
  
  # Cross-validated ridge
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  # Prepare new observation
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  
  x_new <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + OCUPACION_HOT + dummy_covid1 + dummy_covid2,
                        data = new_data)[, -1]
  
  # Prediction
  df_forecast_data$nowcast_ocupacion_hot[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  
  
  
  x_train <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + OCUPACION_HOT+VAR_INTERANUAL_IPC + dummy_covid1 + dummy_covid2,
                          data = train_data)[, -1]
  
  y_train <- train_data$IMAE_yoy_log
  
  # Cross-validated ridge
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  # Prepare new observation
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  
  x_new <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + OCUPACION_HOT+VAR_INTERANUAL_IPC + dummy_covid1 + dummy_covid2,
                        data = new_data)[, -1]
  
  # Prediction
  df_forecast_data$nowcast_ocupacion_hot_inflacion[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  df_forecast_data$lambda[t] <-cv_ridge$lambda.min
  
  
  
  x_train <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + VENTA_yoy_log+CREDITO_yoy_log+ dummy_covid1 + dummy_covid2,
                          data = train_data)[, -1]
  
  y_train <- train_data$IMAE_yoy_log
  
  
  # Cross-validated ridge
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  # Prepare new observation
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  
  x_new <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log + VENTA_yoy_log+CREDITO_yoy_log+ dummy_covid1 + dummy_covid2,
                        data = new_data)[, -1]
  
  # Prediction
  df_forecast_data$nowcast_big_model[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  
  train_data <- df_forecast_data[1:t, ]
  
  df_forecast_data$nowcast_naive[t + 1] <- train_data%>%summarise(mean(IMAE_yoy_log))%>%as.numeric()
  
  # Estimate model
  x_train <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log+ OCUPACION_HOT+ VAR_INTERANUAL_IPC+CREDITO_yoy_log+ dummy_covid1 + dummy_covid2,
                          data = train_data)[, -1]
  
  y_train <- train_data$IMAE_yoy_log
  
  
  # Cross-validated ridge
  cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
  
  # Prepare new observation
  new_data <- df_forecast_data[t + 1, , drop = FALSE]
  
  x_new <- model.matrix(IMAE_yoy_log ~ lag_IMAE_yoy_log+ OCUPACION_HOT+ VAR_INTERANUAL_IPC +CREDITO_yoy_log+ dummy_covid1 + dummy_covid2,
                        data = new_data)[, -1]
  
  # Prediction
  df_forecast_data$nowcast_gram_schmidt[t + 1] <-
    predict(cv_ridge, newx = x_new, s = "lambda.min")
  
  
  
  
}


#####Calculando errores y RMSE
df_forecast_data<-df_forecast_data%>%mutate(
  forecast_error_imae=IMAE_yoy_log-nowcast_imae,
  forecast_error_ocupacion_hot=IMAE_yoy_log-nowcast_ocupacion_hot,
  forecast_error_ocupacion_hot_inflacion=IMAE_yoy_log-nowcast_ocupacion_hot_inflacion,
  forecast_error_naive=IMAE_yoy_log-nowcast_naive,
  forecast_error_big_model=IMAE_yoy_log-nowcast_big_model,
  forecast_error_gram_schmidt=IMAE_yoy_log-nowcast_gram_schmidt,
  forecast_error_imae2=IMAE_yoy_log-nowcast_imae2
)

rmse <- df_forecast_data %>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
    RMSE_ocupacion_hot = sqrt(mean(forecast_error_ocupacion_hot^2, na.rm = TRUE)),
    RMSE_ocupacion_hot_inflacion = sqrt(mean(forecast_error_ocupacion_hot_inflacion^2, na.rm = TRUE)),
    RMSE_naive = sqrt(mean(forecast_error_naive^2, na.rm = TRUE)),
    RMSE_big_model = sqrt(mean(forecast_error_big_model^2, na.rm = TRUE)),
    RMSE_gram_schmidt = sqrt(mean(forecast_error_gram_schmidt^2, na.rm = TRUE)),
    RMSE_imae2 = sqrt(mean(forecast_error_imae2^2, na.rm = TRUE))
  ) %>%
  unlist()


rmse


rmse_sin_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date>=as.Date("2022-03-01"))%>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
    RMSE_ocupacion_hot = sqrt(mean(forecast_error_ocupacion_hot^2, na.rm = TRUE)),
    RMSE_ocupacion_hot_inflacion = sqrt(mean(forecast_error_ocupacion_hot_inflacion^2, na.rm = TRUE)),
    RMSE_naive = sqrt(mean(forecast_error_naive^2, na.rm = TRUE)),
    RMSE_big_model = sqrt(mean(forecast_error_big_model^2, na.rm = TRUE)),
    RMSE_gram_schmidt = sqrt(mean(forecast_error_gram_schmidt^2, na.rm = TRUE)),
    RMSE_imae2 = sqrt(mean(forecast_error_imae2^2, na.rm = TRUE))
  ) %>%
  unlist()

rmse_sin_covid




rmse_pre_covid <- df_forecast_data %>%
  mutate(date = as.Date(as.yearmon(paste(ANO, MES), "%Y %m"))) %>%
  filter(date<=as.Date("2020-02-01"))%>%
  summarise(
    RMSE_imae = sqrt(mean(forecast_error_imae^2, na.rm = TRUE)),
    RMSE_ocupacion_hot = sqrt(mean(forecast_error_ocupacion_hot^2, na.rm = TRUE)),
    RMSE_ocupacion_hot_inflacion = sqrt(mean(forecast_error_ocupacion_hot_inflacion^2, na.rm = TRUE)),
    RMSE_ocupacion_naive = sqrt(mean(forecast_error_naive^2, na.rm = TRUE)),
    RMSE_big_model = sqrt(mean(forecast_error_big_model^2, na.rm = TRUE)),
    RMSE_gram_schmidt = sqrt(mean(forecast_error_gram_schmidt^2, na.rm = TRUE)),
    RMSE_imae2 = sqrt(mean(forecast_error_imae2^2, na.rm = TRUE))
  ) %>%
  unlist()

rmse_pre_covid





