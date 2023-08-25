********************************************************************************
********************************************************************************

*                Step 5.1 - Stylized Facts Secondary Regression		           *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	 07/Jul/2021
				* Autor:		 Nicolas Mancera 
				* Modificación:  13/Jul/2021
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
	
	log using "${logs}/Step 5.1 - Stylized Facts Secondary Regression.smcl", replace 
	
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


local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {


clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/age_gender_education/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

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
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 


local prior = `prior' + 1

}

}

local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/age_gender_education/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/age_gender_education/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

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

gen educ = "`educ'"
gen gender = "`g'"
gen age = "`age'_`age_plus'"

save "quarter_transition_rates_`age'_`age_plus'_`g'_`educ'.dta", replace 


}


local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1

}


}

clear all 


local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

append using  "quarter_transition_rates_`age'_`age_plus'_`g'_`educ'.dta"  


}

local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1

}

}

compress 

save "quarterly_transition_rates_panel_age_gender_educ.dta", replace 

* Datos Originales Dane 

/*
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
*/

* Datos Originales Dane desestacionalizados 

preserve 

	import excel "${rawdata}/pib_trimestral_2005_2020_desestacionalizado.xlsx", sheet("Hoja2") firstrow clear
	gen time = Periodo
	replace time = ustrregexrf(time, "IV",  "4")
	replace time = ustrregexrf(time, "III", "3")
	replace time = ustrregexrf(time, "II",  "2")
	replace time = ustrregexrf(time, "I",   "1")
	
	gen quarter = quarterly(time, "YQ")
	format quarter %tq
	
	drop time Periodo
	rename Productointernobruto pib
	
	keep if quarter <= yq(2019, 4)
	keep pib quarter 
	
	sort quarter 
	gen quarter_number = _n
	
	tsset quarter_number
	
	gen lpibq = ln(pib)
	gen diff_lpibq = lpibq - L4.lpibq
	
	arima diff_lpibq, noconstant arima(3,0,0)
	predict diff_lpibq_hat, dynamic(tq(2019, 4))
		
	set obs `=_N+4'
	replace quarter_number = _n 
	
	arima diff_lpibq, noconstant arima(3,0,0)
	predict diff_lpibq_hat_1, dynamic(tq(2019, 4))
	
	replace quarter = tq(2020, 1) if quarter_number == 61
	replace quarter = tq(2020, 2) if quarter_number == 62
	replace quarter = tq(2020, 3) if quarter_number == 63
	replace quarter = tq(2020, 4) if quarter_number == 64
	
	drop diff_lpibq
	rename diff_lpibq_hat_1 diff_lpibq
	keep quarter diff_lpibq
	
	save "quarterly_pib_data_seasonally_adj.dta", replace 
	
restore 

use "quarterly_transition_rates_panel_age_gender_educ.dta", clear 

merge m:1 quarter using "quarterly_pib_data_seasonally_adj.dta", keep(3) nogen keepusing(diff_lpibq)

* Politicas publicas 

gen primer_empleo = (quarter >= yq(2011,1))
*gen cesante       = (quarter >= yq(2013,2))
gen parafiscales  = (quarter >= yq(2013,2))
*gen salud_unific  = (quarter >= yq(2012,3))
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

sort  Origen educ gender age year_quarter

bys Origen educ gender age: gen quarter_number = _n 


* Categorias 

gen female = (gender == "women")
gen edu_superior = (educ == "con")
gen age_20_29 = (age == "20_29")
gen age_30_39 = (age == "30_39")
gen age_40_49 = (age == "40_49")
gen age_50_59 = (age == "50_59")
gen age_60_69 = (age == "60_69")

save "main_transition_regression_data_age_gender_educ.dta", replace

********************************************************************************
*				  Section 2  - Regressions Women                              *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_50_59 

keep if female == 1 

* Promedios transiciones  

mat women = J(5, 5, .)
mat colnames women = d e i oc p 
mat rownames women = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat women[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat women[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat women[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat women[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat women[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}

estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_women_20210805.txt" , se sca(N r2) varwidth(50) replace 

********************************************************************************
*				     Section 3  - Regressions Men                              *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_50_59 

keep if female == 0 

* Promedios transiciones  

mat men = J(5, 5, .)
mat colnames men = d e i oc p 
mat rownames men = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat men[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat men[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat men[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat men[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat men[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}

estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_men_20210805.txt" , se sca(N r2) varwidth(50) replace 

********************************************************************************
*				  Section 4  - Regressions Women Con                           *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_50_59 

keep if female == 1 & edu_superior == 1 

* Promedios transiciones  

mat women_con = J(5, 5, .)
mat colnames women_con = d e i oc p 
mat rownames women_con = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat women_con[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat women_con[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat women_con[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat women_con[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat women_con[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}

estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_women_con_20210805.txt" , se sca(N r2) varwidth(50) replace 



********************************************************************************
*				    Section 5  - Regressions Women Sin                         *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_50_59 

keep if female == 1 & edu_superior == 0

* Promedios transiciones  

mat women_sin = J(5, 5, .)
mat colnames women_sin = d e i oc p 
mat rownames women_sin = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat women_sin[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat women_sin[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat women_sin[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat women_sin[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat women_sin[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}

estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_women_sin_20210805.txt" , se sca(N r2) varwidth(50) replace 


********************************************************************************
*						 Section 6  - Regressions Men Con                      *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_60_69 

keep if female == 0 & edu_superior == 1

* Promedios transiciones  

mat men_con = J(5, 5, .)
mat colnames men_con = d e i oc p 
mat rownames men_con = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat men_con[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat men_con[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat men_con[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat men_con[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat men_con[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}


estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_men_con_20210805.txt" , se sca(N r2) varwidth(50) replace 

********************************************************************************
*						 Section 7  - Regressions Men Sin                      *							
********************************************************************************

use "main_transition_regression_data_age_gender_educ.dta", clear 

*tt=f(lpibq, q, t, dum_politicas, pandemia)

global main  diff_lpibq i.quarter quarter_number pandemia_2020_q3 pandemia_2020_q4 
global politicas primer_empleo parafiscales licencias pensiones
global grupos edu_superior  age_30_39 age_40_49 age_50_59 age_60_69
global interacciones licencias##age_20_29  licencias##age_30_39 primer_empleo##age_20_29 pensiones##age_60_69 

keep if female == 0 & edu_superior == 0

* Promedios transiciones  

mat men_sin = J(5, 5, .)
mat colnames men_sin = d e i oc p 
mat rownames men_sin = d e i oc p 

local origen "d e i oc p"

local row = 0 
foreach x of local origen {
preserve 

	summ d if Origen == "`x'", meanonly 
		mat men_sin[`row'+1, 1] = r(mean) 
	summ e if Origen == "`x'", meanonly
		mat men_sin[`row'+1, 2] = r(mean) 
	summ i if Origen == "`x'", meanonly 
		mat men_sin[`row'+1, 3] = r(mean) 	
	summ oc if Origen == "`x'", meanonly
		mat men_sin[`row'+1, 4] = r(mean) 
	summ p if Origen == "`x'", meanonly
		mat men_sin[`row'+1, 5] = r(mean) 

restore 
local row = `row' + 1 
}

mat list men_sin

estimates clear
	
* Origen Desempleo

reg d  $main $politicas $grupos $interacciones  if Origen == "d"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "d"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "d"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "d"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "d"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5



* Origen Empleo Asalariado 


reg d  $main $politicas $grupos $interacciones if Origen == "e"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "e"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "e"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "e"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "e"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5


* Origen Inactividad 


reg d  $main $politicas $grupos $interacciones if Origen == "i"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "i"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "i"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "i"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "i"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Cuenta Propia  


reg d  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "oc"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "oc"
est store eq5

eststo: suest eq1 eq2 eq3 eq4 eq5

* Origen Patrones  


reg d  $main $politicas $grupos $interacciones if Origen == "p"
est store eq1
reg e  $main $politicas $grupos $interacciones if Origen == "p"
est store eq2
reg i  $main $politicas $grupos $interacciones if Origen == "p"
est store eq3
reg oc $main $politicas $grupos $interacciones if Origen == "p"
est store eq4
reg p  $main $politicas $grupos $interacciones if Origen == "p"
est store eq5


eststo: suest eq1 eq2 eq3 eq4 eq5


esttab est1 est2 est3 est4 est5 using "${tables}/Transiciones/transition_estimates_men_sin_20210805.txt" , se sca(N r2) varwidth(50) replace 


estout matrix(women, fmt(4)) using     "${tables}/Transiciones/transition_average_women_20210817.txt", replace 
estout matrix(men, fmt(4)) using       "${tables}/Transiciones/transition_average_men_20210817.txt", replace 
estout matrix(women_con, fmt(4)) using "${tables}/Transiciones/transition_average_women_con_20210817.txt", replace 
estout matrix(women_sin, fmt(4)) using "${tables}/Transiciones/transition_average_women_sin_20210817.txt", replace 
estout matrix(men_con, fmt(4)) using   "${tables}/Transiciones/transition_average_men_con_20210817.txt", replace 
estout matrix(men_sin, fmt(4)) using   "${tables}/Transiciones/transition_average_men_sin_20210817.txt", replace 



log close 






