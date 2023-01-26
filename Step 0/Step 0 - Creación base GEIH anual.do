********************************************************************************
********************************************************************************

*                        Creacion base GEIH                                    *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	02/Mar/2020
				* Autor:		Nicolas Mancera 
*/

********************************************************************************
*                          Seccion 0 - Preliminaries		                   *
********************************************************************************
	clear all
	set   more off, perm 
	
* Rutas de las bases 

	global rawdata  "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data"
	global data 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Data"
	global graphs 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Graphs/Ejercicios GEIH"
	global tables 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Tables/Ejercicios GEIH"
	global logs     "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Log_files/Ejercicios GEIH"
	
	cd "${rawdata}"

	cap log close 
	log using "${logs}/Step 0 - Creacion base GEIH.smcl", replace

********************************************************************************
* 	               Seccion 1 - Organizacion de variables 		              *
********************************************************************************
	
* Guardar todas las bases con la variables en mayuscula 

local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'
local meses   "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"


foreach a of local areas {
foreach b of local bases {
foreach m of local meses {
forvalues i=2007/2020    {

use  "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", clear  

cap drop mes	
rename *, upper 
cap drop MES
gen MES="`m'"	
	
noisily save "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", replace  

}
}
}
}
	
* Arreglar la variable MES para todas las bases (Esta matriz muestra como esta compuesta la variable mes de todos los años y además muestra en que años no esta la variable )


local areas "Area Cabecera Resto"
local bases "Caracteristicas generales (Personas)" "Fuerza de trabajo"  "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" 

foreach a of local areas {

local meses   "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

mat mes_`a'=J(1, 12, .)
mat rownames mes_`a'=  2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
mat colnames mes_`a'= Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre

local row=0 

forvalues i=2007/2020 {
	local col=0
	foreach m of local meses {

		use  "$rawdata/GEIH/`i'/`m'/`a' - Caracteristicas generales (Personas).dta", clear  
		dis `i' "`m'" "`a'"
		cap tab MES, nolab 
		cap mat mes_`a'[`row'+1, `col'+1]=r(r) 

		local col=`col'+1 

	}

local row=`row'+1 
}
}


mat list mes_Area
mat list mes_Cabecera
mat list mes_Resto 

* Arreglar la variable REGIS y CLASE que esta en string en los años 2018 2019

local areas "Area Cabecera Resto"
local meses "Enero FebreroMarzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

forvalues i=2007/2019 {
foreach a of local areas { 
foreach m of local meses {
foreach b of local bases {
cap {
use "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", clear 

cap destring REGIS, replace force 
cap destring CLASE, replace force 

save "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", replace 
}

}
}
}
}


****************************** Variable DPTO ***********************************

* Departamentos que aparecen de 2008 a 2016 

local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'
local meses  "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

local counter=1
foreach a of local areas {
foreach b of local bases {
foreach m of local meses {
forvalues i=2008/2016    {

use  "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", clear  

dis `i' "`m'" "`a'" "`b'" 
decode DPTO, gen(DPTO_S1)
keep DPTO_S1
duplicates drop DPTO_S1, force 

tempfile `counter'

save ``counter''

local counter=`counter'+1

}
}
}
}

use `1', clear 

local counter=1
foreach a of local areas {
foreach b of local bases {
foreach m of local meses {
forvalues i=2008/2016    {

append using ``counter''
noisily dis `counter'
local counter=`counter'+1

}
}
}
}

duplicates drop DPTO_S1, force 

gen DPTO_S=""

replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "08")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "11")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "15")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "18")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "19")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "20")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "25")
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "27")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "41")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "44")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "47")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "50")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "54")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "63")
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "70")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "73")
replace DPTO_S="Antioquia" if ustrregexm(DPTO_S1, "Antioquia")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "Atlántico")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "ntico")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "Bogot")
replace DPTO_S="Bolivar" if ustrregexm(DPTO_S1, "Bol")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "Boyac")
replace DPTO_S="Caldas" if ustrregexm(DPTO_S1, "Caldas")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "Cauca")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "Cesar")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "sar") & DPTO_S1!="Risaralda"
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "Choc")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "Cundinamarca")
replace DPTO_S="Cordoba" if ustrregexm(DPTO_S1, "rdoba")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "uajira")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "Huila")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "Magdalena")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "Meta")
replace DPTO_S="Narino" if ustrregexm(DPTO_S1, "Nari")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "Norte")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "Quind")
replace DPTO_S="Risaralda" if ustrregexm(DPTO_S1, "Risaralda")
replace DPTO_S="Santander" if DPTO_S1=="Santander"
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "Sucre")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "Tolima")
replace DPTO_S="Valle del Cauca" if ustrregexm(DPTO_S1, "Valle del")

cap drop DPTO

gen DPTO=""

replace DPTO="05" if DPTO_S=="Antioquia"
replace DPTO="08" if DPTO_S=="Atlantico"
replace DPTO="11" if DPTO_S=="Bogota, D.C."
replace DPTO="13" if DPTO_S=="Bolivar"
replace DPTO="15" if DPTO_S=="Boyaca"
replace DPTO="17" if DPTO_S=="Caldas"
replace DPTO="18" if DPTO_S=="Caqueta"
replace DPTO="19" if DPTO_S=="Cauca"
replace DPTO="20" if DPTO_S=="Cesar"
replace DPTO="27" if DPTO_S=="Choco"
replace DPTO="23" if DPTO_S=="Cordoba"
replace DPTO="25" if DPTO_S=="Cundinamarca"
replace DPTO="41" if DPTO_S=="Huila"
replace DPTO="44" if DPTO_S=="La Guajira"
replace DPTO="47" if DPTO_S=="Magdalena"
replace DPTO="50" if DPTO_S=="Meta"
replace DPTO="52" if DPTO_S=="Narino"
replace DPTO="54" if DPTO_S=="Norte de Santander"
replace DPTO="63" if DPTO_S=="Quindio"
replace DPTO="66" if DPTO_S=="Risaralda"
replace DPTO="68" if DPTO_S=="Santander"
replace DPTO="70" if DPTO_S=="Sucre"
replace DPTO="73" if DPTO_S=="Tolima"
replace DPTO="76" if DPTO_S=="Valle del Cauca"
replace DPTO="81" if DPTO_S=="Arauca"
replace DPTO="85" if DPTO_S=="Casanare"
replace DPTO="86" if DPTO_S=="Putumayo"
replace DPTO="88" if DPTO_S=="Archipielago de San Andres"
replace DPTO="91" if DPTO_S=="Amazonas"
replace DPTO="94" if DPTO_S=="Guainia"
replace DPTO="95" if DPTO_S=="Guaviare"
replace DPTO="97" if DPTO_S=="Vaupes"
replace DPTO="99" if DPTO_S=="Vichada"

save "$data/Listado_Departamentos_GEIH.dta", replace  // Esta base contiene la lista de departamentos que aparecen entre 2008 y 2016

clear all 


****************************** Variable AREA ***********************************

* Nota: La variable AREA solo aparece en las bases de Area y Cabecera

* Areas que aparecen de 2008 a 2016 

local areas "Area Cabecera"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'
local meses  "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

local counter=1
foreach a of local areas {
foreach b of local bases {
foreach m of local meses {
forvalues i=2008/2016    {

use  "$rawdata/GEIH/`i'/`m'/`a' - `b'.dta", clear  

