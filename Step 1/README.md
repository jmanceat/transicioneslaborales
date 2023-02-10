#  Step 1 - Matriz de Transiciones GEIH

## Sección 0 - Preliminaries

Esta sección del código establece las variables y las rutas necesarias para realizar un análisis de datos. El código comienza con la instrucción "clear all" que limpia todas las variables y objetos previamente cargados en el espacio de trabajo de Stata. Luego, la instrucción "set more off, perm" desactiva el paginado automático y permite guardar los cambios realizados en el espacio de trabajo.

A continuación, se establecen las rutas para acceder a las bases de datos utilizadas en el análisis. Estas rutas se almacenan en variables globales, que son accesibles desde cualquier punto del script. Se establecen rutas para los datos crudos, los datos analizados, los gráficos y las tablas generadas y los archivos de registro.

Por último, se cambia el directorio de trabajo a la ruta especificada para los datos crudos y se cierra y guarda el registro de comandos ejecutados en un archivo específico.

## Sección 1 - Datos de estadísticas vitales 

### Nacimientos

Este código en Stata está generando una base de datos temporal de nacimientos para los años 2020 y 2021. En primer lugar, el código utiliza la base de datos "nac2019.dta" para calcular la tasa de crecimiento de la población. Luego, utiliza un bucle "forvalues" para recorrer los meses del año y generar una nueva base de datos temporal para cada mes del año 2020. La tasa de crecimiento se aplica para reducir el número de observaciones en cada mes. Cada base temporal se guarda con un nombre diferente utilizando la función "tempfile" y "save".

Finalmente, utiliza un bucle similar para generar una base de datos temporal para los primeros tres meses del año 2021 y se aplica una tasa de crecimiento diferente. Todos los datos temporales se fusionan en una sola base de datos y se guardan con el nombre "nac2021.dta" reemplazando cualquier base de datos anterior con el mismo nombre. Es importante mencionar que esta base temporal es solo temporal mientras el Dane (Departamento Administrativo Nacional de Estadística) publica los resultados finales para los años mencionados.


### Fallecidos 

Este código de Stata es utilizado para calcular tasas de crecimiento de fallecidos. Utiliza dos archivos de datos, "nofetal2019" y "nofetal2020", que contienen información sobre defunciones no fetales en un año específico.

En primer lugar, el código utiliza el archivo "nofetal2019" y cuenta el número de fallecidos en ese año. Luego, utiliza ese número para calcular la tasa de crecimiento de fallecidos en 2020, comparando el número de fallecidos en 2020 (296800) con el número de fallecidos en 2019.

Luego, el código utiliza nuevamente el archivo "nofetal2019" pero solo selecciona los registros correspondientes al mes de enero. Luego cuenta el número de fallecidos en Enero de 2019. Utiliza ese número para calcular la tasa de crecimiento de fallecidos en Enero de 2021, comparando el número de fallecidos en Enero de 2021 (34493) con el número de fallecidos en Enero de 2019.

Finalmente, ambas tasas son guardadas como variables globales para ser utilizadas en una línea posterior del código.


## Sección 2 -  Datos

Este código de Stata es un bucle que se utiliza para procesar un conjunto de datos mensuales.

En primer lugar, se definen dos variables locales: "years" y "tokenize". La variable "years" contiene una lista de años, desde 2012 hasta 2021, y "tokenize" contiene una lista de meses, desde enero hasta diciembre. Luego, se inicia un bucle "forval" que recorre los 12 meses del año. Dentro de este bucle, se define una variable local "prior" con el valor 2011.

A continuación, se inicia otro bucle "foreach" que recorre la lista de años definida anteriormente. Dentro de este bucle, se utilizan varios comandos para procesar los datos.

<span style="color: red;">Nota:</span> Los bucles mencionados anteriormente cubren desde la "Sección 2 - Datos" hasta la "Sección 10 - Guardar Resultados" de este archivo. En estos bucles la variable local $`y'$ corresponde al año $t$ y la variable local $`prior'$ corresponde al año $t-1$.

El siguiente comando "use" es utilizado para abrir un archivo de datos específico, en este caso, se está abriendo un archivo mensual con nombre "Bases mensuales Cabecera ``mes'' `y'" del directorio "$data/GEIH/".

El comando "append" se utiliza para agregar otro archivo de datos al conjunto de datos actual, en este caso, se está agregando el archivo "Bases mensuales Resto ``mes'' `y'" y se está creando una nueva variable llamada "resto".

El comando "egen" se utiliza para crear una nueva variable llamada "total_poblacion" que es la suma de los valores de la variable "FEX_C_2011".

El comando "sum" se utiliza para calcular la suma de la variable "total_poblacion" y almacenar el resultado en una matriz llamada "poblacion_total".

Por último, el comando "drop" se utiliza para eliminar la variable "total_poblacion" del conjunto de datos. Los datos que se cargan en este paso fuero creados en el paso "Step 0 - Creación de base anual GEIH". 

