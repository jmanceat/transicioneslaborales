# Series 
Este código se realiza con el objetivo de construir series de tiempo de las tasas de transición laboral antes y despues de realizar el RAS. 

## Sección 0 - Preliminaries

Esta sección del código establece las variables y las rutas necesarias para realizar un análisis de datos. Para replicar los ejercicios de este repositorio, se debe ajustar el usuario del computador en el que se van a correr los códigos. 

## Sección 1 - Figuras generales

Esta sección se divide en tres partes: 

- Calculo de diferencia entre las tasas de transición que tienen el origen en el empleo asalariado antes y después del RAS. 
- Gráficas antes del RAS. 
- Gráficas después del RAS.


### Antes del RAS

En esta sección del código se leen las bases de las tasas de transición laboral antes de hacer el ajuste del RAS. Para estos se siguen los siguientes pasos: 

- Se leen las matrices que contienen las tasas de transición laboral de cada mes.
- Se construye un panel de tasas de transición laboral a nivel de origen mes y año en donde cada variable representa un estado de destino laboral.
- Se reemplazan las tasas de transición de los meses del 2020 por valores vacios debido a los errores que pudo ocasionar la pandemia del Covid-19 en cuanto a los errores de respuesta en la encuesta.
- Se definen momentos en los que hubo cambios en la regulación laboral colombiana que pudieron afectar las dinámicas de las transiciones laborales.
- Se construyen los gráficos de tasas de transición para cada origen laboral.  

### Después del RAS

En esta sección del código se leen las bases de las tasas de transición laboral antes de hacer el ajuste del RAS. Para estos se siguen los siguientes pasos: 

- Se leen las matrices que contienen las tasas de transición laboral de cada mes.
- Se construye un panel de tasas de transición laboral a nivel de origen mes y año en donde cada variable representa un estado de destino laboral.
- Se reemplazan las tasas de transición de los meses del 2020 por valores vacios debido a los errores que pudo ocasionar la pandemia del Covid-19 en cuanto a los errores de respuesta en la encuesta.
- Se definen momentos en los que hubo cambios en la regulación laboral colombiana que pudieron afectar las dinámicas de las transiciones laborales.
- Se construyen los gráficos de tasas de transición para cada origen laboral.

