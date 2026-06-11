# Nowcasting del IMAE mediante Ridge Regression y Selección de Variables Gram-Schmidt

## Descripción general

Este proyecto implementa un sistema de **nowcasting del Indicador Mensual de Actividad Económica (IMAE)** utilizando modelos econométricos y técnicas de regularización para anticipar el crecimiento económico en tiempo real.

El objetivo es evaluar qué conjunto de indicadores macroeconómicos contiene mayor información predictiva para explicar la evolución interanual del IMAE y comparar su desempeño mediante ejercicios pseudo out-of-sample.

El proyecto combina:

* Modelos autorregresivos tradicionales
* Ridge Regression
* Selección de variables mediante Gram-Schmidt Forward Selection
* Evaluación de pronósticos en tiempo real mediante ventanas expansivas

---

## Enfoque metodológico

La estrategia seguida en este proyecto se basa en:

* Transformación de variables macroeconómicas a tasas de crecimiento interanual en logaritmos
* Inclusión de rezagos de la variable objetivo
* Incorporación de variables contemporáneas relacionadas con la actividad económica
* Selección automática de variables mediante Gram-Schmidt
* Estimación mediante Ridge Regression para reducir problemas de sobreajuste
* Evaluación pseudo out-of-sample utilizando ventanas expansivas
* Comparación de modelos mediante RMSE

Adicionalmente se incluyen variables dummy para capturar los efectos extraordinarios asociados a la pandemia del COVID-19 y al período posterior de normalización económica.

---

## Flujo del proceso de nowcasting

El proceso general es el siguiente:

### 1. Carga de datos

* Se lee un archivo CSV con información macroeconómica mensual.
* Se verifica la disponibilidad de todas las variables requeridas.
* Se ordenan las observaciones cronológicamente.

### 2. Transformación de variables

* Se construyen tasas de crecimiento interanual:

  ```text
  YoY = (log(x_t) - log(x_{t-12})) × 100
  ```

* Se generan rezagos de la variable objetivo.
* Se construyen variables dummy para COVID.

### 3. Preparación de la muestra

* Se eliminan observaciones incompletas.
* Se construye una muestra pre-COVID para el proceso de selección de variables.

### 4. Selección de variables

* Se aplica el algoritmo Gram-Schmidt Forward Selection.
* Las variables se incorporan de manera secuencial según su contribución marginal al R².
* El procedimiento se detiene cuando la ganancia adicional de R² es inferior al umbral especificado.

### 5. Construcción de modelos

Se estiman varios modelos de nowcasting:

* Modelo Naive
* Modelo autorregresivo OLS
* Modelo Ridge autorregresivo
* Modelo Ridge con ocupación hotelera
* Modelo Ridge con ocupación hotelera e inflación
* Modelo Ridge ampliado con ventas y crédito
* Modelo Ridge con variables seleccionadas por Gram-Schmidt

### 6. Simulación de tiempo real

Para cada período:

* Se estima el modelo utilizando únicamente información disponible hasta ese momento.
* Se genera un pronóstico para el siguiente período.
* Se incorpora la nueva observación.
* Se reestima el modelo.

Este procedimiento replica el proceso real de generación de nowcasts.

### 7. Evaluación

* Se calculan errores de pronóstico.
* Se calcula el RMSE para cada modelo.
* Se evalúa el desempeño:

  * En toda la muestra
  * En el período pre-COVID
  * En el período post-COVID

---

## Descripción del script `nowcast_imae_2.R`

El archivo principal realiza las siguientes tareas:

### 1. Lectura y preparación de datos

* Lectura de la base de datos CSV
* Construcción de rezagos
* Transformación de variables a tasas interanuales
* Construcción de variables dummy para COVID

### 2. Selección de variables

* Carga de la función `gram_schmidt_forward.R`
* Aplicación del algoritmo sobre la muestra pre-COVID
* Identificación de variables con mayor capacidad explicativa

### 3. Estimación de modelos