## Sección 3 - Datos de migración


Debido a que el proposito de este proyecto de investigación es tener un panorama completo de las transiciones laborales de la población colombiana, también se incluye información del módulo de migración de la GEIH, disponible a través del Dane en el siguiente link: 

- [Modulo de migración GEIH][migracion-link]

[migracion-link]: https://microdatos.dane.gov.co/index.php/catalog/MERCLAB-Microdatos#_r=&collection=&country=&dtype=&from=1970&page=1&ps=&sid=&sk=&sort_by=title&sort_order=&to=2022&topic=&view=s&vk=

Con estos datos, este sección del código se une la información del mercado laboral con la información de migración en donde se utiliza el comando "merge" para unir la información para cada individuo basándose en los identificadores de directorio, secuencia de personas, mes y orden. 

Después de realizar el merge, se crean variables dummy que tienen como función señalar si la persona migró recientemente. 

## Sección 4 - Variables 

### Definición de destinos

En la primera parte de esta sección del código define una serie de variables que describen el destino laboral de una persona en el año $t$ en la  encuesta. Las variables se generan a partir de preguntas en la encuesta que se identifican por sus códigos (por ejemplo, "P6040" para la edad de la persona).

La primera línea "gen fex_entero=round(FEX_C_2011)" genera una nueva variable "fex_entero" que es igual a la variable "FEX_C_2011" redondeada al entero más cercano. Este paso se realiza con el finde que en el momento de realizar los análisis agregados, sea mucha más fácil aplicar lod factores de expasión a los individuos. 

El resto del código define nuevas variables que describen los diferentes destinos laborales de las personas en la encuesta, basados en las respuestas a las preguntas de la encuesta. Estas nuevas variables se identifican por un sufijo "_y" en el nombre para denotar que la variable corresponde a un destino (por ejemplo, "m_y" para describir a los trabajadores menores de la edad de trabajar en el año $t$).

Por ejemplo, la línea "gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))" genera una variable "m_y" que es 1 si la edad de la persona (medida por la variable "P6040") es mayor o igual a 0 y menor que 12 y la variable "resto" es igual a 0 (para las cabeceras municipales), o si la edad de la persona es mayor o igual a 0 y menor que 10 y la variable "resto" es igual a 1 (para el resto de municipios).

La última línea ```dis `prior' `y'``` imprime los años $t-1$ y $t$ en los que se encuentra el loop.

### Definición de origenes 

En la segunda parte de esta sección del código define una serie de variables que describen el origen laboral de una persona en el año $t-1$ en la  encuesta. La letra "x" en el nombre de las variables indica que se trata del "origen" de la persona en el mercado laboral.

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

Cada categoría se define a través de una serie de condiciones que se aplican a diferentes variables que corresponden a preguntas retrospectivas de la GEIH, tales como la edad, el estatus de empleo empleo anetior, el tiempo desocupado entre el anterior empleo y el actual, y el tipo de trabajo anterior, entre otros. Luego, se utiliza la función egen para identificar el valor máximo en cada fila y asignar a cada persona su categoría correspondiente.

En general, el objetivo de esta sección del código es clasificar a las personas según su situación laboral en los meses $t-1$ y $t$, y proporcionar una base para el análisis posterior de los datos.

## Seccion 5 - Transiciones 

En esta sección del código se generan las variables que indican si hay una transición de un estado a otro en dos períodos consecutivos ($x$ e $y$).

La lista de variables "var" incluye "m", "i", "d", "e", "e0", "e5", "p", "o", "of", "oc", "os", "on", "oj", "ot" y "r".

Para cada una de estas variables, se genera una nueva variable que indica si ambas (x e y) tienen un valor igual a 1. Por ejemplo, para la variable "m", se genera la variable "m_m" que es igual a 1 si "m_x" es igual a 1 y "m_y" es igual a 1. Es decir, si la persona fue menor de la edad para trabajar en el origen x ($t-12$) y continua siendo menor de la edad para trabajar en el destino $y$ ($t$) Esto se repite para cada una de las variables en la lista "var".

La última línea "```dis `prior' `y'```" imprime los años $t-1$ y $t$ en los que se encuentra el loop.


## Sección 6 - Matriz para guardar resultados

Este código en Stata crea una matriz llamada "mes_prior_y" con 14 filas y 13 columnas. La línea "mat list 'mes'_prior'_y'" imprime una lista de la matriz creada.

Luego, los nombres de las columnas y las filas de la matriz se establecen con "mat colnames 'mes'prior'_y' = m i d e p of oc os on oj ot qpd emi" y "mat rownames 'mes'prior'_y' = nac m i d e p of oc os on oj ot qpd imi", respectivamente.

Finalmente, la función "svmat2" guarda la matriz con los nombres de columna y fila especificados en los argumentos "names(col)" y "rnames(Origen_Destino)".