dis `i' "`m'" "`a'" "`b'" 
decode AREA, gen(AREA_S1)
keep AREA_S1
duplicates drop AREA_S1, force 

tempfile `counter'

save ``counter''

local counter=`counter'+1

}
}
}
}

use `1', clear 

local counter=1
foreach a of local areas {
foreach b of local bases {
foreach m of local meses {
forvalues i=2008/2016    {

append using ``counter''
noisily dis `counter'
local counter=`counter'+1

}
}
}
}

duplicates drop AREA_S1, force 

gen AREA_S=""

replace AREA_S="Medellin" if ustrregexm(AREA_S1, "05")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "08")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "11")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "13")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "15")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "17")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "18")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "19")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "20")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "23")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "25")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "27")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "41")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "44")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "47")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "50")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "52")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "54")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "63")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "66")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "68")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "70")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "73")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "76")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Antioquia")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Mede")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Atlántico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "ntico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Barranquilla")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "Bogot")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Bol")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Cartagena")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Boyac")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Tunja")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Caldas")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Manizales")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Florencia")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Cauca")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Popay")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Cesar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Valledupar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "sar") & AREA_S1!="Risaralda"
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Choc")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Quibd")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "Cundinamarca")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "rdoba")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "Monter")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "uajira")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "Riohacha")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Huila")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Neiva")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Magdalena")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Santa Marta")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "arta") & AREA_S1!="Cartagena"
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Meta")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Villavicencio")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Nari")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Pasto")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "Norte")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "cuta")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Quind")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Armenia")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Risaralda")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Pereira")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Santander")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Bucaramanga")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sucre")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sincelejo")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Tolima")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Ibagu")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Valle del")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Cali")

cap drop AREA

gen AREA=""

replace AREA="05" if AREA_S=="Medellin"
replace AREA="08" if AREA_S=="Barranquilla"
replace AREA="11" if AREA_S=="Bogota, D.C."
replace AREA="13" if AREA_S=="Cartagena"
replace AREA="15" if AREA_S=="Tunja"
replace AREA="17" if AREA_S=="Manizales"
replace AREA="18" if AREA_S=="Florencia"
replace AREA="19" if AREA_S=="Popayan"
replace AREA="20" if AREA_S=="Valledupar"
replace AREA="27" if AREA_S=="Quibdo"
replace AREA="23" if AREA_S=="Monteria"
replace AREA="25" if AREA_S=="Cundinamarca"
replace AREA="41" if AREA_S=="Neiva"
replace AREA="44" if AREA_S=="Riohacha"
replace AREA="47" if AREA_S=="Santa Marta"
replace AREA="50" if AREA_S=="Villavicencio"
replace AREA="52" if AREA_S=="Pasto"
replace AREA="54" if AREA_S=="Cucuta"
replace AREA="63" if AREA_S=="Armenia"
replace AREA="66" if AREA_S=="Pereira"
replace AREA="68" if AREA_S=="Bucaramanga"
replace AREA="70" if AREA_S=="Sincelejo"
replace AREA="73" if AREA_S=="Ibague"
replace AREA="76" if AREA_S=="Cali"
replace AREA="81" if AREA_S=="Arauca"
replace AREA="85" if AREA_S=="Yopal"
replace AREA="86" if AREA_S=="Mocoa"
replace AREA="88" if AREA_S=="San Andres"
replace AREA="91" if AREA_S=="Leticia"
replace AREA="94" if AREA_S=="Inirida"
replace AREA="95" if AREA_S=="San Jose del Guaviare"
replace AREA="97" if AREA_S=="Mitu"
replace AREA="99" if AREA_S=="Puerto Carreno"