Se estiman distintos modelos utilizando:

* Regresión lineal (`lm`)
* Ridge Regression (`glmnet`)

### 4. Generación de nowcasts

* Implementación de ventana expansiva
* Reestimación continua de parámetros
* Generación de pronósticos fuera de muestra

### 5. Evaluación

* Cálculo de errores de pronóstico
* Comparación de modelos mediante RMSE
* Evaluación por submuestras

---

## Descripción del algoritmo Gram-Schmidt

El archivo `gram_schmidt_forward.R` implementa un procedimiento de selección de variables basado en ortogonalización secuencial.

### Variables candidatas

* Rezago del IMAE
* Ocupación hotelera
* Inflación interanual
* Ventas
* Crédito

### Procedimiento

En cada iteración:

1. Se ortogonalizan las variables restantes respecto a las previamente seleccionadas.
2. Se calcula la correlación entre cada variable ortogonalizada y el residuo actual.
3. Se selecciona la variable con mayor correlación absoluta.
4. Se mide la mejora incremental del R².
5. Se detiene cuando la mejora es inferior al umbral establecido.

Este enfoque permite identificar variables con información verdaderamente adicional y reducir problemas de colinealidad.

---

## Modelos evaluados

### Modelo Naive

Utiliza el promedio histórico del crecimiento del IMAE como predicción.

---

### Modelo Autorregresivo (OLS)

Incluye:

* Rezago del IMAE
* Dummies COVID

---

### Modelo Ridge Autorregresivo

Incluye:

* Rezago del IMAE
* Dummies COVID

Estimado mediante Ridge Regression.

---

### Modelo Ridge con Ocupación Hotelera

Incluye:

* Rezago del IMAE
* Ocupación hotelera
* Dummies COVID

---

### Modelo Ridge con Ocupación Hotelera e Inflación

Incluye:

* Rezago del IMAE
* Ocupación hotelera
* Inflación interanual
* Dummies COVID

---

### Modelo Grande

Incluye:

* Rezago del IMAE
* Ventas
* Crédito
* Dummies COVID

---

### Modelo Gram-Schmidt

Incluye las variables seleccionadas automáticamente por el procedimiento Gram-Schmidt.

---

## Estructura de los datos

La base de datos debe contener al menos las siguientes variables:

### Variables temporales

* `ANO`
* `MES`

### Variable objetivo

* `IMAE`

### Variables explicativas

* `OCUPACION_HOT`
* `VAR_INTERANUAL_IPC`
* `VENTA`
* `CREDITO`

---

## Evaluación del desempeño

Los errores de pronóstico se calculan como:

```text
Error = Valor observado - Pronóstico
```

La métrica principal es:

```text
RMSE = sqrt(mean(error²))
```

Un menor RMSE implica una mayor capacidad predictiva.

Se reportan resultados para:

* Muestra completa
* Período pre-COVID
* Período post-COVID

---

## Requisitos

Paquetes utilizados en R:

* tidyverse
* dplyr
* zoo
* lubridate
* glmnet
* forecast
* tseries
* plotly
* openxlsx
* modelsummary

---

## Ejecución

### Paso 1

Colocar los archivos:

```text
data_segundo_blogpost.csv
nowcast_imae_2.R
gram_schmidt_forward.R
```

en el mismo directorio de trabajo.

### Paso 2

Ejecutar:

```r
source("nowcast_imae_2.R")
```

### Paso 3

Revisar los resultados:

```r
rmse
rmse_pre_covid
rmse_sin_covid
```

---

## Objetivo del proyecto

Este ejercicio busca responder una pregunta central del análisis macroeconómico:

> ¿Qué indicadores permiten anticipar con mayor precisión la evolución futura de la actividad económica?

La comparación entre modelos autorregresivos, modelos Ridge y modelos con selección de variables Gram-Schmidt permite cuantificar el valor predictivo de distintos indicadores y construir sistemas de nowcasting más robustos para el seguimiento de la economía en tiempo real.