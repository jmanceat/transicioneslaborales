# Step 0 - Creación base GEIH anual

## Seccion 0 - Preliminaries

Este código de Stata es un script que establece las variables y las rutas necesarias para realizar un análisis de datos. El código comienza con la instrucción "clear all" que limpia todas las variables y objetos previamente cargados en el espacio de trabajo de Stata. Luego, la instrucción "set more off, perm" desactiva el paginado automático y permite guardar los cambios realizados en el espacio de trabajo.

A continuación, se establecen las rutas para acceder a las bases de datos utilizadas en el análisis. Estas rutas se almacenan en variables globales, que son accesibles desde cualquier punto del script. Se establecen rutas para los datos crudos, los datos analizados, los gráficos y las tablas generadas y los archivos de registro.

Por último, se cambia el directorio de trabajo a la ruta especificada para los datos crudos y se cierra y guarda el registro de comandos ejecutados en un archivo específico.


## Seccion 1 - Organización de variables

 Esta sección del código comienza iterando sobre tres conjuntos de variables (areas, bases y meses) y utiliza estos conjuntos para cargar y modificar un conjunto de bases de datos con nombres específicos.

La primera sección del código crea tres variables locales: "areas", "bases" y "meses", las cuales contienen los nombres de las áreas, bases de datos y los meses que se utilizarán en el script.

El siguiente bloque de código es un ciclo "foreach" anidado que itera sobre cada una de las variables locales. El ciclo "foreach" es utilizado para repetir un bloque de código para cada valor de una variable. En este caso, el ciclo itera sobre las variables "areas", "bases" y "meses" simultáneamente, generando todas las combinaciones posibles.

Dentro del ciclo anidado, se utiliza la función "use" para cargar una base de datos específica utilizando las variables "a", "b" y "m" para construir el nombre de archivo. Luego, se utiliza la función "cap drop" para eliminar una variable específica, se utiliza la función "rename" para cambiar el nombre de todas las variables a mayúsculas y se utiliza la función "gen" para crear una variable llamada "MES" con el valor actual de "m". Finalmente, el código utiliza la función "noisily save" para guardar la base de datos modificada en el mismo lugar de donde se cargó, reemplazando la versión anterior.

A partir de este punto se utiliza una estructura de iteración similar para la organización de variables especificas (MES, REGIS, CLASE, AREA y DPTO)

 ## Seccion 2 - Merge de bases especificas

 