save "$data/Listado_AREA_GEIH.dta", replace  // Esta base contiene la lista de areas metropolitanas que aparecen entre 2008 y 2016



clear all 


************************ Corrección de variables *******************************

* Años 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 (En 2007 y 2017 solo se van a arreglar los primeros meses en este paso)

*** Variable DPTO

local years "2017"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto" 
local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 

decode DPTO, gen(DPTO_S1)
rename DPTO DPTO_BAD  

gen DPTO_S=""

replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "08")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "11")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "15")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "18")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "19")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "20")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "25")
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "27")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "41")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "44")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "47")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "50")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "54")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "63")
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "70")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "73")
replace DPTO_S="Antioquia" if ustrregexm(DPTO_S1, "Antioquia")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "Atlántico")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "ntico")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "Bogot")
replace DPTO_S="Bolivar" if ustrregexm(DPTO_S1, "Bol")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "Boyac")
replace DPTO_S="Caldas" if ustrregexm(DPTO_S1, "Caldas")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "Cauca")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "Cesar")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "sar") & DPTO_S1!="Risaralda"
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "Choc")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "Cundinamarca")
replace DPTO_S="Cordoba" if ustrregexm(DPTO_S1, "rdoba")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "uajira")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "Huila")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "Magdalena")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "Meta")
replace DPTO_S="Narino" if ustrregexm(DPTO_S1, "Nari")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "Norte")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "Quind")
replace DPTO_S="Risaralda" if ustrregexm(DPTO_S1, "Risaralda")
replace DPTO_S="Santander" if DPTO_S1=="Santander"
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "Sucre")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "Tolima")
replace DPTO_S="Valle del Cauca" if ustrregexm(DPTO_S1, "Valle del")

gen DPTO=""

replace DPTO="05" if DPTO_S=="Antioquia"
replace DPTO="08" if DPTO_S=="Atlantico"
replace DPTO="11" if DPTO_S=="Bogota, D.C."
replace DPTO="13" if DPTO_S=="Bolivar"
replace DPTO="15" if DPTO_S=="Boyaca"
replace DPTO="17" if DPTO_S=="Caldas"
replace DPTO="18" if DPTO_S=="Caqueta"
replace DPTO="19" if DPTO_S=="Cauca"
replace DPTO="20" if DPTO_S=="Cesar"
replace DPTO="27" if DPTO_S=="Choco"
replace DPTO="23" if DPTO_S=="Cordoba"
replace DPTO="25" if DPTO_S=="Cundinamarca"
replace DPTO="41" if DPTO_S=="Huila"
replace DPTO="44" if DPTO_S=="La Guajira"
replace DPTO="47" if DPTO_S=="Magdalena"
replace DPTO="50" if DPTO_S=="Meta"
replace DPTO="52" if DPTO_S=="Narino"
replace DPTO="54" if DPTO_S=="Norte de Santander"
replace DPTO="63" if DPTO_S=="Quindio"
replace DPTO="66" if DPTO_S=="Risaralda"
replace DPTO="68" if DPTO_S=="Santander"
replace DPTO="70" if DPTO_S=="Sucre"
replace DPTO="73" if DPTO_S=="Tolima"
replace DPTO="76" if DPTO_S=="Valle del Cauca"
replace DPTO="81" if DPTO_S=="Arauca"
replace DPTO="85" if DPTO_S=="Casanare"
replace DPTO="86" if DPTO_S=="Putumayo"
replace DPTO="88" if DPTO_S=="Archipielago de San Andres"
replace DPTO="91" if DPTO_S=="Amazonas"
replace DPTO="94" if DPTO_S=="Guainia"
replace DPTO="95" if DPTO_S=="Guaviare"
replace DPTO="97" if DPTO_S=="Vaupes"
replace DPTO="99" if DPTO_S=="Vichada"


save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}



local years "2008 2009 2010 2011 2012 2013 2014 2015 2016"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre" 
local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 

decode DPTO, gen(DPTO_S1)
rename DPTO DPTO_BAD  

gen DPTO_S=""

replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "08")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "11")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "15")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "18")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "19")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "20")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "25")
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "27")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "41")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "44")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "47")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "50")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "54")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "63")
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "70")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "73")
replace DPTO_S="Antioquia" if ustrregexm(DPTO_S1, "Antioquia")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "Atlántico")
replace DPTO_S="Atlantico" if ustrregexm(DPTO_S1, "ntico")
replace DPTO_S="Bogota, D.C." if ustrregexm(DPTO_S1, "Bogot")
replace DPTO_S="Bolivar" if ustrregexm(DPTO_S1, "Bol")
replace DPTO_S="Boyaca" if ustrregexm(DPTO_S1, "Boyac")
replace DPTO_S="Caldas" if ustrregexm(DPTO_S1, "Caldas")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cauca" if ustrregexm(DPTO_S1, "Cauca")
replace DPTO_S="Caqueta" if ustrregexm(DPTO_S1, "Caquet")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "Cesar")
replace DPTO_S="Cesar" if ustrregexm(DPTO_S1, "sar") & DPTO_S1!="Risaralda"
replace DPTO_S="Choco" if ustrregexm(DPTO_S1, "Choc")
replace DPTO_S="Cundinamarca" if ustrregexm(DPTO_S1, "Cundinamarca")
replace DPTO_S="Cordoba" if ustrregexm(DPTO_S1, "rdoba")
replace DPTO_S="La Guajira" if ustrregexm(DPTO_S1, "uajira")
replace DPTO_S="Huila" if ustrregexm(DPTO_S1, "Huila")
replace DPTO_S="Magdalena" if ustrregexm(DPTO_S1, "Magdalena")
replace DPTO_S="Meta" if ustrregexm(DPTO_S1, "Meta")
replace DPTO_S="Narino" if ustrregexm(DPTO_S1, "Nari")
replace DPTO_S="Norte de Santander" if ustrregexm(DPTO_S1, "Norte")
replace DPTO_S="Quindio" if ustrregexm(DPTO_S1, "Quind")
replace DPTO_S="Risaralda" if ustrregexm(DPTO_S1, "Risaralda")
replace DPTO_S="Santander" if DPTO_S1=="Santander"
replace DPTO_S="Sucre" if ustrregexm(DPTO_S1, "Sucre")
replace DPTO_S="Tolima" if ustrregexm(DPTO_S1, "Tolima")
replace DPTO_S="Valle del Cauca" if ustrregexm(DPTO_S1, "Valle del")

gen DPTO=""

replace DPTO="05" if DPTO_S=="Antioquia"
replace DPTO="08" if DPTO_S=="Atlantico"
replace DPTO="11" if DPTO_S=="Bogota, D.C."
replace DPTO="13" if DPTO_S=="Bolivar"
replace DPTO="15" if DPTO_S=="Boyaca"
replace DPTO="17" if DPTO_S=="Caldas"
replace DPTO="18" if DPTO_S=="Caqueta"
replace DPTO="19" if DPTO_S=="Cauca"
replace DPTO="20" if DPTO_S=="Cesar"
replace DPTO="27" if DPTO_S=="Choco"
replace DPTO="23" if DPTO_S=="Cordoba"
replace DPTO="25" if DPTO_S=="Cundinamarca"
replace DPTO="41" if DPTO_S=="Huila"
replace DPTO="44" if DPTO_S=="La Guajira"
replace DPTO="47" if DPTO_S=="Magdalena"
replace DPTO="50" if DPTO_S=="Meta"
replace DPTO="52" if DPTO_S=="Narino"
replace DPTO="54" if DPTO_S=="Norte de Santander"
replace DPTO="63" if DPTO_S=="Quindio"
replace DPTO="66" if DPTO_S=="Risaralda"
replace DPTO="68" if DPTO_S=="Santander"
replace DPTO="70" if DPTO_S=="Sucre"
replace DPTO="73" if DPTO_S=="Tolima"
replace DPTO="76" if DPTO_S=="Valle del Cauca"
replace DPTO="81" if DPTO_S=="Arauca"
replace DPTO="85" if DPTO_S=="Casanare"
replace DPTO="86" if DPTO_S=="Putumayo"
replace DPTO="88" if DPTO_S=="Archipielago de San Andres"
replace DPTO="91" if DPTO_S=="Amazonas"
replace DPTO="94" if DPTO_S=="Guainia"
replace DPTO="95" if DPTO_S=="Guaviare"
replace DPTO="97" if DPTO_S=="Vaupes"
replace DPTO="99" if DPTO_S=="Vichada"


save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}

* Años 2007, 2017 2018 y 2019  (Para 2007 y 2017 se arreglarán los meses que faltaron del paso anterior)

local years "2017"
local meses "Septiembre Octubre Noviembre Diciembre"
local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 


gen DPTO_S="" 

replace DPTO_S="Antioquia" if DPTO=="05"
replace DPTO_S="Atlantico" if DPTO=="08"
replace DPTO_S="Bogota, D.C." if DPTO=="11"
replace DPTO_S="Bolivar" if DPTO=="13"
replace DPTO_S="Boyaca" if DPTO=="15"
replace DPTO_S="Caldas" if DPTO=="17"
replace DPTO_S="Caqueta" if DPTO=="18"
replace DPTO_S="Cauca" if DPTO=="19"
replace DPTO_S="Cesar" if DPTO=="20"
replace DPTO_S="Choco" if DPTO=="27"
replace DPTO_S="Cordoba" if DPTO=="23"
replace DPTO_S="Cundinamarca" if DPTO=="25"
replace DPTO_S="Huila" if DPTO=="41"
replace DPTO_S="La Guajira" if DPTO=="44"
replace DPTO_S="Magdalena" if DPTO=="47"
replace DPTO_S="Meta" if DPTO=="50"
replace DPTO_S="Narino" if DPTO=="52"
replace DPTO_S="Norte de Santander" if DPTO=="54"
replace DPTO_S="Quindio" if DPTO=="63"
replace DPTO_S="Risaralda" if DPTO=="66"
replace DPTO_S="Santander" if DPTO=="68"
replace DPTO_S="Sucre" if DPTO=="70"
replace DPTO_S="Tolima" if DPTO=="73"
replace DPTO_S="Valle del Cauca" if DPTO=="76"
replace DPTO_S="Arauca" if DPTO=="81"
replace DPTO_S="Casanare" if DPTO=="85"
replace DPTO_S="Putumayo" if DPTO=="86"
replace DPTO_S="Archipielago de San Andres" if DPTO=="88"
replace DPTO_S="Amazonas" if DPTO=="91"
replace DPTO_S="Guainia" if DPTO=="94"
replace DPTO_S="Guaviare" if DPTO=="95"
replace DPTO_S="Vaupes" if DPTO=="97"
replace DPTO_S="Vichada" if DPTO=="99"

