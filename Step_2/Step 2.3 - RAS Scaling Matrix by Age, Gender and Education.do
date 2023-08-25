********************************************************************************
********************************************************************************

*          Step 3.3 - RAS Scaling Matrix by Age, Gender and Education     	   *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	07/Jul/2021
				* Autor:		Nicolas Mancera 
				* Modificacion: 
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

	cd "${rawdata}"
	

	cap log close 
	
	log using "${logs}/Step 3.3 - RAS Scaling Matrix by Gender age and education.smcl", replace 

	cap mkdir "$data/Transiciones/RAS_Output/age_gender_education"
	
********************************************************************************
*                          Section 1 - Data		   			                   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

local temp = 1 

foreach g of local gender {



local years  "2021" //  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
tokenize "Enero Febrero" //  Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {


	
use "$data/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`temp'_`educ'.dta", clear 

egen suma_prior = sum(Total_`prior')
egen suma_after = sum(Total_`y')

gen diff = suma_prior - suma_after 

replace Total_`y'=0 if Total_`y'==. & Origen_Destino=="imi"
 
replace Total_`y'=Total_`y' + diff if Origen_Destino=="imi" & (diff>150 | diff <150)

drop suma_prior suma_after diff 

egen total_imi_origen = rowtotal(m i d e p of oc os on oj ot qpd) if Origen_Destino == "imi"
gen valor_distribucion = Total_`y'*(-1) if Total_`y'<0 & Total_`y'!=.

local variables "m i d e p of oc os on oj ot qpd"
foreach i of local variables  {
		replace `i'= `i' + ((`i'/total_imi_origen)*valor_distribucion) if `i'!=. & Total_`y'<0 & Total_`y'!=. & Origen_Destino == "imi"
}

***** Reemplazo de valores totales emigracion 

	replace Total_`prior'= Total_`prior' - Total_`y' if Total_`y'<0 & Total_`y'!=. & Origen_Destino == "imi" & Total_`prior'!=.

* Reemplazo del total y columna
	
	replace Total_`y' = . if Total_`y'<0 & Total_`y'!=. & Origen_Destino == "imi" & Total_`prior'!=.
	gen one = (Total_`y'==. & Origen_Destino == "imi")
	egen total_missing = max(one)
	
	replace emi = . if total_missing==1 

	
drop total_imi_origen valor_distribucion one total_missing
	

local variables "m i d e of oc os on oj ot qpd emi"
foreach i of local variables  {
		replace `i'=0 if `i'==.
}

replace Total_`y'=0 if Total_`y'==.

rename * Freq*

