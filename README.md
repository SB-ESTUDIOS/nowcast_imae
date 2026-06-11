# Nowcasting del IMAE: Desarrollo Iterativo de Modelos Econométricos

## Descripción general

Este repositorio documenta el desarrollo progresivo de un sistema de nowcasting del Indicador Mensual de Actividad Económica (IMAE), cuyo objetivo es estimar el crecimiento económico en tiempo real antes de la publicación oficial de los datos.

El proyecto está estructurado como un proceso iterativo en dos etapas:

- Primera iteración: construcción de un marco base con modelos econométricos tradicionales (OLS)
- Segunda iteración: extensión del marco base mediante técnicas avanzadas de regularización y selección de variables

Este enfoque permite evidenciar cómo evoluciona un sistema de nowcasting al incorporar mayor sofisticación metodológica y un conjunto más amplio de información.

---

## Objetivos

- Construir un sistema de nowcasting paso a paso
- Evaluar el aporte incremental de distintas metodologías
- Identificar variables con mayor poder predictivo sobre el IMAE
- Comparar modelos simples vs. modelos regularizados
- Analizar la estabilidad del desempeño en distintos períodos (pre y post COVID)

---

## Arquitectura del proyecto

El repositorio se divide en dos componentes principales:

### 🔹 Iteración 1: Enfoque econométrico base (`nowcast_imae_1.R`)

Esta primera versión establece las bases del sistema de nowcasting mediante herramientas econométricas estándar.

**Características principales:**

- Modelos lineales (OLS)
- Inclusión de rezagos del IMAE
- Incorporación de variables contemporáneas (ej. consumo, turismo)
- Construcción manual de especificaciones
- Evaluación mediante RMSE
- Análisis exploratorio completo

**Rol dentro del proyecto:**

- Define el benchmark inicial
- Permite entender la dinámica del IMAE
- Proporciona una referencia para comparar mejoras posteriores

---

### 🔹 Iteración 2: Modelos avanzados (`nowcast_imae_2.R` + `gram_schmidt_forward.R`)

La segunda iteración amplía el enfoque inicial incorporando técnicas modernas de modelación.

**Mejoras introducidas:**

- Ridge Regression (glmnet) para mitigar sobreajuste
- Selección automática de variables (Gram-Schmidt Forward Selection)
- Evaluación más sistemática de múltiples modelos
- Manejo de mayor dimensionalidad en variables explicativas

**Características principales:**

- Modelos autorregresivos regularizados
- Modelos con múltiples combinaciones de variables macroeconómicas
- Procedimientos automáticos de selección de variables
- Comparación estructurada de desempeño

**Rol dentro del proyecto:**

- Mejora la capacidad predictiva
- Reduce problemas de colinealidad
- Permite escalar el sistema con más variables
- Representa una versión más robusta del nowcasting

---

## Enfoque metodológico común

Ambas iteraciones comparten un núcleo metodológico:

### Transformación de variables

```math
YoY = (\log(x_t) - \log(x_{t-12})) * 100
```

### Ingeniería de variables

- Rezagos del IMAE
- Variables contemporáneas
- Dummies para:
  - COVID-19
  - Período de rebote

### Evaluación en tiempo real

- Simulación mediante ventanas expansivas
- Estimación con información disponible en cada período

### Métrica principal

```math
RMSE = sqrt(mean((y_t - \hat{y}_t)^2))
```

Evaluado en:

- Muestra completa
- Período pre-COVID
- Período post-COVID

---

## Flujo general del proceso

- Carga y limpieza de datos
- Transformación (YoY, log, rezagos)
- Análisis exploratorio
- Construcción de modelos
- Nowcasting con ventana expansiva
- Evaluación (RMSE y análisis por subperíodos)

---

## Selección de variables (Iteración 2)

Se implementa un algoritmo de Gram-Schmidt Forward Selection que:

- Selecciona variables de forma secuencial
- Evalúa contribuciones marginales al R²
- Reduce colinealidad mediante ortogonalización
- Se detiene cuando la mejora marginal es baja

Esto permite identificar variables con información verdaderamente adicional.

---

## Modelos considerados

- Modelo naive
- Modelo autorregresivo (OLS)
- Modelos con variables adicionales (consumo, turismo, etc.)
- Modelo Ridge autorregresivo
- Modelos Ridge ampliados
- Modelo con variables seleccionadas automáticamente

---

## Datos requeridos

### Variables temporales

- ANO
- MES

### Variable objetivo

- IMAE

### Variables explicativas (ejemplos)

- Consumo con tarjetas
- Ocupación hotelera
- Inflación
- Ventas
- Crédito

---

## Requisitos

Paquetes en R:

- tidyverse
- dplyr
- zoo
- lubridate
- plotly
- forecast
- tseries
- glmnet
- openxlsx
- modelsummary

---

## Ejecución

### Iteración 1

```r
source("nowcast_imae_1.R")
```

### Iteración 2

```r
source("nowcast_imae_2.R")
```

---

## Interpretación y valor del enfoque iterativo

El diseño en dos iteraciones permite:

- Entender cómo un modelo base puede ser mejorado progresivamente
- Medir el valor de:
  - Regularización
  - Selección automática de variables
- Evaluar el trade-off entre simplicidad e información
- Construir un sistema de nowcasting más robusto y escalable

---

## Conclusión

Este repositorio no solo presenta modelos de nowcasting, sino que documenta el proceso de construcción de un sistema predictivo, pasando de:

> Modelos econométricos simples → Modelos regularizados con selección de variables

El resultado es un marco práctico, replicable y extensible para el monitoreo en tiempo real de la actividad económica.