save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}


* Arreglo base 2018 (la variable dpto estaba numerica)

use  "$rawdata/GEIH/2018/Enero/Cabecera - Otras actividades y ayudas en la semana.dta", clear  


rename DPTO DPTO_BAD
tostring DPTO_BAD, gen(DPTO) force 
gen temp="0"
egen temp_2=concat(temp DPTO) if DPTO=="5"|DPTO=="8"
replace DPTO=temp_2 if DPTO=="5"|DPTO=="8"

* gen str4 cocupacion_1 = string(cocupacion,"%04.0f") Este comando tambien sirve para lo mismo

local years "2020" // "2007 2018 2019 2020"
local meses  "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"
local areas "Area Cabecera Resto"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

cap{

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 


gen DPTO_S="" 

replace DPTO_S="Antioquia" if DPTO=="05"
replace DPTO_S="Atlantico" if DPTO=="08"
replace DPTO_S="Bogota, D.C." if DPTO=="11"
replace DPTO_S="Bolivar" if DPTO=="13"
replace DPTO_S="Boyaca" if DPTO=="15"
replace DPTO_S="Caldas" if DPTO=="17"
replace DPTO_S="Caqueta" if DPTO=="18"
replace DPTO_S="Cauca" if DPTO=="19"
replace DPTO_S="Cesar" if DPTO=="20"
replace DPTO_S="Choco" if DPTO=="27"
replace DPTO_S="Cordoba" if DPTO=="23"
replace DPTO_S="Cundinamarca" if DPTO=="25"
replace DPTO_S="Huila" if DPTO=="41"
replace DPTO_S="La Guajira" if DPTO=="44"
replace DPTO_S="Magdalena" if DPTO=="47"
replace DPTO_S="Meta" if DPTO=="50"
replace DPTO_S="Narino" if DPTO=="52"
replace DPTO_S="Norte de Santander" if DPTO=="54"
replace DPTO_S="Quindio" if DPTO=="63"
replace DPTO_S="Risaralda" if DPTO=="66"
replace DPTO_S="Santander" if DPTO=="68"
replace DPTO_S="Sucre" if DPTO=="70"
replace DPTO_S="Tolima" if DPTO=="73"
replace DPTO_S="Valle del Cauca" if DPTO=="76"
replace DPTO_S="Arauca" if DPTO=="81"
replace DPTO_S="Casanare" if DPTO=="85"
replace DPTO_S="Putumayo" if DPTO=="86"
replace DPTO_S="Archipielago de San Andres" if DPTO=="88"
replace DPTO_S="Amazonas" if DPTO=="91"
replace DPTO_S="Guainia" if DPTO=="94"
replace DPTO_S="Guaviare" if DPTO=="95"
replace DPTO_S="Vaupes" if DPTO=="97"
replace DPTO_S="Vichada" if DPTO=="99"

save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}
}


*************************** Variable AREA 


local years "2017"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto" 
local areas "Area Cabecera"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 

decode AREA, gen(AREA_S1)
rename AREA  AREA_BAD
  
gen AREA_S=""

replace AREA_S="Medellin" if ustrregexm(AREA_S1, "05")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "08")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "11")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "13")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "15")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "17")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "18")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "19")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "20")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "23")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "25")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "27")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "41")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "44")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "47")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "50")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "52")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "54")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "63")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "66")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "68")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "70")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "73")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "76")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Antioquia")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Mede")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Atlántico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "ntico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Barranquilla")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "Bogot")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Bol")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Cartagena")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Boyac")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Tunja")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Caldas")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Manizales")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Florencia")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Cauca")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Popay")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Cesar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Valledupar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "sar") & AREA_S1!="Risaralda"
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Choc")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Quibd")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "Cundinamarca")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "rdoba")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "Monter")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "uajira")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "Riohacha")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Huila")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Neiva")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Magdalena")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Santa Marta")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "arta") & AREA_S1!="Cartagena"
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Meta")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Villavicencio")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Nari")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Pasto")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "Norte")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "cuta")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Quind")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Armenia")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Risaralda")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Pereira")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Santander")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Bucaramanga")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sucre")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sincelejo")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Tolima")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Ibagu")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Valle del")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Cali")


gen AREA=""

replace AREA="05" if AREA_S=="Medellin"
replace AREA="08" if AREA_S=="Barranquilla"
replace AREA="11" if AREA_S=="Bogota, D.C."
replace AREA="13" if AREA_S=="Cartagena"
replace AREA="15" if AREA_S=="Tunja"
replace AREA="17" if AREA_S=="Manizales"
replace AREA="18" if AREA_S=="Florencia"
replace AREA="19" if AREA_S=="Popayan"
replace AREA="20" if AREA_S=="Valledupar"
replace AREA="27" if AREA_S=="Quibdo"
replace AREA="23" if AREA_S=="Monteria"
replace AREA="25" if AREA_S=="Cundinamarca"
replace AREA="41" if AREA_S=="Neiva"
replace AREA="44" if AREA_S=="Riohacha"
replace AREA="47" if AREA_S=="Santa Marta"
replace AREA="50" if AREA_S=="Villavicencio"
replace AREA="52" if AREA_S=="Pasto"
replace AREA="54" if AREA_S=="Cucuta"
replace AREA="63" if AREA_S=="Armenia"
replace AREA="66" if AREA_S=="Pereira"
replace AREA="68" if AREA_S=="Bucaramanga"
replace AREA="70" if AREA_S=="Sincelejo"
replace AREA="73" if AREA_S=="Ibague"
replace AREA="76" if AREA_S=="Cali"
replace AREA="81" if AREA_S=="Arauca"
replace AREA="85" if AREA_S=="Yopal"
replace AREA="86" if AREA_S=="Mocoa"
replace AREA="88" if AREA_S=="San Andres"
replace AREA="91" if AREA_S=="Leticia"
replace AREA="94" if AREA_S=="Inirida"
replace AREA="95" if AREA_S=="San Jose del Guaviare"
replace AREA="97" if AREA_S=="Mitu"
replace AREA="99" if AREA_S=="Puerto Carreno"

