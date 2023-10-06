# Matriz de Transiciones GEIH

El objetivo de los códigos es generar las matrices de transición entre estados laborales en Colombia. Estos códigos se encuentran dividos en el grupos del total de la población, género, edad y nivel de educación. Sin embargo, todos los códigos tienen la misma estructura. 


## Sección 0 - Preliminaries

Esta sección del código establece las variables y las rutas necesarias para realizar un análisis de datos. Para replicar los ejercicios de este repositorio, se debe ajustar el usuario del computador en el que se van a correr los códigos. 

## Sección 1 - Datos 

En esta sección se leen las bases de datos que contienen las matrices de transición calculadas en el Step 1. En este proceso se calculan los totales de fila y de columna de cada una de las matrices de transición y se cálcula la diferencia entre estos dos totales. 

Por último, con estos totales se consiguen los valores de la emigración y la inmigración que sirven para compesar los valores faltantes de estos dos estados. 



## Sección 2 -  Datos

En la sección de los datos se leen cada una de las bases de mensuales para cada año del DANE. Para cada mes y cada año, se usa la base que corresponde a los datos de cabeceras municipales y se incluye la base del resto de municipios para ese mismo mes. 

Adicionalmente, se crean los valores del total de la población utilizando los factores de expansión de 2011 disponibles en estos datos

## Sección 3 - Datos de migración

Cómo el objetivo de este código es tener los datos detallados de las transiciones laborales de la población colombiana, también se incluye información del módulo de migración de la GEIH, disponible a través del Dane en el siguiente link: 

- [Modulo de migración GEIH][migracion-link]

[migracion-link]: https://microdatos.dane.gov.co/index.php/catalog/MERCLAB-Microdatos#_r=&collection=&country=&dtype=&from=1970&page=1&ps=&sid=&sk=&sort_by=title&sort_order=&to=2022&topic=&view=s&vk=

Esta información mensual se une con la base de datos de información laboral y se generan la variables que siren para identificar las migraciones mensuales en Colombia. 

## Sección 4 - Variables 

### Definición de destinos

En la primera parte de esta sección del código se definen las variables que describen el destino laboral de una persona en el mes $t$ en la encuesta. Las variables se generan a partir de preguntas en la encuesta que se identifican por sus códigos (por ejemplo, "P6040" para la edad de la persona). Estas nuevas variables se identifican por un sufijo "_y" en el nombre para denotar que la variable corresponde a un destino.

Por ejemplo, la línea "gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))" genera una variable "m_y" que es 1 si la edad de la persona (medida por la variable "P6040") es mayor o igual a 0 y menor que 12 y la variable "resto" es igual a 0 (para las cabeceras municipales), o si la edad de la persona es mayor o igual a 0 y menor que 10 y la variable "resto" es igual a 1 (para el resto de municipios).

### Definición de origenes 

En la segunda parte de esta sección del código definen las variables que describen el origen laboral de una persona en el año $t-1$ en la  encuesta. La letra "x" en el nombre de las variables indica que se trata del "origen" de la persona en el mercado laboral.

Se definen trece categorías:

- Menores de la edad de trabajar (m)
- Desempleado (d)
- Empleado Regular (e)
- Patrones (p)
- Otro empleo (o)
- Trabajador familiar (of)
- Cuenta propia (oc)
- Empleado domestico (os)
- Trabajador sin remuneracion (on)
- Jornalero o peon (oj)
- Otro (ot)
- Inactivos (i)
- Migracion (r)

Cada categoría se define a través de unas condiciones que se aplican a las variables que corresponden a preguntas retrospectivas de la GEIH, tales como la edad, el estatus de empleo empleo anterior, el tiempo desocupado entre el anterior empleo y el actual, y el tipo de trabajo anterior, entre otros. Luego, se asigna a cada persona su categoría correspondiente.

En general, el objetivo de esta sección del código es clasificar a las personas según su situación laboral en los meses $t-1$ y $t$, y proporcionar una base para el análisis posterior de los datos.

## Seccion 5 - Transiciones 

En esta sección del código se generan las variables que indican si hay una transición de un estado a otro en dos períodos consecutivos ($x$ e $y$).

