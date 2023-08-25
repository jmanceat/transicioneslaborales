********************************************************************************
********************************************************************************

*                         Step 5 - Stylized Facts 					           *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	 07/Jul/2021
				* Autor:		 Nicolas Mancera 
				* Modificación:  
*/

********************************************************************************
*                          Section 0 - Preliminaries		                   *
********************************************************************************


	clear all
	set   more off
	
* Rutas de las bases de datos 

	global rawdata  "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data"
	global data 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Data"
	global graphs 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Graphs/Ejercicios_GEIH"
	global tables 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Tables/Ejercicios_GEIH"
	global logs     "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Log_files/Ejercicios_GEIH/Transiciones"

	cap mkdir "$data/Transiciones/stylized_facts_data"

	cd "$data/Transiciones/stylized_facts_data"
	
	cap log close 
	
	log using "${logs}/Step 5 - Stylized Facts.smcl", replace 
	
********************************************************************************
*						Section 1  - Data Organization						   *
********************************************************************************


/* Tareas */

/*

1. Variables dependientes: tasas de transicion (5X5=25) por grupo de edad (desde 20, o sea 5) y sexo (2), promedios trimestrales (~50 o algo así)  
    Es decir, para las 25 variables dependientes, por los 10 grupos de edad y sexo, tendremos paneles de unos 50 datos cada uno.
2. Vamos a correr la regresion tt=f(lpibq, q, t, dum_politicas, pandemia) con SUR para cada uno de los 10 grupos de edad y sexo 
    Donde tt es tasa de transicion
               lpibq es el log del pib trimestral en pesos constantes
               q es una dummy estacional por trimestre
               t es el número del trimestre (de a 1 a 60 o algo asi)
               dum_politicas es un vector de dummies para antes/despues de cada una de las poiliticas que tiene pintadas en el grafico, más antes y despues del 2014 (cambio edad pensiones)
               pandemia es una dummy con 1 para los periodos desde 2020.q3
3. Diferenciación de sectores: puede ser útil separar en tres el PIB: los verdes son actividades rurales, los amarillos son actividades intensivas en empleo informal, y el resto.

*/ 


********************** Quarterly Data (Transition Rates) ***********************


* Fix pandemic values 

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'.dta", force 


local prior = `prior' + 1

}

}

rename * *_before 
rename (Origen_before MES_before YEAR_before) (Origen MES YEAR)

tempfile temp 
save `temp'


clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/All/transition_rate_``mes''_`prior'_`y'.dta", force 

local prior = `prior' + 1

}

}

count 
merge 1:1 Origen MES YEAR using `temp', keep(3) nogen 


gen temp = "-"
egen time_string = concat(YEAR temp MES)
gen time = monthly(time_string, "YM")
format time %tm 

drop if time >= ym(2020, 3)

* Average Mean 

keep if Origen == "e" 
keep e e_before
gen diff = e_before - e 

sum diff, meanonly 
global average_diff = r(mean)

dis $average_diff 

* After RAS data 

clear all 

local years "2020"
tokenize "Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/5  {
	
	local prior = 2019
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'.dta", force 


local prior = `prior' + 1

}

}

local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'.dta", force 


local prior = `prior' + 1

}

}


gen temp = "-"
egen time_string = concat(YEAR temp MES)
gen time = monthly(time_string, "YM")
format time %tm 

keep if time >= ym(2020, 8)
keep if Origen == "e"
keep Origen time e 
sum e 
replace e = e - $average_diff
sum e 
list 
duplicates report Origen time e , force 

tempfile fix
save `fix'

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/All/transition_rate_``mes''_`prior'_`y'.dta", force 

local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/All/transition_rate_``mes''_`prior'_`y'.dta", force 

local prior = `prior' + 1

}

}


gen temp = "-"
egen time_string = concat(YEAR temp MES)
gen time = monthly(time_string, "YM")
format time %tm 
 
replace e=. if Origen == "e" & time >= ym(2020,3)

merge 1:1 Origen time using `fix',  update keep(1 4) nogen

global outcomes d e emi i m oc of oj on os ot p qpd