save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}



local years "2008 2009 2010 2011 2012 2013 2014 2015 2016"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre" 
local areas "Area Cabecera"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 

decode AREA, gen(AREA_S1)
rename AREA AREA_BAD  

gen AREA_S=""

replace AREA_S="Medellin" if ustrregexm(AREA_S1, "05")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "08")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "11")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "13")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "15")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "17")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "18")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "19")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "20")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "23")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "25")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "27")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "41")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "44")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "47")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "50")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "52")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "54")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "63")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "66")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "68")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "70")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "73")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "76")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Antioquia")
replace AREA_S="Medellin" if ustrregexm(AREA_S1, "Mede")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Atlántico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "ntico")
replace AREA_S="Barranquilla" if ustrregexm(AREA_S1, "Barranquilla")
replace AREA_S="Bogota, D.C." if ustrregexm(AREA_S1, "Bogot")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Bol")
replace AREA_S="Cartagena" if ustrregexm(AREA_S1, "Cartagena")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Boyac")
replace AREA_S="Tunja" if ustrregexm(AREA_S1, "Tunja")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Caldas")
replace AREA_S="Manizales" if ustrregexm(AREA_S1, "Manizales")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Florencia")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Cauca")
replace AREA_S="Popayan" if ustrregexm(AREA_S1, "Popay")
replace AREA_S="Florencia" if ustrregexm(AREA_S1, "Caquet")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Cesar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "Valledupar")
replace AREA_S="Valledupar" if ustrregexm(AREA_S1, "sar") & AREA_S1!="Risaralda"
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Choc")
replace AREA_S="Quibdo" if ustrregexm(AREA_S1, "Quibd")
replace AREA_S="Cundinamarca" if ustrregexm(AREA_S1, "Cundinamarca")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "rdoba")
replace AREA_S="Monteria" if ustrregexm(AREA_S1, "Monter")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "uajira")
replace AREA_S="Riohacha" if ustrregexm(AREA_S1, "Riohacha")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Huila")
replace AREA_S="Neiva" if ustrregexm(AREA_S1, "Neiva")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Magdalena")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "Santa Marta")
replace AREA_S="Santa Marta" if ustrregexm(AREA_S1, "arta") & AREA_S1!="Cartagena"
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Meta")
replace AREA_S="Villavicencio" if ustrregexm(AREA_S1, "Villavicencio")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Nari")
replace AREA_S="Pasto" if ustrregexm(AREA_S1, "Pasto")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "Norte")
replace AREA_S="Cucuta" if ustrregexm(AREA_S1, "cuta")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Quind")
replace AREA_S="Armenia" if ustrregexm(AREA_S1, "Armenia")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Risaralda")
replace AREA_S="Pereira" if ustrregexm(AREA_S1, "Pereira")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Santander")
replace AREA_S="Bucaramanga" if ustrregexm(AREA_S1, "Bucaramanga")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sucre")
replace AREA_S="Sincelejo" if ustrregexm(AREA_S1, "Sincelejo")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Tolima")
replace AREA_S="Ibague" if ustrregexm(AREA_S1, "Ibagu")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Valle del")
replace AREA_S="Cali" if ustrregexm(AREA_S1, "Cali")

gen AREA=""

replace AREA="05" if AREA_S=="Medellin"
replace AREA="08" if AREA_S=="Barranquilla"
replace AREA="11" if AREA_S=="Bogota, D.C."
replace AREA="13" if AREA_S=="Cartagena"
replace AREA="15" if AREA_S=="Tunja"
replace AREA="17" if AREA_S=="Manizales"
replace AREA="18" if AREA_S=="Florencia"
replace AREA="19" if AREA_S=="Popayan"
replace AREA="20" if AREA_S=="Valledupar"
replace AREA="27" if AREA_S=="Quibdo"
replace AREA="23" if AREA_S=="Monteria"
replace AREA="25" if AREA_S=="Cundinamarca"
replace AREA="41" if AREA_S=="Neiva"
replace AREA="44" if AREA_S=="Riohacha"
replace AREA="47" if AREA_S=="Santa Marta"
replace AREA="50" if AREA_S=="Villavicencio"
replace AREA="52" if AREA_S=="Pasto"
replace AREA="54" if AREA_S=="Cucuta"
replace AREA="63" if AREA_S=="Armenia"
replace AREA="66" if AREA_S=="Pereira"
replace AREA="68" if AREA_S=="Bucaramanga"
replace AREA="70" if AREA_S=="Sincelejo"
replace AREA="73" if AREA_S=="Ibague"
replace AREA="76" if AREA_S=="Cali"
replace AREA="81" if AREA_S=="Arauca"
replace AREA="85" if AREA_S=="Yopal"
replace AREA="86" if AREA_S=="Mocoa"
replace AREA="88" if AREA_S=="San Andres"
replace AREA="91" if AREA_S=="Leticia"
replace AREA="94" if AREA_S=="Inirida"
replace AREA="95" if AREA_S=="San Jose del Guaviare"
replace AREA="97" if AREA_S=="Mitu"
replace AREA="99" if AREA_S=="Puerto Carreno"