La lista de variables incluye "m", "i", "d", "e", "e0", "e5", "p", "o", "of", "oc", "os", "on", "oj", "ot" y "r".

Para cada una de estas variables, se genera una nueva variable que indica si ambas (x e y) tienen un valor igual a 1. Por ejemplo, para la variable "m", se genera la variable "m_m" que es igual a 1 si "m_x" es igual a 1 y "m_y" es igual a 1. Es decir, si la persona fue menor de la edad para trabajar en el mes de origen x ($t-12$) y continua siendo menor de la edad para trabajar en el mes de destino $y$ ($t$). Esto se repite para cada una de las variables en la lista.

## Sección 6 - Matriz para guardar resultados

Este código en Stata crea una matriz para cada mes con 14 filas y 13 columnas. Los nombres de las columnas y las filas de la matriz se establecen con los nombres de cada estado laboral.

## Sección 7 - Conteo de transiciones

En esta sección del código se realiza un conteo para cada una de las transiciones laborales y se guardan los resultados en la matriz que se creó en la sección anterior. 

## Sección 8 - Ajuste de fallecidos

Esta sección del código se utiliza para analizar los valores de estadisticas vitales de fallecidos. Esta sección del código se divide en dos partes en la que la primera parte procesa los datos de los años 2020 y 2021 y los datos que van desde el año 2012 a 2019. 

Si el año es igual a 2020 o a 2021, el script:
- Carga los archivos "nofetal2018.dta" y "nofetal2019.dta" en la memoria de trabajo de Stata (en el directorio "rawdata/Vitales").
- Realiza un recuento de los fallecidos y almacena el resultado en la matriz "fallecidos".
- Ajusta el numero de fallecidos multiplicándolo por 1 + tasa en el año 2020 (o 2021), en donde la tasa en el año 2020 (2021) es el valor calculado en la Sección 1 - Datos de estadísticas vitales.
- Crea tres variables nuevas: "menores", "inactivos" y "ocupados", que representan respectivamente a los menores de edad, a los estudiantes, jubilados y amas de casa, y a los ocupados activamente.
- Crea una variable nueva llamada "totales" que almacena el valor total de la población.
 - Calcula las tasas de mortalidad para cada una de las tres variables nuevas y las almacena en una matríz.

Por último, para cada año diferente a 2020 y 2021, el código: 
- Carga los archivos de fallecidos correspondientes al mes $t$ y al mes $t-12$ en la memoria.
- Crea una matriz llamada "fallecidos".
- Realiza un recuento del numero de fallecidos y almacena el resultado en la matriz "fallecidos".
- Crea tres variables nuevas: "menores", "inactivos" y "ocupados", que representan respectivamente a los menores de edad, a los estudiantes, jubilados y amas de casa, y a los ocupados activamente.
- Crea una variable nueva llamada "totales" que almacena el valor total de la población.
- Calcula las tasas de mortalidad para cada una de las tres variables nuevas y las almacena en una matríz.


## Sección 9 - Ajuste de nacimientos

En esta sección del código, se calcula el número de nacimientos para cada periodo de 12 meses. Para esto, se realiza el conteo de nacimientos entre el mes actual y el mismo mes del año anterior usando las bases de nacimientos estadisticas vitales. Para los datos de 2020 y 2021 se raealiza el ajuste de numero de nacimientos utilizando la tasas que se calcularon en la sección 1 - Datos de estadísticas vitales. 

## Sección 10 - Totales de fila y de columna

En esta sección se calcula el numero de individuos totales para cada estado laboral en el el mes $t$ (destino) y en el mes $t-12$ (origen) y luego se agregan los datos a la matriz aue contiene los valores de las transiciones. 

## Sección 11 - Guardar los resultados

En esta sección se guardan cada una de las matrices de transición desde enero de 2012 a enero de 2021 con los totales de origen y destino los datos en formato Stata.  

## Sección 12 -  Ajustes para años individuales

El objetivo de esta sección es ajustar los valores de migración para los años anteriores a 2012, ya que el DANE comenzó a agregar esta información a partir de enero de 2012. 