rename (FreqOrigen_Destino FreqTotal_`prior' FreqTotal_`y') (Origen Total_`prior' Total_`y')

preserve 

tempfile  Total_`y'
keep      Origen Total_`y'
rename    Origen Destino
replace   Destino="emi" if Destino=="imi"
save     `Total_`y''

restore 

drop    Total_`y'
reshape long Freq, i(Origen Total_`prior') j(Destino) string  
order   Origen Destino Freq
merge   m:1 Destino using `Total_`y''
drop   _merge 
drop    if Destino=="nac"

replace Freq=1 if Freq==0
replace Total_`prior' = 13 if Total_`prior' == 0 | Total_`prior' == .
replace Total_`y' = 13 if Total_`y' == 0 
replace Total_`prior'=round(Total_`prior')
replace Total_`y'=round(Total_`y')
format  Total_`prior' %12.0f
format  Total_`y' %12.0f

sort Origen Destino


********************************************************************************
*                   	 Section 2 - Seed values	   	                       *
********************************************************************************

/* Pasos 

1. Realizar procedimiento para las filas de desmepleo
2. Suma por Origenes de las celdas que no se van a imputar 
3. Realizar la diferencia entre el total real de la fila y el calculado en el paso anterior 
4. Calcular la suma de los totales de destino de las celdas a reemplazar
5. Construir el ponderador
		a_ij = output_step_2 * (total del destino j / output_step_3) 
6. Reemplazar los valores del ponderador en la matriz original
7. Generar identificador de valores ajustados 
8. Borrar variables inncesarias

*/

* 1. Reajuste de desempleo 

bys Origen: egen suma_desempleo = sum(Freq) if Origen == "d"
gen resta_desempleo = Total_`prior' - suma_desempleo

gen Freq3 = Freq + (resta_desempleo * (Freq / suma_desempleo))

replace Freq = Freq3 if Origen == "d" & Destino != "m"


* 2. Sumas Origenes

bys Origen: egen suma_temp = sum(Freq) if Freq != 1 
bys Origen: egen suma = max(suma_temp)

* 3. Diferencia Totales 

gen diff_total = Total_`prior' - suma

* 4. Suma de Totales

bys Origen: egen suma_tot_`y' = sum(Total_`y') if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m"

* 5. Ponderador 

gen Freq2 = diff_total*(Total_`y'/suma_tot) if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m" 

replace Freq2 = abs(Freq2)

* 6. Reemplazar Valores

replace Freq = Freq2 if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m" 

* 7. Identificador

gen identifier = (Freq2 != .)

replace Freq=round(Freq)

* 8. Drop variables   

drop Freq3 Freq2 suma_tot_`y' suma_desempleo suma_temp resta_desempleo 


replace Freq = 1 if Freq == . 
********************************************************************************
*     Section 9 - Matrix Scaling with constraints (Seed Values)                *
********************************************************************************
dis in red "`y' `prior'``mes''" 

cap drop result_constraint
cap drop row_tot col_tot

*seednicomstdize Freq Total_`prior' Total_`y' , by(Origen Destino)  tolerance(40)  generate(result_constraint)
dis in red "`y' `prior' ``mes'' `age' `age_plus'"
seednico2 Freq Total_`prior' Total_`y' , by(Origen Destino)  tolerance(100)  generate(result_constraint)

bys Origen: egen row_tot = sum(result_constraint)
bys Destino: egen col_tot = sum(result_constraint)

* Comparaciones 

format row_tot %12.0f
format col_tot %12.0f 


********************************************************************************
*     				     Section 10 - Descriptives 				   			   *
********************************************************************************

/*
gen diff_rate_`y' = ((abs(Total_`y'-col_tot))/Total_`y')
gen diff_rate_`prior' = ((abs(Total_`prior'-row_tot))/Total_`prior')


mat diff_rate = J(13, 2, .) 

mat colnames diff_rate = Total_`prior' Total_`y'
mat rownames diff_rate = nac m i d e of oc os on oj ot qpd emi 
 

local destino "m i d e of oc os on oj ot qpd emi"

local row = 1

foreach d of local destino {

dis "`d'"
sum diff_rate_`y' if Destino == "`d'"
mat diff_rate[`row' + 1, 2] = r(mean)

local row = `row' + 1

}

local origen "nac m i d e of oc os on oj ot qpd imi"

local row = 0 
foreach o of local origen {

dis "`o'"
sum diff_rate_`prior' if Origen == "`o'"
mat diff_rate[`row' + 1, 1] = r(mean)

local row = `row' + 1

}

preserve 

clear 

svmat2 diff_rate, names(col) rnames(Origen_Destino)

export excel using "$tables/Transiciones/Matriz de transiciones 08032021.xlsx", sheet("Difference Rate") firstrow(variables) sheetreplace

restore 
*/
********************************************************************************
*     				     Section 11 - Matrix Output      		   			   *
********************************************************************************

preserve 

keep Origen row_tot

duplicates drop Origen row_tot, force 

replace row_tot = round(row_tot)

tempfile origen 

save `origen'

restore 


preserve 

keep Destino col_tot

duplicates drop Destino col_tot, force 

replace col_tot = round(col_tot)

rename Destino Origen 

tempfile destino 

save `destino'

restore 


preserve 

keep Origen Destino result_constraint

replace result_constraint = round(result_constraint)

reshape wide result_constraint, i(Origen) j(Destino) string 

rename result_constraint* *

merge 1:1 Origen using "`origen'", nogen
merge 1:1 Origen using "`destino'", nogen 

list 

sum col_tot if Origen == "emi"

replace col_tot = r(mean) if Origen =="imi"

drop if Origen == "emi"

gen MES = `mes' 
gen YEAR = `y'

save "$data/Transiciones/RAS_Output/age_gender_education/transition_matrix_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", replace 


restore 



********************************************************************************
*     		Section 12 - Matrix Output (Transition Rates)    	   			   *
********************************************************************************

tab row_tot 

preserve 

replace result_constraint = 0 if row_tot == 12

gen lambda = result_constraint/row_tot

keep Origen Destino lambda 

reshape wide lambda, i(Origen) j(Destino) string 

rename lambda* * 

list 

gen MES = `mes' 
gen YEAR = `y'

save "$data/Transiciones/RAS_Output/age_gender_education/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", replace 

restore 

local prior = `prior' + 1


}
}



********************************************************************************
*																			   *
*																			   *
* 					Data Transition Rates Before RAS						   *
*																			   *
*																			   *
********************************************************************************


local years   "2021" // "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020" //  
tokenize "Enero Febrero" // Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {

use "$data/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`temp'_`educ'.dta", clear 

local variables "m i d e of oc os on oj ot qpd emi"
foreach i of local variables  {
		replace `i'=0 if `i'==.
}

replace Total_`y'=0 if Total_`y'==.

rename * Freq*

rename (FreqOrigen_Destino FreqTotal_`prior' FreqTotal_`y') (Origen Total_`prior' Total_`y')

preserve 

tempfile  Total_`y'
keep      Origen Total_`y'
rename    Origen Destino
replace   Destino="emi" if Destino=="imi"
save     `Total_`y''

restore 

drop    Total_`y'
reshape long Freq, i(Origen Total_`prior') j(Destino) string  
order   Origen Destino Freq
merge   m:1 Destino using `Total_`y''
drop   _merge 
drop    if Destino=="nac"

replace Freq=1 if Freq==0
replace Total_`prior' = 13 if Total_`prior' == 0 | Total_`prior' == .
replace Total_`y' = 13 if Total_`y' == 0 
replace Total_`prior'=round(Total_`prior')
replace Total_`y'=round(Total_`y')
format  Total_`prior' %12.0f
format  Total_`y' %12.0f

sort Origen Destino



********************************************************************************
*                   	 Section 2 - Seed values	   	                       *
********************************************************************************

* 1. Reajuste de desempleo 

bys Origen: egen suma_desempleo = sum(Freq) if Origen == "d"
gen resta_desempleo = Total_`prior' - suma_desempleo

gen Freq3 = Freq + (resta_desempleo * (Freq / suma_desempleo))

replace Freq = Freq3 if Origen == "d" & Destino != "m"


* 2. Sumas Origenes

bys Origen: egen suma_temp = sum(Freq) if Freq != 1 
bys Origen: egen suma = max(suma_temp)

* 3. Diferencia Totales 

gen diff_total = Total_`prior' - suma

* 4. Suma de Totales

bys Origen: egen suma_tot_`y' = sum(Total_`y') if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m"

* 5. Ponderador 

gen Freq2 = diff_total*(Total_`y'/suma_tot) if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m" 

replace Freq2 = abs(Freq2)

* 6. Reemplazar Valores

replace Freq = Freq2 if Freq == 1 & Origen != "nac" & Origen != "qpd" & Destino != "m" 

* 7. Identificador

gen identifier = (Freq2 != .)

replace Freq=round(Freq)

* 8. Drop variables   

drop Freq3 Freq2 suma_tot_`y' suma_desempleo suma_temp resta_desempleo 


gen lambda = Freq/Total_`prior'

keep Origen Destino lambda 

reshape wide lambda, i(Origen) j(Destino) string 

rename lambda* * 

gen MES = `mes' 
gen YEAR = `y'

save "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", replace 


local prior = `prior' + 1

 
}

}

local temp = `temp' + 1 

}

local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1

}

}

log close 