save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}

* Años 2007, 2017 2018 y 2019  (Para 2007 y 2017 se arreglarán los meses que faltaron del paso anterior)

local years "2017"
local meses "Septiembre Octubre Noviembre Diciembre"
local areas "Area Cabecera"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 


gen AREA_S=""

replace AREA_S="Medellin" if AREA=="05" 
replace AREA_S="Barranquilla" if AREA=="08" 
replace AREA_S="Bogota, D.C." if AREA=="11" 
replace AREA_S="Cartagena" if AREA=="13" 
replace AREA_S="Tunja" if AREA=="15" 
replace AREA_S="Manizales" if AREA=="17" 
replace AREA_S="Florencia" if AREA=="18" 
replace AREA_S="Popayan" if AREA=="19" 
replace AREA_S="Valledupar" if AREA=="20" 
replace AREA_S="Quibdo" if AREA=="27" 
replace AREA_S="Monteria" if AREA=="23" 
replace AREA_S="Cundinamarca" if AREA=="25" 
replace AREA_S="Neiva" if AREA=="41" 
replace AREA_S="Riohacha" if AREA=="44" 
replace AREA_S="Santa Marta" if AREA=="47" 
replace AREA_S="Villavicencio" if AREA=="50" 
replace AREA_S="Pasto" if AREA=="52" 
replace AREA_S="Cucuta" if AREA=="54" 
replace AREA_S="Armenia" if AREA=="63" 
replace AREA_S="Pereira" if AREA=="66" 
replace AREA_S="Bucaramanga" if AREA=="68" 
replace AREA_S="Sincelejo" if AREA=="70" 
replace AREA_S="Ibague" if AREA=="73" 
replace AREA_S="Cali" if AREA=="76" 
replace AREA_S="Arauca" if AREA=="81" 
replace AREA_S="Yopal" if AREA=="85" 
replace AREA_S="Mocoa" if AREA=="86" 
replace AREA_S="San Andres" if AREA=="88" 
replace AREA_S="Leticia" if AREA=="91" 
replace AREA_S="Inirida" if AREA=="94" 
replace AREA_S="San Jose del Guaviare" if AREA=="95" 
replace AREA_S="Mitu" if AREA=="97" 
replace AREA_S="Puerto Carreno" if AREA=="99" 



save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}



local years "2007 2018 2019 2020"
local meses  "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"
local areas "Area Cabecera"
local bases `" "Caracteristicas generales (Personas)" "Fuerza de trabajo" "Ocupados" "Desocupados" "Inactivos" "Vivienda y Hogares" "Otros ingresos" "Otras actividades y ayudas en la semana" "'

foreach y of local years {
foreach m of local meses {
foreach a of local areas {
foreach b of local bases {

cap{
use "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", clear 


gen AREA_S=""

replace AREA_S="Medellin" if AREA=="05" 
replace AREA_S="Barranquilla" if AREA=="08" 
replace AREA_S="Bogota, D.C." if AREA=="11" 
replace AREA_S="Cartagena" if AREA=="13" 
replace AREA_S="Tunja" if AREA=="15" 
replace AREA_S="Manizales" if AREA=="17" 
replace AREA_S="Florencia" if AREA=="18" 
replace AREA_S="Popayan" if AREA=="19" 
replace AREA_S="Valledupar" if AREA=="20" 
replace AREA_S="Quibdo" if AREA=="27" 
replace AREA_S="Monteria" if AREA=="23" 
replace AREA_S="Cundinamarca" if AREA=="25" 
replace AREA_S="Neiva" if AREA=="41" 
replace AREA_S="Riohacha" if AREA=="44" 
replace AREA_S="Santa Marta" if AREA=="47" 
replace AREA_S="Villavicencio" if AREA=="50" 
replace AREA_S="Pasto" if AREA=="52" 
replace AREA_S="Cucuta" if AREA=="54" 
replace AREA_S="Armenia" if AREA=="63" 
replace AREA_S="Pereira" if AREA=="66" 
replace AREA_S="Bucaramanga" if AREA=="68" 
replace AREA_S="Sincelejo" if AREA=="70" 
replace AREA_S="Ibague" if AREA=="73" 
replace AREA_S="Cali" if AREA=="76" 
replace AREA_S="Arauca" if AREA=="81" 
replace AREA_S="Yopal" if AREA=="85" 
replace AREA_S="Mocoa" if AREA=="86" 
replace AREA_S="San Andres" if AREA=="88" 
replace AREA_S="Leticia" if AREA=="91" 
replace AREA_S="Inirida" if AREA=="94" 
replace AREA_S="San Jose del Guaviare" if AREA=="95" 
replace AREA_S="Mitu" if AREA=="97" 
replace AREA_S="Puerto Carreno" if AREA=="99" 


save "$rawdata/GEIH/`y'/`m'/`a' - `b'.dta", replace 

}
}
}
}
}

