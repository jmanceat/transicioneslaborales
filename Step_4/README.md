# Hechos estilizados

Con este código se construye la estrategia econométrica en donde se explora la influencia de cambios regulatorios en las transiciones laborales. Este análisis se puede realizar utilizando un cuasi-panel de transiciones agregado para toda la población o utilizando un cuasi-panel a nivel de genero, grupo de edad, nivel de educación trimestre. 

En el articulo de investigación se presenta el análisis a nivel de genero, grupo de edad, nivel de educación y trimestre. 

## Sección 0 - Preliminaries

Esta sección del código establece las variables y las rutas necesarias para realizar un análisis de datos. Para replicar los ejercicios de este repositorio, se debe ajustar el usuario del computador en el que se van a correr los códigos. 

## Sección 1 - Organización de los datos

En esta sección se organiza el código para generar el cuasi-panel balanceado de tasas de transición a nivel de género, edad, nivel de educación y trimestre. 

En primer lugar se hace el ajuste de las tasas de transición en el periodo después pandemia del Covid-19. Este ajuste se hace de la siguiente manera: 

- Se calculan las tasas de transición promedio con origen en el empleo asalariado para las tasas que no fueron ajustadas por el método RAS.
- Se calcula las mismas tasas de transición promedio con origen en el empleo asalariado pero para las tasas que fueron ajusadas con el método RAS.
- Se calcula la diferencia entre la tasa de transición de antes del RAS y la tasa de transición después del RAS.
- Se leen los datos entre agosto del 2020 y febrero de 2021.
- Se reemplazan los valores de las tasas de transición con origen en el empleo asalariado entre agosto del 2020 y febrero de 2021 de la siguiente manera: $$
    p_{g,s_{0},s_{1},t}' = 
$$
 



En primer lugar, se leen las bases a nivel mensual de las tasas de transición antes de hacer el ajuste RAS a nivel de genero, grupo de edad y nivel de educación para calcular el promedio de la tasas transición con origen en el empleo asalariado. Lo anterior se realiza con el objetivo de ajustar las tasas de transición que se se ven afectadas por la recolección de los datos del DANE durante la pandemia del Covid-19. 

El ajuste de la tasa de transición se realiza 
