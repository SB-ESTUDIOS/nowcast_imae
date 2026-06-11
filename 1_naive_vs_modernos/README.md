# Nowcasting del IMAE con método `naive`

## Descripción general

Este proyecto implementa un ejercicio de **nowcasting del Indicador Mensual de Actividad Económica (IMAE)** utilizando modelos econométricos simples con información contemporánea y rezagada.

El objetivo del nowcasting es **estimar el crecimiento económico en tiempo real**, antes de que los datos oficiales estén completamente disponibles, utilizando variables que se publican con mayor frecuencia o menor rezago.

---

## Enfoque metodológico

El enfoque seguido en este proyecto se basa en:

* Transformaciones de series macroeconómicas a tasas de crecimiento interanual (YoY en logaritmos)
* Inclusión de rezagos de la variable objetivo (IMAE)
* Incorporación de variables explicativas contemporáneas (ej. consumo con tarjetas, ocupación hotelera)
* Uso de modelos lineales estimados en ventanas expansivas
* Evaluación del desempeño mediante errores de pronóstico (RMSE)

Además, se introducen **variables dummy** para capturar efectos estructurales asociados a la pandemia del COVID-19 y el período de rebote posterior.

---

## Flujo del proceso de nowcasting

El proceso general es el siguiente:

1. **Carga de datos**

   * Se leen archivos CSV con series macroeconómicas.
   * Se eliminan columnas innecesarias (como índices).

2. **Transformación de variables**

   * Se calcula el crecimiento interanual en logaritmos:

     * ( \text{YoY} = \log(x_t / x_{t-12}) \times 100 )
   * Se generan variables rezagadas (lags).
   * Se construyen variables dummy para eventos específicos (COVID y rebote).

3. **Análisis exploratorio**

   * Visualización de la serie del IMAE.
   * Análisis de autocorrelación (ACF y PACF).
   * Pruebas de estacionariedad (ADF, PP, KPSS).

4. **Construcción de modelos**
   Se estiman varios modelos de regresión:

   * Modelo base:

     * IMAE en función de su propio rezago

   * Modelo con consumo:

     * Incluye consumo con tarjetas como variable explicativa

   * Modelo extendido:

     * Incluye consumo y ocupación hotelera

5. **Nowcasting (ventana expansiva)**

   * Para cada período ( t ):

     * Se estima el modelo con datos hasta ( t )
     * Se predice ( t+1 )
   * Este proceso simula un entorno de tiempo real.

6. **Evaluación del desempeño**

   * Se calculan errores de pronóstico:

     * Error = valor observado - nowcast
   * Se calcula el RMSE:

     * Para toda la muestra
     * Para período post-COVID
     * Para período pre-COVID

---

## Descripción del script nowcast_imae_1.R

El archivo principal realiza las siguientes tareas:

### 1. Preparación de datos

* Lectura de archivos:

  * `data1.csv`
  * `data1_variable.csv`
* Limpieza y selección de variables
* Generación de transformaciones (YoY log)

### 2. Análisis exploratorio

* Gráficos interactivos del IMAE (plotly)
* Identificación visual de períodos de COVID y rebote
* Análisis de autocorrelación
* Pruebas de estacionariedad

### 3. Ingeniería de variables

* Creación de rezagos
* Construcción de variables dummy
* Integración de múltiples fuentes de datos

### 4. Modelación

* Estimación de modelos lineales (`lm`)
* Inclusión progresiva de variables explicativas

### 5. Simulación de nowcasting

* Implementación de ventana expansiva
* Generación de predicciones fuera de muestra

### 6. Evaluación

* Cálculo de errores de pronóstico
* Comparación de modelos mediante RMSE
* Evaluación por subperíodos (pre y post COVID)

---

## Estructura de los datos

Los datos utilizados contienen:

* Identificadores temporales:

  * Año (`ANO`)
  * Mes (`MES`)
* Variable objetivo:

  * IMAE
* Variables explicativas:

  * Consumo con tarjetas
  * Ocupación hotelera
  * Otras variables macroeconómicas

---

## Interpretación

El ejercicio permite:

* Evaluar qué variables mejoran el nowcast del IMAE
* Analizar la estabilidad del modelo en distintos períodos
* Medir el impacto de shocks estructurales (como COVID-19)
* Comparar modelos simples vs. modelos con más información


---

## Requisitos

Paquetes utilizados en R:

* tidyverse
* dplyr
* zoo
* lubridate
* plotly
* forecast
* tseries
* glmnet

---

## Nota final

Este proyecto ilustra un enfoque práctico y replicable de nowcasting con herramientas estándar de econometría, enfatizando la importancia de la información oportuna en el análisis macroeconómico.