********************************************************************************
* 	               Seccion 2 - Merge de bases especificas 		              *
********************************************************************************
	
* Bases de 2007 a 2008

local areas "Area Cabecera Resto"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forvalues i=2007/2020 {
foreach a of local areas {
foreach m of local meses {

use "$rawdata/GEIH/`i'/`m'/`a' - Caracteristicas generales (Personas).dta", clear   
 
merge m:1 DIRECTORIO SECUENCIA_P MES using "$rawdata/GEIH/`i'/`m'/`a' - Vivienda y Hogares.dta", gen(vivienda)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Fuerza de trabajo.dta", gen(workforce)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Ocupados.dta", gen(ocupados) 
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Desocupados.dta", gen(desocupados) 
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Inactivos.dta", gen(inactivos) 
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Otros ingresos.dta", gen(otros_ingresos)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Otras actividades y ayudas en la semana.dta", gen(otras_acti)  

local bases "vivienda workforce ocupados desocupados inactivos otros_ingresos otras_acti"

foreach b of local bases {

replace `b'=0 if `b'!=3 
replace `b'=1 if `b'==3

}

save "$data/GEIH/Bases mensuales `a' `m' `i'", replace 

}
} 
} 
 
 
* Bases de 2009 a 2020 


local areas "Area Cabecera Resto"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forvalues i=2009/2020 {
foreach a of local areas {
foreach m of local meses {

cap {

use "$rawdata/GEIH/`i'/`m'/`a' - Caracteristicas generales (Personas).dta", clear   
 
merge m:1 DIRECTORIO SECUENCIA_P HOGAR MES using "$rawdata/GEIH/`i'/`m'/`a' - Vivienda y Hogares.dta", gen(vivienda)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Fuerza de trabajo.dta", gen(workforce)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Ocupados.dta", gen(ocupados)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Desocupados.dta", gen(desocupados)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Inactivos.dta", gen(inactivos)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Otros ingresos.dta", gen(otros_ingresos)
merge 1:1 DIRECTORIO SECUENCIA_P HOGAR MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Otras actividades y ayudas en la semana.dta", gen(otras_acti)  

local bases "vivienda workforce ocupados desocupados inactivos otros_ingresos otras_acti"

foreach b of local bases {
cap {
replace `b'=0 if `b'!=3 
replace `b'=1 if `b'==3
}
}

save "$data/GEIH/Bases mensuales `a' `m' `i'", replace 

}
} 
} 
}



*  2020 (Marzo Abril)

local areas "Area Cabecera"
local meses "Marzo Abril"

forvalues i=2020/2020 {
foreach a of local areas {
foreach m of local meses {

use "$rawdata/GEIH/`i'/`m'/`a' - Caracteristicas generales (Personas).dta", clear   
 
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Fuerza de trabajo.dta", gen(workforce)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Ocupados.dta", gen(ocupados)

local bases "workforce ocupados"

foreach b of local bases {

replace `b'=0 if `b'!=3 
replace `b'=1 if `b'==3

}

save "$data/GEIH/Bases mensuales `a' `m' `i'", replace 

}
} 
} 


* 2020 (Mayo Junio Julio)

local areas "Area Cabecera"
local meses "Mayo Junio Julio"

forvalues i=2020/2020 {
foreach a of local areas {
foreach m of local meses {


use "$rawdata/GEIH/`i'/`m'/`a' - Caracteristicas generales (Personas).dta", clear   
 
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Fuerza de trabajo.dta", gen(workforce)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Ocupados.dta", gen(ocupados)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Desocupados.dta", gen(desocupados)
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$rawdata/GEIH/`i'/`m'/`a' - Inactivos.dta", gen(inactivos)

local bases "workforce ocupados desocupados inactivos"

foreach b of local bases {
cap {
replace `b'=0 if `b'!=3 
replace `b'=1 if `b'==3
}
}

save "$data/GEIH/Bases mensuales `a' `m' `i'", replace 

} 
} 
}




* Crear variable YEAR para todas las bases 

clear all 

local areas "Area Cabecera Resto"
local meses "Diciembre" //"Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forvalues y=2021/2021 {
foreach a of local areas {
foreach m of local meses {

use  "$data/GEIH/Bases mensuales `a' `m' `y'", clear 

cap gen YEAR=`y'

compress
 
save "$data/GEIH/Bases mensuales `a' `m' `y'", replace  

 
} 
} 
} 
 
  
* Arreglar la variable de factor de expansion para el 2011 


local areas "Area"
local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach a of local areas {
foreach m of local meses {
 
use  "$data/GEIH/Bases mensuales `a' `m' 2011", clear 

rename FEX_C_2011 FEX_C_2011_BAD
rename FEX_C FEX_C_2011 

save "$data/GEIH/Bases mensuales `a' `m' 2011", replace 

}
}

* Arreglar la variable de factor de expansion para 2016 y 2017 


local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forvalues y=2016/2017 {
foreach m of local meses {
 
use  "$data/GEIH/Bases mensuales Area `m' `y'", clear 

rename FEX_C_2011 FEX_C_2011_BAD
merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$data/GEIH/Bases mensuales Cabecera `m' `y'.dta", keepusing(FEX_C_2011) keep(3)

save "$data/GEIH/Bases mensuales Area `m' `y'", replace 

}
}



log close 
 
 
 
 

