foreach var in $outcomes {
	
	replace `var'=. if (time>=ym(2020,3) & time<=ym(2020,7)) 
}

egen suma = rowtotal(d e emi m oc of oj on os ot p qpd) if time >= ym(2020, 8) & Origen == "e"
replace i = 1 - suma if time >= ym(2020, 8) & Origen == "e"


drop MES YEAR temp time_string suma 

order time Origen 

gen quarter = qofd(dofm(time))

format quarter %tq

collapse (mean) d e i oc p, by(Origen quarter)

keep if Origen == "d" | Origen == "e" | Origen == "i" | Origen == "oc" | Origen == "p" 

save "quarter_transition_rates.dta", replace 

preserve 

	import excel "${rawdata}/pib_trimestral_2005_2020.xlsx", sheet("Hoja2") firstrow clear
	gen time = Periodo
	replace time = ustrregexrf(time, "IV",  "4")
	replace time = ustrregexrf(time, "III", "3")
	replace time = ustrregexrf(time, "II",  "2")
	replace time = ustrregexrf(time, "I",   "1")
	
	gen quarter = quarterly(time, "YQ")
	format quarter %tq
	
	drop time Periodo
	rename Productointernobruto pib
	
	save "quarterly_pib_data.dta", replace 
	
restore 

use "quarter_transition_rates.dta", clear 

merge m:1 quarter using "quarterly_pib_data.dta", keep(3) nogen keepusing(pib)

gen lpibq = ln(pib)

* Politicas publicas 

gen primer_empleo = (quarter >= yq(2011,1))
gen cesante       = (quarter >= yq(2013,2))
gen salud_unific  = (quarter >= yq(2012,3))
gen licencias     = (quarter >= yq(2017,1))
gen pensiones     = (quarter >= yq(2014,1))

* Pandemia

gen pandemia = (quarter >= yq(2020,1))
gen pandemia_2020_q3 =(quarter == yq(2020,3))
gen pandemia_2020_q4 =(quarter == yq(2020,4))

* Dummies estacionales 

rename quarter year_quarter 
gen quarter = quarter(dofq(year_quarter))

* Numero del periodo 

bys Origen: gen quarter_number = _n


save "main_transition_regression_data.dta", replace

********************************************************************************
*						 Section 2  - Regressions                              *							
********************************************************************************

use "main_transition_regression_data.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

estimates clear 	  
	
* Origen Desempleo

reg d  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "d"
est store eq1
reg e  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "d"
est store eq2
reg i  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "d"
est store eq3
reg oc lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "d"
est store eq4
reg p  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Empleo Asalariado 

estimates clear 

reg d  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "e"
est store eq6
reg e  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "e"
est store eq7
reg i  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "e"
est store eq8
reg oc lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "e"
est store eq9
reg p  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "e"
est store eq10

eststo: suest eq6 eq7 eq8 eq9 eq10


* Origen Inactividad 

estimates clear 

reg d  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "i"
est store eq11
reg e  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "i"
est store eq12
reg i  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "i"
est store eq13
reg oc lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "i"
est store eq14
reg p  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "i"
est store eq15

eststo: suest eq11 eq12 eq13 eq14 eq15

* Origen Cuenta Propia  

estimates clear

reg d  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "oc"
est store eq16
reg e  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "oc"
est store eq17
reg i  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "oc"
est store eq18
reg oc lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "oc"
est store eq19
reg p  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "oc"
est store eq20

eststo: suest eq16 eq17 eq18 eq19 eq20

* Origen Patrones  

estimates clear 

reg d  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "p"
est store eq21
reg e  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "p"
est store eq22
reg i  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "p"
est store eq23
reg oc lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "p"
est store eq24
reg p  lpibq i.quarter quarter_number primer_empleo cesante salud_unific licencias pensiones pandemia if Origen == "p"
est store eq25


eststo: suest eq21 eq22 eq23 eq24 eq25 




reg f_f_lt bartik_ct_p
est store eq1
reg f_i_lt bartik_ct_p
est store eq2
reg f_s_lt bartik_ct_p
est store eq3
reg f_o_lt bartik_ct_p
est store eq10

reg i_f_lt bartik_ct_p
est store eq4
reg i_i_lt bartik_ct_p
est store eq5
reg i_s_lt bartik_ct_p
est store eq6
reg i_o_lt bartik_ct_p
est store eq11


reg s_f_lt bartik_ct_p
est store eq7
reg s_i_lt bartik_ct_p
est store eq8
reg s_s_lt bartik_ct_p
est store eq9
reg s_o_lt bartik_ct_p
est store eq12
	 
eststo: suest eq1 eq2 eq3 eq4 eq5 eq6 eq7 eq8 eq9 eq10 eq11 eq12 
 
*log close 






