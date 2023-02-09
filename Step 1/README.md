#  Step 1 - Matriz de Transiciones GEIH

## Seccion 0 - Preliminaries

Esta sección del código establece las variables y las rutas necesarias para realizar un análisis de datos. El código comienza con la instrucción "clear all" que limpia todas las variables y objetos previamente cargados en el espacio de trabajo de Stata. Luego, la instrucción "set more off, perm" desactiva el paginado automático y permite guardar los cambios realizados en el espacio de trabajo.

A continuación, se establecen las rutas para acceder a las bases de datos utilizadas en el análisis. Estas rutas se almacenan en variables globales, que son accesibles desde cualquier punto del script. Se establecen rutas para los datos crudos, los datos analizados, los gráficos y las tablas generadas y los archivos de registro.

Por último, se cambia el directorio de trabajo a la ruta especificada para los datos crudos y se cierra y guarda el registro de comandos ejecutados en un archivo específico.

## Seccion 1 - Datos de estadísticas vitales 

### Nacimientos

Este código en Stata está generando una base de datos temporal de nacimientos para los años 2020 y 2021. En primer lugar, el código utiliza la base de datos "nac2019.dta" para calcular la tasa de crecimiento de la población. Luego, utiliza un bucle "forvalues" para recorrer los meses del año y generar una nueva base de datos temporal para cada mes del año 2020. La tasa de crecimiento se aplica para reducir el número de observaciones en cada mes. Cada base temporal se guarda con un nombre diferente utilizando la función "tempfile" y "save".

Finalmente, utiliza un bucle similar para generar una base de datos temporal para los primeros tres meses del año 2021 y se aplica una tasa de crecimiento diferente. Todos los datos temporales se fusionan en una sola base de datos y se guardan con el nombre "nac2021.dta" reemplazando cualquier base de datos anterior con el mismo nombre. Es importante mencionar que esta base temporal es solo temporal mientras el Dane (Departamento Administrativo Nacional de Estadística) publica los resultados finales para los años mencionados.


### Fallecidos 

Este código de Stata es utilizado para calcular tasas de crecimiento de fallecidos. Utiliza dos archivos de datos, "nofetal2019" y "nofetal2020", que contienen información sobre defunciones no fetales en un año específico.

En primer lugar, el código utiliza el archivo "nofetal2019" y cuenta el número de fallecidos en ese año. Luego, utiliza ese número para calcular la tasa de crecimiento de fallecidos en 2020, comparando el número de fallecidos en 2020 (296800) con el número de fallecidos en 2019.

Luego, el código utiliza nuevamente el archivo "nofetal2019" pero solo selecciona los registros correspondientes al mes de enero. Luego cuenta el número de fallecidos en Enero de 2019. Utiliza ese número para calcular la tasa de crecimiento de fallecidos en Enero de 2021, comparando el número de fallecidos en Enero de 2021 (34493) con el número de fallecidos en Enero de 2019.

Finalmente, ambas tasas son guardadas como variables globales para ser utilizadas en una línea posterior del código.


## Seccion 2 -  Datos

Este código de Stata es un bucle que se utiliza para procesar un conjunto de datos mensuales.

En primer lugar, se definen dos variables locales: "years" y "tokenize". La variable "years" contiene una lista de años, desde 2012 hasta 2021, y "tokenize" contiene una lista de meses, desde enero hasta diciembre. Luego, se inicia un bucle "forval" que recorre los 12 meses del año. Dentro de este bucle, se define una variable local "prior" con el valor 2011.

A continuación, se inicia otro bucle "foreach" que recorre la lista de años definida anteriormente. Dentro de este bucle, se utilizan varios comandos para procesar los datos.

<span style="color: red;">Nota:</span> Los bucles mencionados anteriormente cubren desde la "Sección 2 - Datos" hasta la "Sección 10 - Guardar Resultados" de este archivo. 

El siguiente comando "use" es utilizado para abrir un archivo de datos específico, en este caso, se está abriendo un archivo mensual con nombre "Bases mensuales Cabecera ``mes'' `y'" del directorio "$data/GEIH/".

El comando "append" se utiliza para agregar otro archivo de datos al conjunto de datos actual, en este caso, se está agregando el archivo "Bases mensuales Resto ``mes'' `y'" y se está creando una nueva variable llamada "resto".

El comando "egen" se utiliza para crear una nueva variable llamada "total_poblacion" que es la suma de los valores de la variable "FEX_C_2011".

El comando "sum" se utiliza para calcular la suma de la variable "total_poblacion" y almacenar el resultado en una matriz llamada "poblacion_total".

Por último, el comando "drop" se utiliza para eliminar la variable "total_poblacion" del conjunto de datos. Los datos que se cargan en este paso fuero creados en el paso "Step 0 - Creación de base anual GEIH". 

### Sección 3 - Datos de migración


Debido a que el proposito de este proyecto de investigación es tener un panorama completo de las transiciones laborales de la población colombiana, también se incluye información del módulo de migración de la GEIH, disponible a través del Dane en el siguiente link: 

- [Modulo de migración GEIH][migracion-link]

[migracion-link]: https://microdatos.dane.gov.co/index.php/catalog/MERCLAB-Microdatos#_r=&collection=&country=&dtype=&from=1970&page=1&ps=&sid=&sk=&sort_by=title&sort_order=&to=2022&topic=&view=s&vk=

Con estos datos, este sección del código se une la información del mercado laboral con la información de migración en donde se utiliza el comando "merge" para unir la información para cada individuo basándose en los identificadores de directorio, secuencia de personas, mes y orden. 

Después de realizar el merge, se crean variables dummy que tienen como función señalar si la persona migró recientemente. 