********************************************************************************
********************************************************************************

*   Step 2.3 - Matriz de Transiciones GEIH by age , gender, sin educ superior  *

********************************************************************************
********************************************************************************

/*
				* Creación: 	 05/Oct/2020
				* Autor:		 Nicolas Mancera 
				* Modificación:  2/Jun/2021
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
	
	log using "${logs}/Step 2.3 - Matriz de Transiciones GEIH by age_gender_sineduc.smcl", replace 
	
	

********************************************************************************
*                       Section 1 - Vitales Data	   		                   *
********************************************************************************

* Nota: Data para 2020 y 2021 porque no estan disponibles estos datos en el Dane aún

******************************** Nacimientos ***********************************

* Calcular tasa de crecimiento de la poblacion 

use "${rawdata}/Vitales/nac2019.dta", clear 

* Generar data en formato date (Montly Data)

* Nota: El numero de nacimientos preliminar en 2020 fue de 619504 y en 2019 fue de 642660
*       lo que significa que la tasa de nacimientos fue de -.03603149


*** 2020 


forvalues mes=1/12 {
	
preserve 
keep if mes==`mes'	
count 

local num = r(N)
clear all 
local obs = round(`num'*(1-0.03603149))
set obs `obs'
gen one=1
gen mes=`mes'
gen ANO=2020
tempfile `mes'

save ``mes''
	
restore 

}

clear 

forvalues mes=1/12 {
	
	append using ``mes'', force
}

save "${rawdata}/Vitales/nac2020.dta", replace // Esta base es temporal mientras el Dane publica los resultados de 2020


*** 2021 

use "${rawdata}/Vitales/nac2020.dta", clear 


forvalues mes=1/3 {
	
preserve 

keep if mes==`mes'	
count 

local num = r(N)
clear  
local obs = round(`num'*(1-0.11898917))
set obs `obs'
gen one=1
gen mes=`mes'
gen ANO=2021
tempfile `mes'

save ``mes''
	
restore 

}


clear 

forvalues mes=1/3 {
	
	append using ``mes'', force
}


save "${rawdata}/Vitales/nac2021.dta", replace // Esta base es temporal mientras el Dane publica los resultados de 2021



******************************** Fallecidos ***********************************

* Nota: Numero de defunciones no fetales en el 2020: 296800
* 		Las tasas que resultan de este proceso se incluyen luego en la construcción 
*		especifica de esos rubros en la linea 641 

* Tasas 

* 2020

use "${rawdata}/Vitales/nofetal2019", clear 

count 
local num=r(N) // Numero de fallecidos en el 2019: 244.355
global tasa2020=(296800-`num')/`num'
 

* 2021

* Nota: Numero de defunciones no fetales en enero de 2021: 34493
* 		Numero de defunciones no fetales en enero de 2019: 21354

use "${rawdata}/Vitales/nofetal2019", clear 
keep if mes==1
count 
local nu=r(N)
global tasa2021=(34493 - `nu')/ `nu'

********************************************************************************
*                          Section 2 - Data		   			                   *
********************************************************************************


local gender "1 2" 

foreach g of local gender {


local ages "10 20 30 40 50 60"

local gru_edu = 10 
local gru_edu2 = 11

foreach age of local ages {


local age_plus = `age' + 9



local years    "2021"  // "2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero" // Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"


forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

	
	dis `prior' `y'
	
use "$data/GEIH/Bases mensuales Cabecera ``mes'' `y'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `y'", force gen(resto) 

 dis `prior' `y'
 
 
keep if P6020 ==  `g'

keep if P6040 >= `age' & P6040 < `age_plus'

egen total_poblacion = sum(FEX_C_2011)

sum total_poblacion

mat poblacion_total = r(mean)

drop total_poblacion

********************************************************************************
*                       Section 2 - Migration Data    		                   *
********************************************************************************

* Inmigration 

dis `prior' `y'

forvalues s=`y'/`y' {

merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$data/GEIH/Migracion/Bases mensuales migracion ``mes'' `y'.dta", gen(migracion) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

replace migracion=0 if migracion!=3 
replace migracion=1 if migracion==3

}


dis `prior' `y'

********************************************************************************
*                          Section 3 - Variables    		                   *
********************************************************************************

gen fex_entero=round(FEX_C_2011)

*************************** Definicion de destinos *****************************

* Nota: la letra "y" en el nombre de las variables denota destino 
 
*** Menores de la edad de trabajar (m)

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

*** Inactivos (i)

gen i_y = inactivos

*** Desempleado (d)

gen d_y = desocupado

*** Empleado Regular o Patrones (e)

gen e_y=(ocupados==1&(P6430==1|P6430==2))

*** Empleador (p)

gen p_y=(ocupados==1&P6430==5)

*** Empleado en empresa de menos de 5 trabajadores (e0)

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1))

*** Empleado en empresa de mas de 5 trabajadores (e5)

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

*** Otro empleo (o)

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

*** Trabajador familiar (of)

gen of_y=(ocupados==1&P6430==6)

*** Cuenta propia (oc)

gen oc_y=(ocupados==1&P6430==4)

*** Empleado domestico (os)

gen os_y=(ocupados==1&P6430==3)

*** Trabajador sin remuneracion (on)

gen on_y=(ocupados==1&P6430==7)

*** Jornalero o peon (oj)

gen oj_y=(ocupados==1&P6430==8)

*** Otro (ot)

gen ot_y=(ocupados==1&P6430==9)

dis `prior' `y'
*************************** Definicion de origenes *****************************

* Nota: la letra "x" en el nombre de las variables denota origen 

*** Menores de la edad de trabajar (m)

gen m_x = ((P6040>=0&P6040<11&resto==1)|(P6040>=0&P6040<13&resto==0))

*** Desempleado (d)

gen d_x_1 = (P7430==1&P7440>2&P7440!=.&P7456==2)  // Definicion de los inactivos 
gen d_x_2 = (P7430==2&P7456==2) 				  // Definicion de los inactivos que no trabajaron antes
gen d_x_3 = (P7310==2&P7320>=52&P7250>=52) 		  // Definicion de los desocupados cesantes
gen d_x_4 = (P7310==1&P7250>=52) 				  // Definicion de los desocupados aspirantes
gen d_x_5 = (P6426<=12&P7020==1&P760>12&P760<=24) // Definicion de los ocupados 

egen d_x = rowmax(d_x_1 d_x_2 d_x_3 d_x_4 d_x_5)

*** Empleado Regular o Patrones (e)

gen e_x_1 = (P7430==1&(P7440==1|P7440==2))					   // Definicion de inactivos 
gen e_x_2 = (P7320>52&P7320<=104&(P7350==1|P7350==2)) 		   // Definicion de desocupados
gen e_x_3 = (P6426<=12&(P7028==1|P7028==2)&P760<4)             // Definicion de ocupados que cambiaron de empresa
gen e_x_4 = (P6426>12&(P6430==1|P6430==2))	    	           // Definicion de ocupados que no cambiaron de empresa 

egen e_x = rowmax(e_x_1 e_x_2 e_x_3 e_x_4)

*** Patrones (p)

gen p_x_1 = (P7320>52&P7320<=104&(P7350==5))     	 // Definicion de desocupados
gen p_x_2 = (P6426<=12&P7028==5&P760<4)    		     // Definicion de ocupados que cambiaron de empresa
gen p_x_3 = (P6426>12&P6430==5)	    	             // Definicion de ocupados que no cambiaron de empresa 

egen p_x = rowmax(p_x_1 p_x_2 p_x_3)

*** Otro empleo (o)

gen o_x_1 = (P7320>52&P7320<=104&(P7350!=1&P7350!=2&P7350!=5)) // Definicion de los desocupados 
gen o_x_2 = (P6426<=12&(P7028!=1&P7028!=2&P7028!=5)&P760<4)    // Definicion de los ocupados 
gen o_x_3 = (P6426>=24&P6430!=1&P6430!=2&P6430!=3)             // Ocupados que no cambiaron de trabajo 

egen o_x = rowmax(o_x_1 o_x_2 o_x_3)

*** Trabajador familiar (of)

gen of_x_1 = (P7320>52&P7320<=104&(P7350==6))   // Definicion de los desocupados 
gen of_x_2 = (P6426<=12&P7028==6&P760<4)  		// Definicion de los ocupados
gen of_x_3 = (P6426>=24&P6430==6) 			    // Ocupados que no cambiaron de trabajo 

egen of_x = rowmax(of_x_1 of_x_2 of_x_3) 

*** Cuenta propia (oc)

gen oc_x_1 = (P7320>52&P7320<=104&(P7350==4))	// Definicion de los desocupados 
gen oc_x_2 = (P6426<=12&P7028==4&P760<4)		// Definicion de los ocupados 
gen oc_x_3 = (P6426>=24&P6430==4) 				// Ocupados que no cambiaron de trabajo 

egen oc_x = rowmax(oc_x_1 oc_x_2 oc_x_3)

*** Empleado domestico (os)

gen os_x_1 = (P7320>52&P7320<=104&(P7350==3))	// Definicion de los desocupados
gen os_x_2 = (P6426<=12&P7028==3&P760<4)		// Definicion de los ocupados
gen os_x_3 = (P6426>=24&P6430==3)			    // Ocupados que no cambiaron de trabajo 

egen os_x = rowmax(os_x_1 os_x_2 os_x_3)

*** Trabajador sin remuneracion (on)

gen on_x_1 = (P7320>52&P7320<=104&(P7350==7))   // Definicion de los desocupados 
gen on_x_2 = (P6426<=12&P7028==7&P760<4)  		// Definicion de los ocupados
gen on_x_3 = (P6426>=24&P6430==7) 			    // Ocupados que no cambiaron de trabajo 

egen on_x = rowmax(on_x_1 on_x_2 on_x_3) 

*** Jornalero o peon (oj)

gen oj_x_1 = (P7320>52&P7320<=104&(P7350==8))   // Definicion de los desocupados 
gen oj_x_2 = (P6426<=12&P7028==8&P760<4)  		// Definicion de los ocupados
gen oj_x_3 = (P6426>=24&P6430==8) 			    // Ocupados que no cambiaron de trabajo 

egen oj_x = rowmax(oj_x_1 oj_x_2 oj_x_3) 

*** Otro (ot)

gen ot_x_1 = (P7320>52&P7320<=104&(P7350==9))   // Definicion de los desocupados 
gen ot_x_2 = (P6426<=12&P7028==9&P760<4)  		// Definicion de los ocupados
gen ot_x_3 = (P6426>=24&P6430==9) 			    // Ocupados que no cambiaron de trabajo 

egen ot_x = rowmax(ot_x_1 ot_x_2 ot_x_3) 

*** Inactivos (i)

gen i_x_2 = (P7310==2&P7320>52&P7250<=52)                      // Definicion de los desocupados cesantes
gen i_x_3 = (P7310==1&P7250<=52) 							   // Definicion de los desocupados aspirantes 
gen i_x_4 = (P6426<=12&P7020==2)	 						   // Definicion de los ocupados  
gen i_x_5 = (P6426<=12&P7020==1&P760>24)					   // Definicion de los ocupados    
gen i_x_1 = (P7440==3|P7440==4|P7440==9)					   // Definicion de los inactivos  

egen i_x = rowmax(i_x_1 i_x_2 i_x_3 i_x_4 i_x_5)  			   // i_o_3

*** Migracion (r) (r por reallocation)

gen r_x = (migracion==1&P753S3!=.)

dis `prior' `y'
********************************************************************************
*                          Section 4 - Transitions    		                   *
********************************************************************************


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen m_`v'=(m_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen i_`v'=(i_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen d_`v'=(d_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen e_`v'=(e_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen p_`v'=(p_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen o_`v'=(o_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen of_`v'=(of_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oc_`v'=(oc_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen os_`v'=(os_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen on_`v'=(on_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oj_`v'=(oj_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen ot_`v'=(ot_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen r_`v'=(r_x==1&`v'_y==1)

}

dis `prior' `y'

********************************************************************************
*                      Section 5 - Matrix to save outcomes                     *
********************************************************************************


mat ``mes''_`prior'_`y' = J(14, 13, .)

mat list ``mes''_`prior'_`y'


mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)
  
 
********************************************************************************
*                          Section 6 - Tabulates     		                   *
********************************************************************************

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab m_`v' [fw=fex_entero], matcell(result)

replace `v' = result[2, 1] if Origen_Destino == "m"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab  i_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "i"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab d_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "d"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab e_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "e"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab p_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "p"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab of_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "of" 

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oc_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oc"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab os_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "os"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab on_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "on"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oj_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oj"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab ot_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "ot"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab r_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "imi"

}



********************************************************************************
*                          Section 7 - Death Rate     		                   *
********************************************************************************

						

if `y'==2020{

preserve 

	noisily use "$rawdata/Vitales/nofetal2018.dta", clear
	append using "$rawdata/Vitales/nofetal2019.dta", force 

	keep if (YEAR==2018 & mes>`mes') | (YEAR==2019 & mes<=`mes')

	keep if (GRU_ED1 == "`gru_edu'" | GRU_ED1 == "`gru_edu2'")
	
	mat fallecidos = J(1, 1, .)

	count 

	mat fallecidos[1, 1]= r(N)*(1+$tasa2020)

	gen   menores =(GRU_ED2=="01"|GRU_ED2=="02"|GRU_ED2=="03")   // No se dejan los mayores

	gen   inactivos  =(OCUPACION=="PENSIONADO"|OCUPACION=="ESTUDIANTE"|OCUPACION=="AMA DE CASA")        

	gen   ocupados =(menores==0&inactivos==0)           

	gen totales = poblacion_total[1, 1]

	sum totales, meanonly
	local totales=r(mean)
	
	egen  T_menores = sum(menores)
	sum   T_menores, meanonly
	local minors=r(mean)
	
	egen  T_inactivos = sum(inactivos)
	sum   T_inactivos, meanonly
	local outoflabor=r(mean)
	
	egen  T_ocupados = sum(ocupados) 
	sum   T_ocupados, meanonly
	local occupied=r(mean)
	
	gen t_menores = `minors'/`totales'
	gen t_inactivos = `outoflabor'/`totales'
	gen t_ocupados = `outoflabor'/`totales'

	sum t_menores t_inactivos t_ocupados

	mat tasas_qpd = J(1, 3, .)

	sum t_menores, meanonly 
	mat tasas_qpd[1, 1]=r(mean)

	sum t_ocupados, meanonly
	mat tasas_qpd[1, 2]=r(mean)

	sum t_inactivos, meanonly
	mat tasas_qpd[1, 3]=r(mean)

	drop T_menores T_inactivos T_ocupados


restore 

}
else if `y'==2021{

preserve 

	noisily use "$rawdata/Vitales/nofetal2018.dta", clear
	append using "$rawdata/Vitales/nofetal2019.dta", force 

	keep if (YEAR==2018 & mes>`mes') | (YEAR==2019 & mes<=`mes')

	keep if (GRU_ED1 == "`gru_edu'" | GRU_ED1 == "`gru_edu2'")

	mat fallecidos = J(1, 1, .)

	count 

	mat fallecidos[1, 1]= r(N)*(1+$tasa2021)

	gen   menores =(GRU_ED2=="01"|GRU_ED2=="02"|GRU_ED2=="03")   // No se dejan los mayores

	gen   inactivos  =(OCUPACION=="PENSIONADO"|OCUPACION=="ESTUDIANTE"|OCUPACION=="AMA DE CASA")        

	gen   ocupados =(menores==0&inactivos==0)           

	gen totales = poblacion_total[1, 1]

	sum totales, meanonly
	local totales=r(mean)
	
	egen  T_menores = sum(menores)
	sum   T_menores, meanonly
	local minors=r(mean)
	
	egen  T_inactivos = sum(inactivos)
	sum   T_inactivos, meanonly
	local outoflabor=r(mean)
	
	egen  T_ocupados = sum(ocupados) 
	sum   T_ocupados, meanonly
	local occupied=r(mean)
	
	gen t_menores = `minors'/`totales'
	gen t_inactivos = `outoflabor'/`totales'
	gen t_ocupados = `occupied'/`totales'

	sum t_menores t_inactivos t_ocupados

	mat tasas_qpd = J(1, 3, .)

	sum t_menores, meanonly 
	mat tasas_qpd[1, 1]=r(mean)

	sum t_ocupados, meanonly
	mat tasas_qpd[1, 2]=r(mean)

	sum t_inactivos, meanonly
	mat tasas_qpd[1, 3]=r(mean)

	drop T_menores T_inactivos T_ocupados


restore 

}
else{
	
preserve 

	noisily use "$rawdata/Vitales/nofetal`prior'.dta", clear

	append using "$rawdata/Vitales/nofetal`y'.dta", force 

	keep if (YEAR==`prior' & mes>`mes') | (YEAR==`y' & mes<=`mes')

	keep if (GRU_ED1 == "`gru_edu'" | GRU_ED1 == "`gru_edu2'")

	mat fallecidos = J(1, 1, .)

	count 

	mat fallecidos[1, 1]= r(N)

	gen   menores =(GRU_ED2=="01"|GRU_ED2=="02"|GRU_ED2=="03")   // No se dejan los mayores

	gen   inactivos  =(OCUPACION=="PENSIONADO"|OCUPACION=="ESTUDIANTE"|OCUPACION=="AMA DE CASA")        

	gen   ocupados =(menores==0&inactivos==0)           

	gen totales = poblacion_total[1, 1]

	egen T_menores = sum(menores)
	egen T_inactivos = sum(inactivos)
	egen T_ocupados = sum(ocupados) 

	gen t_menores = T_menores/totales
	gen t_inactivos = T_inactivos/totales
	gen t_ocupados = T_ocupados/totales 

	sum t_menores t_inactivos t_ocupados

	mat tasas_qpd = J(1, 3, .)

	sum t_menores, meanonly 
	mat tasas_qpd[1, 1]=r(mean)

	sum t_ocupados, meanonly
	mat tasas_qpd[1, 2]=r(mean)

	sum t_inactivos, meanonly
	mat tasas_qpd[1, 3]=r(mean)

	drop T_menores T_inactivos T_ocupados


restore 

}

********************************************************************************
*                         	 Section 8 - Births     		                   *
********************************************************************************

preserve 

						
use "$rawdata/Vitales/nac`prior'.dta", clear

append using "$rawdata/Vitales/nac`y'.dta", force 


keep if (ANO==`prior' & mes>`mes') | (ANO==`y' & mes<=`mes')

mat nacimientos = J(1, 1, .)


restore 

replace m = nacimientos[1, 1] if Origen_Destino == "nac"


********************************************************************************
*                    Section 9 - Row and Column Totals     		               *
********************************************************************************


gen Total_`y' = . 


******************************* 2018 Totals ************************************

*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "e"

*** Patrones (p)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "p"


*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "ot"

*** Fallecidos (qpd)

replace Total_`y' = fallecidos[1, 1] if Origen_Destino == "qpd"

*** Migrantes (r)

mat migrantes = J(1, 1, .)

tab r_x [fw=fex_entero], matcell(result) 

mat migrantes[1, 1]=result[2, 1]


keep m - Total_`y'

keep in 1/14 

tempfile x 

save `x' 


****************************** 2017 Totals *************************************

use "$data/GEIH/Bases mensuales Cabecera ``mes'' `prior'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `prior'", force gen(resto) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

gen fex_entero=round(FEX_C_2011)

mat ``mes''_`prior'_`y' = J(14, 13, .)

mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)

gen Total_`prior' = .

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

gen i_y = inactivos

gen d_y = desocupado

gen e_y=(ocupados==1&(P6430==1|P6430==2))

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1)) 

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

gen p_y=(ocupados==1&(P6430==5))

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

gen of_y=(ocupados==1&P6430==6)

gen oc_y=(ocupados==1&P6430==4)

gen os_y=(ocupados==1&P6430==3)

gen on_y=(ocupados==1&P6430==7)

gen oj_y=(ocupados==1&P6430==8)

gen ot_y=(ocupados==1&P6430==9)


*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "e"

*** Patrones (p)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "p"

*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "ot"

*** Migracion (r)

replace Total_`prior' = migrantes[1, 1] if Origen_Destino == "imi"

keep Origen_Destino Total_`prior'

keep in 1/14

merge 1:1 Origen_Destino using `x', keep(3) nogen

*** Nacimientos (nac)

replace Total_`prior' = m if Origen_Destino == "nac"


*************************** Fallecidos por fila ********************************


replace qpd = tasas_qpd[1, 1]*Total_`prior' if Origen_Destino == "m"
replace qpd = tasas_qpd[1, 3]*Total_`prior' if Origen_Destino == "i"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "d"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "e"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "p"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "of"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oc"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "os"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "on"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oj"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "ot"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "imi"


************************ Correcciones individuales *****************************

* Valores de menores de edad para trabajar 

replace m = . if Origen_Destino == "m"
replace m = . if Origen_Destino == "e"
replace m = . if Origen_Destino == "i"

egen column_m = sum(m)

replace m = Total_`y' - column_m if Origen_Destino == "m"
drop column_m

* Valores de emigracion 

egen poblacion_`prior'=sum(Total_`prior')
egen poblacion_`y'=sum(Total_`y') if Origen_Destino!="qpd"
egen qpd_`y'_temp = max(Total_`y') if Origen_Destino == "qpd"
egen qpd_`y' = max(qpd_`y'_temp)

gen total_emigracion_`y' = poblacion_`prior' - poblacion_`y' - qpd_`y'

replace Total_`y' = total_emigracion_`y' if Origen_Destino == "imi"

egen poblacion_`prior'_temp = sum(Total_`prior') if Origen_Destino != "nac" & Origen_Destino != "imi"

egen poblacion_`prior'_temp2 = max(poblacion_`prior'_temp)

replace emi = (Total_`prior'*total_emigracion_`y')/poblacion_`prior'_temp2

replace emi = . if Origen_Destino == "nac"

replace emi = . if Origen_Destino == "imi"


drop poblacion_`y' poblacion_`prior' qpd_`y'_temp qpd_`y' total_emigracion_`y' poblacion_`prior'_temp poblacion_`prior'_temp2


********************************************************************************
*                    	  Section 10 - Save Outputs    	   				       *
********************************************************************************


* Archivo de Stata

save "$data/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_sin.dta", replace 


local prior = `prior' + 1


}

}

local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1 

}

}









******************************************************************************** 
*																			   *
*								Data  2012                        		       *      
*																			   *
********************************************************************************
	


local gender "1 2" 

foreach g of local gender {


local ages "10 20 30 40 50 60"

local gru_edu = 10 
local gru_edu2 = 11

foreach age of local ages {


local age_plus = `age' + 9


local years "2012"
tokenize "Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"



forval mes = 1/11  {
	
	local prior = 2011
	
foreach y of local years {
	

	dis `prior' `y'
	
use "$data/GEIH/Bases mensuales Cabecera ``mes'' `y'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `y'", force gen(resto) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

 dis `prior' `y'
 
egen total_poblacion = sum(FEX_C_2011)

sum total_poblacion

mat poblacion_total = r(mean)

drop total_poblacion


********************************************************************************
*                       Section 2 - Migration Data    		                   *
********************************************************************************

* Inmigration 

dis `prior' `y'

forvalues s=`y'/`y' {

merge 1:1 DIRECTORIO SECUENCIA_P MES ORDEN using "$data/GEIH/Migracion/Bases mensuales migracion ``mes'' `y'.dta", gen(migracion) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

replace migracion=0 if migracion!=3 
replace migracion=1 if migracion==3

}


dis `prior' `y'

********************************************************************************
*                          Section 3 - Variables    		                   *
********************************************************************************

gen fex_entero=round(FEX_C_2011)

*************************** Definicion de destinos *****************************

* Nota: la letra "y" en el nombre de las variables denota destino 
 
*** Menores de la edad de trabajar (m)

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

*** Inactivos (i)

gen i_y = inactivos

*** Desempleado (d)

gen d_y = desocupado

*** Empleado Regular o Patrones (e)

gen e_y=(ocupados==1&(P6430==1|P6430==2))

*** Empleador (p)

gen p_y=(ocupados==1&P6430==5)

*** Empleado en empresa de menos de 5 trabajadores (e0)

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1))

*** Empleado en empresa de mas de 5 trabajadores (e5)

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

*** Otro empleo (o)

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

*** Trabajador familiar (of)

gen of_y=(ocupados==1&P6430==6)

*** Cuenta propia (oc)

gen oc_y=(ocupados==1&P6430==4)

*** Empleado domestico (os)

gen os_y=(ocupados==1&P6430==3)

*** Trabajador sin remuneracion (on)

gen on_y=(ocupados==1&P6430==7)

*** Jornalero o peon (oj)

gen oj_y=(ocupados==1&P6430==8)

*** Otro (ot)

gen ot_y=(ocupados==1&P6430==9)

dis `prior' `y'
*************************** Definicion de origenes *****************************

* Nota: la letra "x" en el nombre de las variables denota origen 

*** Menores de la edad de trabajar (m)

gen m_x = ((P6040>=0&P6040<11&resto==1)|(P6040>=0&P6040<13&resto==0))

*** Desempleado (d)

gen d_x_1 = (P7430==1&P7440>2&P7440!=.&P7456==2)  // Definicion de los inactivos 
gen d_x_2 = (P7430==2&P7456==2) 				  // Definicion de los inactivos que no trabajaron antes
gen d_x_3 = (P7310==2&P7320>=52&P7250>=52) 		  // Definicion de los desocupados cesantes
gen d_x_4 = (P7310==1&P7250>=52) 				  // Definicion de los desocupados aspirantes
gen d_x_5 = (P6426<=12&P7020==1&P760>12&P760<=24) // Definicion de los ocupados 

egen d_x = rowmax(d_x_1 d_x_2 d_x_3 d_x_4 d_x_5)

*** Empleado Regular o Patrones (e)

gen e_x_1 = (P7430==1&(P7440==1|P7440==2))					   // Definicion de inactivos 
gen e_x_2 = (P7320>52&P7320<=104&(P7350==1|P7350==2)) 		   // Definicion de desocupados
gen e_x_3 = (P6426<=12&(P7028==1|P7028==2)&P760<4)             // Definicion de ocupados que cambiaron de empresa
gen e_x_4 = (P6426>12&(P6430==1|P6430==2))	    	           // Definicion de ocupados que no cambiaron de empresa 

egen e_x = rowmax(e_x_1 e_x_2 e_x_3 e_x_4)

*** Patrones (p)

gen p_x_1 = (P7320>52&P7320<=104&(P7350==5))     	 // Definicion de desocupados
gen p_x_2 = (P6426<=12&P7028==5&P760<4)    		     // Definicion de ocupados que cambiaron de empresa
gen p_x_3 = (P6426>12&P6430==5)	    	             // Definicion de ocupados que no cambiaron de empresa 

egen p_x = rowmax(p_x_1 p_x_2 p_x_3)

*** Otro empleo (o)

gen o_x_1 = (P7320>52&P7320<=104&(P7350!=1&P7350!=2&P7350!=5)) // Definicion de los desocupados 
gen o_x_2 = (P6426<=12&(P7028!=1&P7028!=2&P7028!=5)&P760<4)    // Definicion de los ocupados 
gen o_x_3 = (P6426>=24&P6430!=1&P6430!=2&P6430!=3)             // Ocupados que no cambiaron de trabajo 

egen o_x = rowmax(o_x_1 o_x_2 o_x_3)

*** Trabajador familiar (of)

gen of_x_1 = (P7320>52&P7320<=104&(P7350==6))   // Definicion de los desocupados 
gen of_x_2 = (P6426<=12&P7028==6&P760<4)  		// Definicion de los ocupados
gen of_x_3 = (P6426>=24&P6430==6) 			    // Ocupados que no cambiaron de trabajo 

egen of_x = rowmax(of_x_1 of_x_2 of_x_3) 

*** Cuenta propia (oc)

gen oc_x_1 = (P7320>52&P7320<=104&(P7350==4))	// Definicion de los desocupados 
gen oc_x_2 = (P6426<=12&P7028==4&P760<4)		// Definicion de los ocupados 
gen oc_x_3 = (P6426>=24&P6430==4) 				// Ocupados que no cambiaron de trabajo 

egen oc_x = rowmax(oc_x_1 oc_x_2 oc_x_3)

*** Empleado domestico (os)

gen os_x_1 = (P7320>52&P7320<=104&(P7350==3))	// Definicion de los desocupados
gen os_x_2 = (P6426<=12&P7028==3&P760<4)		// Definicion de los ocupados
gen os_x_3 = (P6426>=24&P6430==3)			    // Ocupados que no cambiaron de trabajo 

egen os_x = rowmax(os_x_1 os_x_2 os_x_3)

*** Trabajador sin remuneracion (on)

gen on_x_1 = (P7320>52&P7320<=104&(P7350==7))   // Definicion de los desocupados 
gen on_x_2 = (P6426<=12&P7028==7&P760<4)  		// Definicion de los ocupados
gen on_x_3 = (P6426>=24&P6430==7) 			    // Ocupados que no cambiaron de trabajo 

egen on_x = rowmax(on_x_1 on_x_2 on_x_3) 

*** Jornalero o peon (oj)

gen oj_x_1 = (P7320>52&P7320<=104&(P7350==8))   // Definicion de los desocupados 
gen oj_x_2 = (P6426<=12&P7028==8&P760<4)  		// Definicion de los ocupados
gen oj_x_3 = (P6426>=24&P6430==8) 			    // Ocupados que no cambiaron de trabajo 

egen oj_x = rowmax(oj_x_1 oj_x_2 oj_x_3) 

*** Otro (ot)

gen ot_x_1 = (P7320>52&P7320<=104&(P7350==9))   // Definicion de los desocupados 
gen ot_x_2 = (P6426<=12&P7028==9&P760<4)  		// Definicion de los ocupados
gen ot_x_3 = (P6426>=24&P6430==9) 			    // Ocupados que no cambiaron de trabajo 

egen ot_x = rowmax(ot_x_1 ot_x_2 ot_x_3) 

*** Inactivos (i)

gen i_x_2 = (P7310==2&P7320>52&P7250<=52)                      // Definicion de los desocupados cesantes
gen i_x_3 = (P7310==1&P7250<=52) 							   // Definicion de los desocupados aspirantes 
gen i_x_4 = (P6426<=12&P7020==2)	 						   // Definicion de los ocupados  
gen i_x_5 = (P6426<=12&P7020==1&P760>24)					   // Definicion de los ocupados    
gen i_x_1 = (P7440==3|P7440==4|P7440==9)					   // Definicion de los inactivos  

egen i_x = rowmax(i_x_1 i_x_2 i_x_3 i_x_4 i_x_5)  			   // i_o_3

*** Migracion (r) (r por reallocation)

gen r_x = (migracion==1&P753S3!=.)

dis `prior' `y'
********************************************************************************
*                          Section 4 - Transitions    		                   *
********************************************************************************


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen m_`v'=(m_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen i_`v'=(i_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen d_`v'=(d_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen e_`v'=(e_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen p_`v'=(p_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen o_`v'=(o_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen of_`v'=(of_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oc_`v'=(oc_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen os_`v'=(os_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen on_`v'=(on_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oj_`v'=(oj_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen ot_`v'=(ot_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen r_`v'=(r_x==1&`v'_y==1)

}

dis `prior' `y'

********************************************************************************
*                      Section 5 - Matrix to save outcomes                     *
********************************************************************************


mat ``mes''_`prior'_`y' = J(14, 13, .)

mat list ``mes''_`prior'_`y'


mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)
  
 
********************************************************************************
*                          Section 6 - Tabulates     		                   *
********************************************************************************

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab m_`v' [fw=fex_entero], matcell(result)

replace `v' = result[2, 1] if Origen_Destino == "m"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab  i_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "i"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab d_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "d"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab e_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "e"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab p_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "p"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab of_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "of" 

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oc_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oc"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab os_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "os"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab on_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "on"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oj_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oj"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab ot_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "ot"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab r_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "imi"

}



********************************************************************************
*                          Section 7 - Death Rate     		                   *
********************************************************************************


preserve 

noisily use "$rawdata/Vitales/nofetal`prior'.dta", clear

append using "$rawdata/Vitales/nofetal`y'.dta", force 

keep if (GRU_ED1 == "`gru_edu'" | GRU_ED1 == "`gru_edu2'")

keep if (YEAR==`prior' & mes>`mes') | (YEAR==`y' & mes<=`mes')

mat fallecidos = J(1, 1, .)

count 

mat fallecidos[1, 1]= r(N)

gen   menores =(GRU_ED2=="01"|GRU_ED2=="02"|GRU_ED2=="03")   // No se dejan los mayores

gen   inactivos  =(OCUPACION=="PENSIONADO"|OCUPACION=="ESTUDIANTE"|OCUPACION=="AMA DE CASA")        

gen   ocupados =(menores==0&inactivos==0)           

gen totales = poblacion_total[1, 1]

egen T_menores = sum(menores)
egen T_inactivos = sum(inactivos)
egen T_ocupados = sum(ocupados) 

gen t_menores = T_menores/totales
gen t_inactivos = T_inactivos/totales
gen t_ocupados = T_ocupados/totales 

sum t_menores t_inactivos t_ocupados

mat tasas_qpd = J(1, 3, .)

sum t_menores, meanonly 
mat tasas_qpd[1, 1]=r(mean)

sum t_ocupados, meanonly
mat tasas_qpd[1, 2]=r(mean)

sum t_inactivos, meanonly
mat tasas_qpd[1, 3]=r(mean)

drop T_menores T_inactivos T_ocupados


restore 


********************************************************************************
*                         	 Section 8 - Births     		                   *
********************************************************************************

preserve 

use "$rawdata/Vitales/nac`prior'.dta", clear

append using "$rawdata/Vitales/nac`y'.dta", force 


keep if (ANO==`prior' & mes>`mes') | (ANO==`y' & mes<=`mes')

mat nacimientos = J(1, 1, .)

restore 

replace m = nacimientos[1, 1] if Origen_Destino == "nac"


********************************************************************************
*                    Section 9 - Row and Column Totals     		               *
********************************************************************************


gen Total_`y' = . 


******************************* 2018 Totals ************************************

*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "e"

*** Patrones (p)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "p"


*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "ot"

*** Fallecidos (qpd)

replace Total_`y' = fallecidos[1, 1] if Origen_Destino == "qpd"

*** Migrantes (r)

mat migrantes = J(1, 1, .)

tab r_x [fw=fex_entero], matcell(result) 

mat migrantes[1, 1]=result[2, 1]


keep m - Total_`y'

keep in 1/14 

tempfile x 

save `x' 


****************************** 2017 Totals *************************************

use "$data/GEIH/Bases mensuales Cabecera ``mes'' `prior'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `prior'", force gen(resto) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

gen fex_entero=round(FEX_C_2011)

mat ``mes''_`prior'_`y' = J(14, 13, .)

mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)

gen Total_`prior' = .

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

gen i_y = inactivos

gen d_y = desocupado

gen e_y=(ocupados==1&(P6430==1|P6430==2))

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1)) 

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

gen p_y=(ocupados==1&(P6430==5))

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

gen of_y=(ocupados==1&P6430==6)

gen oc_y=(ocupados==1&P6430==4)

gen os_y=(ocupados==1&P6430==3)

gen on_y=(ocupados==1&P6430==7)

gen oj_y=(ocupados==1&P6430==8)

gen ot_y=(ocupados==1&P6430==9)


*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "e"

*** Patrones (p)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "p"

*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "ot"

*** Migracion (r)

replace Total_`prior' = migrantes[1, 1] if Origen_Destino == "imi"

keep Origen_Destino Total_`prior'

keep in 1/14

merge 1:1 Origen_Destino using `x', keep(3) nogen

*** Nacimientos (nac)

replace Total_`prior' = m if Origen_Destino == "nac"


*************************** Fallecidos por fila ********************************


replace qpd = tasas_qpd[1, 1]*Total_`prior' if Origen_Destino == "m"
replace qpd = tasas_qpd[1, 3]*Total_`prior' if Origen_Destino == "i"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "d"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "e"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "p"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "of"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oc"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "os"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "on"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oj"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "ot"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "imi"


************************ Correcciones individuales *****************************

* Valores de menores de edad para trabajar 

replace m = . if Origen_Destino == "m"
replace m = . if Origen_Destino == "e"
replace m = . if Origen_Destino == "i"

egen column_m = sum(m)

replace m = Total_`y' - column_m if Origen_Destino == "m"
drop column_m

* Valores de emigracion 

egen poblacion_`prior'=sum(Total_`prior')
egen poblacion_`y'=sum(Total_`y') if Origen_Destino!="qpd"
egen qpd_`y'_temp = max(Total_`y') if Origen_Destino == "qpd"
egen qpd_`y' = max(qpd_`y'_temp)

gen total_emigracion_`y' = poblacion_`prior' - poblacion_`y' - qpd_`y'

replace Total_`y' = total_emigracion_`y' if Origen_Destino == "imi"

egen poblacion_`prior'_temp = sum(Total_`prior') if Origen_Destino != "nac" & Origen_Destino != "imi"

egen poblacion_`prior'_temp2 = max(poblacion_`prior'_temp)

replace emi = (Total_`prior'*total_emigracion_`y')/poblacion_`prior'_temp2

replace emi = . if Origen_Destino == "nac"

replace emi = . if Origen_Destino == "imi"


drop poblacion_`y' poblacion_`prior' qpd_`y'_temp qpd_`y' total_emigracion_`y' poblacion_`prior'_temp poblacion_`prior'_temp2


********************************************************************************
*                    	  Section 10 - Save Outputs    	   				       *
********************************************************************************


* Archivo de Stata

save "$data/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_sin.dta", replace 


local prior = `prior' + 1

}

}


local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1 

}

}


******************************************************************************** 
*																			   *
*								Data before 2012                               *      
*																			   *
********************************************************************************
	
	

local gender "1 2" 

foreach g of local gender {


local ages "10 20 30 40 50 60"

local gru_edu = 10 
local gru_edu2 = 11

foreach age of local ages {


local age_plus = `age' + 9


local years   "2008 2009 2010 2011 2012" // "2012"
tokenize   "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"  // "Enero"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

	dis `prior' `y'
	
use "$data/GEIH/Bases mensuales Cabecera ``mes'' `y'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `y'", force gen(resto) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

 dis `prior' `y'
 
egen total_poblacion = sum(FEX_C_2011)

sum total_poblacion

mat poblacion_total = r(mean)

drop total_poblacion

********************************************************************************
*                       Section 2 - Migration Data    		                   *
********************************************************************************

* Inmigration 


dis `prior' `y'

********************************************************************************
*                          Section 3 - Variables    		                   *
********************************************************************************

gen fex_entero=round(FEX_C_2011)

*************************** Definicion de destinos *****************************

* Nota: la letra "y" en el nombre de las variables denota destino 
 
*** Menores de la edad de trabajar (m)

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

*** Inactivos (i)

gen i_y = inactivos

*** Desempleado (d)

gen d_y = desocupado

*** Empleado Regular o Patrones (e)

gen e_y=(ocupados==1&(P6430==1|P6430==2))

*** Empleador (p)

gen p_y=(ocupados==1&P6430==5)

*** Empleado en empresa de menos de 5 trabajadores (e0)

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1))

*** Empleado en empresa de mas de 5 trabajadores (e5)

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

*** Otro empleo (o)

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

*** Trabajador familiar (of)

gen of_y=(ocupados==1&P6430==6)

*** Cuenta propia (oc)

gen oc_y=(ocupados==1&P6430==4)

*** Empleado domestico (os)

gen os_y=(ocupados==1&P6430==3)

*** Trabajador sin remuneracion (on)

gen on_y=(ocupados==1&P6430==7)

*** Jornalero o peon (oj)

gen oj_y=(ocupados==1&P6430==8)

*** Otro (ot)

gen ot_y=(ocupados==1&P6430==9)

dis `prior' `y'
*************************** Definicion de origenes *****************************

* Nota: la letra "x" en el nombre de las variables denota origen 

*** Menores de la edad de trabajar (m)

gen m_x = ((P6040>=0&P6040<11&resto==1)|(P6040>=0&P6040<13&resto==0))

*** Desempleado (d)

gen d_x_1 = (P7430==1&P7440>2&P7440!=.&P7456==2)  // Definicion de los inactivos 
gen d_x_2 = (P7430==2&P7456==2) 				  // Definicion de los inactivos que no trabajaron antes
gen d_x_3 = (P7310==2&P7320>=52&P7250>=52) 		  // Definicion de los desocupados cesantes
gen d_x_4 = (P7310==1&P7250>=52) 				  // Definicion de los desocupados aspirantes
gen d_x_5 = (P6426<=12&P7020==1&P760>12&P760<=24) // Definicion de los ocupados 

egen d_x = rowmax(d_x_1 d_x_2 d_x_3 d_x_4 d_x_5)

*** Empleado Regular o Patrones (e)

gen e_x_1 = (P7430==1&(P7440==1|P7440==2))					   // Definicion de inactivos 
gen e_x_2 = (P7320>52&P7320<=104&(P7350==1|P7350==2)) 		   // Definicion de desocupados
gen e_x_3 = (P6426<=12&(P7028==1|P7028==2)&P760<4)             // Definicion de ocupados que cambiaron de empresa
gen e_x_4 = (P6426>12&(P6430==1|P6430==2))	    	           // Definicion de ocupados que no cambiaron de empresa 

egen e_x = rowmax(e_x_1 e_x_2 e_x_3 e_x_4)

*** Patrones (p)

gen p_x_1 = (P7320>52&P7320<=104&(P7350==5))     	 // Definicion de desocupados
gen p_x_2 = (P6426<=12&P7028==5&P760<4)    		     // Definicion de ocupados que cambiaron de empresa
gen p_x_3 = (P6426>12&P6430==5)	    	             // Definicion de ocupados que no cambiaron de empresa 

egen p_x = rowmax(p_x_1 p_x_2 p_x_3)

*** Otro empleo (o)

gen o_x_1 = (P7320>52&P7320<=104&(P7350!=1&P7350!=2&P7350!=5)) // Definicion de los desocupados 
gen o_x_2 = (P6426<=12&(P7028!=1&P7028!=2&P7028!=5)&P760<4)    // Definicion de los ocupados 
gen o_x_3 = (P6426>=24&P6430!=1&P6430!=2&P6430!=3)             // Ocupados que no cambiaron de trabajo 

egen o_x = rowmax(o_x_1 o_x_2 o_x_3)

*** Trabajador familiar (of)

gen of_x_1 = (P7320>52&P7320<=104&(P7350==6))   // Definicion de los desocupados 
gen of_x_2 = (P6426<=12&P7028==6&P760<4)  		// Definicion de los ocupados
gen of_x_3 = (P6426>=24&P6430==6) 			    // Ocupados que no cambiaron de trabajo 

egen of_x = rowmax(of_x_1 of_x_2 of_x_3) 

*** Cuenta propia (oc)

gen oc_x_1 = (P7320>52&P7320<=104&(P7350==4))	// Definicion de los desocupados 
gen oc_x_2 = (P6426<=12&P7028==4&P760<4)		// Definicion de los ocupados 
gen oc_x_3 = (P6426>=24&P6430==4) 				// Ocupados que no cambiaron de trabajo 

egen oc_x = rowmax(oc_x_1 oc_x_2 oc_x_3)

*** Empleado domestico (os)

gen os_x_1 = (P7320>52&P7320<=104&(P7350==3))	// Definicion de los desocupados
gen os_x_2 = (P6426<=12&P7028==3&P760<4)		// Definicion de los ocupados
gen os_x_3 = (P6426>=24&P6430==3)			    // Ocupados que no cambiaron de trabajo 

egen os_x = rowmax(os_x_1 os_x_2 os_x_3)

*** Trabajador sin remuneracion (on)

gen on_x_1 = (P7320>52&P7320<=104&(P7350==7))   // Definicion de los desocupados 
gen on_x_2 = (P6426<=12&P7028==7&P760<4)  		// Definicion de los ocupados
gen on_x_3 = (P6426>=24&P6430==7) 			    // Ocupados que no cambiaron de trabajo 

egen on_x = rowmax(on_x_1 on_x_2 on_x_3) 

*** Jornalero o peon (oj)

gen oj_x_1 = (P7320>52&P7320<=104&(P7350==8))   // Definicion de los desocupados 
gen oj_x_2 = (P6426<=12&P7028==8&P760<4)  		// Definicion de los ocupados
gen oj_x_3 = (P6426>=24&P6430==8) 			    // Ocupados que no cambiaron de trabajo 

egen oj_x = rowmax(oj_x_1 oj_x_2 oj_x_3) 

*** Otro (ot)

gen ot_x_1 = (P7320>52&P7320<=104&(P7350==9))   // Definicion de los desocupados 
gen ot_x_2 = (P6426<=12&P7028==9&P760<4)  		// Definicion de los ocupados
gen ot_x_3 = (P6426>=24&P6430==9) 			    // Ocupados que no cambiaron de trabajo 

egen ot_x = rowmax(ot_x_1 ot_x_2 ot_x_3) 

*** Inactivos (i)

gen i_x_2 = (P7310==2&P7320>52&P7250<=52)                      // Definicion de los desocupados cesantes
gen i_x_3 = (P7310==1&P7250<=52) 							   // Definicion de los desocupados aspirantes 
gen i_x_4 = (P6426<=12&P7020==2)	 						   // Definicion de los ocupados  
gen i_x_5 = (P6426<=12&P7020==1&P760>24)					   // Definicion de los ocupados    
gen i_x_1 = (P7440==3|P7440==4|P7440==9)					   // Definicion de los inactivos  

egen i_x = rowmax(i_x_1 i_x_2 i_x_3 i_x_4 i_x_5)  			   // i_o_3

*** Migracion (r) (r por reallocation)

gen r_x = 0

dis `prior' `y'
********************************************************************************
*                          Section 4 - Transitions    		                   *
********************************************************************************


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen m_`v'=(m_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen i_`v'=(i_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen d_`v'=(d_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen e_`v'=(e_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen p_`v'=(p_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen o_`v'=(o_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen of_`v'=(of_x==1&`v'_y==1)

}

local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oc_`v'=(oc_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen os_`v'=(os_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen on_`v'=(on_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen oj_`v'=(oj_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen ot_`v'=(ot_x==1&`v'_y==1)

}


local var "m i d e e0 e5 p o of oc os on oj ot"

foreach v of local var {

gen r_`v'=(r_x==1&`v'_y==1)

}

dis `prior' `y'

********************************************************************************
*                      Section 5 - Matrix to save outcomes                     *
********************************************************************************


mat ``mes''_`prior'_`y' = J(14, 13, .)

mat list ``mes''_`prior'_`y'


mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)
  
 
********************************************************************************
*                          Section 6 - Tabulates     		                   *
********************************************************************************

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab m_`v' [fw=fex_entero], matcell(result)

replace `v' = result[2, 1] if Origen_Destino == "m"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab  i_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "i"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab d_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "d"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab e_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "e"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab p_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "p"

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab of_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "of" 

}

local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oc_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oc"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab os_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "os"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab on_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "on"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab oj_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "oj"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab ot_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "ot"

}


local var "m i d e e0 e5 p of oc os on oj ot" // o 

foreach v of local var {

tab r_`v' [fw=fex_entero], matcell(result) 

replace `v' = result[2, 1] if Origen_Destino == "imi"

}



********************************************************************************
*                          Section 7 - Death Rate     		                   *
********************************************************************************


preserve 

noisily use "$rawdata/Vitales/nofetal`prior'.dta", clear

append using "$rawdata/Vitales/nofetal`y'.dta", force 

keep if (GRU_ED1 == "`gru_edu'" | GRU_ED1 == "`gru_edu2'")

keep if (YEAR==`prior' & mes>`mes') | (YEAR==`y' & mes<=`mes')

mat fallecidos = J(1, 1, .)

count 

mat fallecidos[1, 1]= r(N)

gen   menores =(GRU_ED2=="01"|GRU_ED2=="02"|GRU_ED2=="03")   // No se dejan los mayores

gen   inactivos  =(OCUPACION=="PENSIONADO"|OCUPACION=="ESTUDIANTE"|OCUPACION=="AMA DE CASA")        

gen   ocupados =(menores==0&inactivos==0)           

gen totales = poblacion_total[1, 1]

egen T_menores = sum(menores)
egen T_inactivos = sum(inactivos)
egen T_ocupados = sum(ocupados) 

gen t_menores = T_menores/totales
gen t_inactivos = T_inactivos/totales
gen t_ocupados = T_ocupados/totales 

sum t_menores t_inactivos t_ocupados

mat tasas_qpd = J(1, 3, .)

sum t_menores, meanonly 
mat tasas_qpd[1, 1]=r(mean)

sum t_ocupados, meanonly
mat tasas_qpd[1, 2]=r(mean)

sum t_inactivos, meanonly
mat tasas_qpd[1, 3]=r(mean)

drop T_menores T_inactivos T_ocupados


restore 


********************************************************************************
*                         	 Section 8 - Births     		                   *
********************************************************************************

preserve 

use "$rawdata/Vitales/nac`prior'.dta", clear

append using "$rawdata/Vitales/nac`y'.dta", force 

keep if (ANO==`prior' & mes>`mes') | (ANO==`y' & mes<=`mes')

mat nacimientos = J(1, 1, .)

restore 

replace m = nacimientos[1, 1] if Origen_Destino == "nac"


********************************************************************************
*                    Section 9 - Row and Column Totals     		               *
********************************************************************************


gen Total_`y' = . 


******************************* 2018 Totals ************************************

*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "e"

*** Patrones (e)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "p"


*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`y' = result[2, 1] if Origen_Destino == "ot"

*** Fallecidos (qpd)

replace Total_`y' = fallecidos[1, 1] if Origen_Destino == "qpd"

*** Migrantes (r)

mat migrantes = J(1, 1, .)

tab r_x [fw=fex_entero], matcell(result) 

mat migrantes[1, 1]=result[2, 1]


keep m - Total_`y'

keep in 1/14 

tempfile x 

save `x' 


****************************** 2017 Totals *************************************

use "$data/GEIH/Bases mensuales Cabecera ``mes'' `prior'", clear 

append using "$data/GEIH/Bases mensuales Resto ``mes'' `prior'", force gen(resto) 

keep if P6020 ==  `g'
keep if P6040 >= `age' & P6040 < `age_plus'

gen sin_educ_sup = (P6210 != 6)
keep if sin_educ_sup == 1 

gen fex_entero=round(FEX_C_2011)

mat ``mes''_`prior'_`y' = J(14, 13, .)

mat colnames ``mes''_`prior'_`y' = m i d e p of oc os on oj ot qpd emi 
mat rownames ``mes''_`prior'_`y' = nac m i d e p of oc os on oj ot qpd imi

svmat2 ``mes''_`prior'_`y', names(col) rnames(Origen_Destino)

gen Total_`prior' = .

gen edad=P6040
gen m_y = ((P6040>=0&P6040<12&resto==0)|(P6040>=0&P6040<10&resto==1))

gen i_y = inactivos

gen d_y = desocupado

gen e_y=(ocupados==1&(P6430==1|P6430==2))

gen e0_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870<4&P6870>1)) 

gen e5_y=(ocupados==1&(P6430==1|P6430==2|P6430==5)&(P6870>=4&P6870!=.1))

gen p_y=(ocupados==1&(P6430==5))

gen o_y=(ocupados==1&(P6430!=1&P6430!=2&P6430!=5))

gen of_y=(ocupados==1&P6430==6)

gen oc_y=(ocupados==1&P6430==4)

gen os_y=(ocupados==1&P6430==3)

gen on_y=(ocupados==1&P6430==7)

gen oj_y=(ocupados==1&P6430==8)

gen ot_y=(ocupados==1&P6430==9)


*** Menores de la edad de trabajar (m)

tab m_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "m"

*** Inactivos (i)

tab i_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "i"

*** Desempleado (d)

tab d_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "d"

*** Empleado Regular (e)

tab e_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "e"

*** Patrones (p)

tab p_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "p"

*** Trabajador familiar (of)

tab of_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "of"

*** Cuenta propia (oc)

tab oc_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oc"

*** Empleado domestico (os)

tab os_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "os"

*** Trabajador sin remuneracion (on)

tab on_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "on"

*** Jornalero o peon (oj)

tab oj_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "oj"

*** Otro (ot)

tab ot_y [fw=fex_entero], matcell(result)

replace Total_`prior' = result[2, 1] if Origen_Destino == "ot"

*** Migracion (r)

replace Total_`prior' = migrantes[1, 1] if Origen_Destino == "imi"

keep Origen_Destino Total_`prior'

keep in 1/14

merge 1:1 Origen_Destino using `x', keep(3) nogen

*** Nacimientos (nac)

replace Total_`prior' = m if Origen_Destino == "nac"


*************************** Fallecidos por fila ********************************


replace qpd = tasas_qpd[1, 1]*Total_`prior' if Origen_Destino == "m"
replace qpd = tasas_qpd[1, 3]*Total_`prior' if Origen_Destino == "i"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "d"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "e"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "p"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "of"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oc"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "os"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "on"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "oj"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "ot"
replace qpd = tasas_qpd[1, 2]*Total_`prior' if Origen_Destino == "imi"


************************ Correcciones individuales *****************************

* Valores de menores de edad para trabajar 

replace m = . if Origen_Destino == "m"
replace m = . if Origen_Destino == "e"
replace m = . if Origen_Destino == "i"

egen column_m = sum(m)

replace m = Total_`y' - column_m if Origen_Destino == "m"
drop column_m

* Valores de emigracion 

egen poblacion_`prior'=sum(Total_`prior')
egen poblacion_`y'=sum(Total_`y') if Origen_Destino!="qpd"
egen qpd_`y'_temp = max(Total_`y') if Origen_Destino == "qpd"
egen qpd_`y' = max(qpd_`y'_temp)

gen total_emigracion_`y' = poblacion_`prior' - poblacion_`y' - qpd_`y'

replace Total_`y' = total_emigracion_`y' if Origen_Destino == "imi"

egen poblacion_`prior'_temp = sum(Total_`prior') if Origen_Destino != "nac" & Origen_Destino != "imi"

egen poblacion_`prior'_temp2 = max(poblacion_`prior'_temp)

replace emi = (Total_`prior'*total_emigracion_`y')/poblacion_`prior'_temp2

replace emi = . if Origen_Destino == "nac"

replace emi = . if Origen_Destino == "imi"


drop poblacion_`y' poblacion_`prior' qpd_`y'_temp qpd_`y' total_emigracion_`y' poblacion_`prior'_temp poblacion_`prior'_temp2


********************************************************************************
*                    	  Section 10 - Save Outputs    	   				       *
********************************************************************************


* Archivo de Stata

save "$data/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'_`g'_sin.dta", replace 


local prior = `prior' + 1

}

}



local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1 

}

}


	
	

local gender "1 2" 

foreach g of local gender {


local ages "10 20 30 40 50 60"

local gru_edu = 10 
local gru_edu2 = 11

foreach age of local ages {


local age_plus = `age' + 9


use "$data/Transiciones/Transiciones_Febrero_2011_2012_`age'_`age_plus'_`g'_sin.dta", replace

local mes "Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach m of local mes {
	
append using "$data/Transiciones/Transiciones_`m'_2011_2012_`age'_`age_plus'_`g'_sin.dta", force

}

keep emi  Origen_Destino 

collapse (mean) emi, by(Origen_Destino)

rename emi emi_2012_Enero 


gen emi_2011_Diciembre = (emi_2012_Enero)*(1+0.012)
gen emi_2011_Noviembre = (emi_2011_Diciembre)*(1+0.012)
gen emi_2011_Octubre = (emi_2011_Noviembre)*(1+0.012)
gen emi_2011_Septiembre = (emi_2011_Octubre)*(1+0.012)
gen emi_2011_Agosto = (emi_2011_Septiembre)*(1+0.012)
gen emi_2011_Julio = (emi_2011_Agosto)*(1+0.012)
gen emi_2011_Junio = (emi_2011_Julio)*(1+0.012)
gen emi_2011_Mayo = (emi_2011_Junio)*(1+0.012)
gen emi_2011_Abril = (emi_2011_Mayo)*(1+0.012)
gen emi_2011_Marzo = (emi_2011_Abril)*(1+0.012)
gen emi_2011_Febrero = (emi_2011_Marzo)*(1+0.012)
gen emi_2011_Enero = (emi_2011_Febrero)*(1+0.012)


gen emi_2010_Diciembre = (emi_2011_Enero)*(1+0.012)
gen emi_2010_Noviembre = (emi_2010_Diciembre)*(1+0.012)
gen emi_2010_Octubre = (emi_2010_Noviembre)*(1+0.012)
gen emi_2010_Septiembre = (emi_2010_Octubre)*(1+0.012)
gen emi_2010_Agosto = (emi_2010_Septiembre)*(1+0.012)
gen emi_2010_Julio = (emi_2010_Agosto)*(1+0.012)
gen emi_2010_Junio = (emi_2010_Julio)*(1+0.012)
gen emi_2010_Mayo = (emi_2010_Junio)*(1+0.012)
gen emi_2010_Abril = (emi_2010_Mayo)*(1+0.012)
gen emi_2010_Marzo = (emi_2010_Abril)*(1+0.012)
gen emi_2010_Febrero = (emi_2010_Marzo)*(1+0.012)
gen emi_2010_Enero = (emi_2010_Febrero)*(1+0.012)

gen emi_2009_Diciembre = (emi_2010_Enero)*(1+0.012)
gen emi_2009_Noviembre = (emi_2009_Diciembre)*(1+0.012)
gen emi_2009_Octubre = (emi_2009_Noviembre)*(1+0.012)
gen emi_2009_Septiembre = (emi_2009_Octubre)*(1+0.012)
gen emi_2009_Agosto = (emi_2009_Septiembre)*(1+0.012)
gen emi_2009_Julio = (emi_2009_Agosto)*(1+0.012)
gen emi_2009_Junio = (emi_2009_Julio)*(1+0.012)
gen emi_2009_Mayo = (emi_2009_Junio)*(1+0.012)
gen emi_2009_Abril = (emi_2009_Mayo)*(1+0.012)
gen emi_2009_Marzo = (emi_2009_Abril)*(1+0.012)
gen emi_2009_Febrero = (emi_2009_Marzo)*(1+0.012)
gen emi_2009_Enero = (emi_2009_Febrero)*(1+0.012)


gen emi_2008_Diciembre = (emi_2009_Enero)*(1+0.012)
gen emi_2008_Noviembre = (emi_2008_Diciembre)*(1+0.012)
gen emi_2008_Octubre = (emi_2008_Noviembre)*(1+0.012)
gen emi_2008_Septiembre = (emi_2008_Octubre)*(1+0.012)
gen emi_2008_Agosto = (emi_2008_Septiembre)*(1+0.012)
gen emi_2008_Julio = (emi_2008_Agosto)*(1+0.012)
gen emi_2008_Junio = (emi_2008_Julio)*(1+0.012)
gen emi_2008_Mayo = (emi_2008_Junio)*(1+0.012)
gen emi_2008_Abril = (emi_2008_Mayo)*(1+0.012)
gen emi_2008_Marzo = (emi_2008_Abril)*(1+0.012)
gen emi_2008_Febrero = (emi_2008_Marzo)*(1+0.012)
gen emi_2008_Enero = (emi_2008_Febrero)*(1+0.012)

save "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", replace 





****** Merge de las bases 

* 2011 

use "$data/Transiciones/Transiciones_Enero_2011_2012_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2012_Enero) nogen

rename emi_2012_Enero emi

egen temp = sum(emi)

replace Total_2012 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Enero_2011_2012_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Diciembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Diciembre) nogen

rename emi_2011_Diciembre emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Diciembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Noviembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Noviembre) nogen

rename emi_2011_Noviembre emi

save "$data/Transiciones/Transiciones_Noviembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Octubre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Octubre) nogen

rename emi_2011_Octubre emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Octubre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Septiembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Septiembre) nogen

rename emi_2011_Septiembre emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Septiembre_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Agosto_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Agosto) nogen

rename emi_2011_Agosto emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Agosto_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Julio_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Julio) nogen

rename emi_2011_Julio emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Julio_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Junio_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Junio) nogen

rename emi_2011_Junio emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Junio_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Mayo_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Mayo) nogen

rename emi_2011_Mayo emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Mayo_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Abril_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Abril) nogen

rename emi_2011_Abril emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Abril_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Marzo_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Marzo) nogen

rename emi_2011_Marzo emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Marzo_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Febrero_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Febrero) nogen

rename emi_2011_Febrero emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Febrero_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Enero_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2011_Enero) nogen

rename emi_2011_Enero emi

egen temp = sum(emi)

replace Total_2011 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Enero_2010_2011_`age'_`age_plus'_`g'_sin.dta", replace 


* 2010 



use "$data/Transiciones/Transiciones_Diciembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Diciembre) nogen

rename emi_2010_Diciembre emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Diciembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Noviembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Noviembre) nogen

rename emi_2010_Noviembre emi

save "$data/Transiciones/Transiciones_Noviembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Octubre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Octubre) nogen

rename emi_2010_Octubre emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Octubre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Septiembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Septiembre) nogen

rename emi_2010_Septiembre emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Septiembre_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Agosto_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Agosto) nogen

rename emi_2010_Agosto emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Agosto_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Julio_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Julio) nogen

rename emi_2010_Julio emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Julio_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Junio_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Junio) nogen

rename emi_2010_Junio emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Junio_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Mayo_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Mayo) nogen

rename emi_2010_Mayo emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Mayo_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Abril_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Abril) nogen

rename emi_2010_Abril emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Abril_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Marzo_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 
 
cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Marzo) nogen

rename emi_2010_Marzo emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Marzo_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Febrero_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Febrero) nogen

rename emi_2010_Febrero emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Febrero_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Enero_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2010_Enero) nogen

rename emi_2010_Enero emi

egen temp = sum(emi)

replace Total_2010 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Enero_2009_2010_`age'_`age_plus'_`g'_sin.dta", replace 



* 2009 




use "$data/Transiciones/Transiciones_Diciembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Diciembre) nogen

rename emi_2009_Diciembre emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Diciembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Noviembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Noviembre) nogen

rename emi_2009_Noviembre emi

save "$data/Transiciones/Transiciones_Noviembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Octubre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Octubre) nogen

rename emi_2009_Octubre emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Octubre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Septiembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Septiembre) nogen

rename emi_2009_Septiembre emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Septiembre_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Agosto_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Agosto) nogen

rename emi_2009_Agosto emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Agosto_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Julio_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Julio) nogen

rename emi_2009_Julio emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Julio_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Junio_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Junio) nogen

rename emi_2009_Junio emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Junio_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Mayo_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Mayo) nogen

rename emi_2009_Mayo emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Mayo_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Abril_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Abril) nogen

rename emi_2009_Abril emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Abril_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Marzo_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Marzo) nogen

rename emi_2009_Marzo emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Marzo_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Febrero_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Febrero) nogen

rename emi_2009_Febrero emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Febrero_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Enero_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2009_Enero) nogen

rename emi_2009_Enero emi

egen temp = sum(emi)

replace Total_2009 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Enero_2008_2009_`age'_`age_plus'_`g'_sin.dta", replace 





* 2008 



use "$data/Transiciones/Transiciones_Diciembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Diciembre) nogen

rename emi_2008_Diciembre emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Diciembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Noviembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Noviembre) nogen

rename emi_2008_Noviembre emi

save "$data/Transiciones/Transiciones_Noviembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Octubre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Octubre) nogen

rename emi_2008_Octubre emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Octubre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Septiembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Septiembre) nogen

rename emi_2008_Septiembre emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Septiembre_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Agosto_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Agosto) nogen

rename emi_2008_Agosto emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Agosto_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Julio_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Julio) nogen

rename emi_2008_Julio emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Julio_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Junio_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Junio) nogen

rename emi_2008_Junio emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Junio_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Mayo_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Mayo) nogen

rename emi_2008_Mayo emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Mayo_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Abril_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Abril) nogen

rename emi_2008_Abril emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Abril_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Marzo_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Marzo) nogen

rename emi_2008_Marzo emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Marzo_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


use "$data/Transiciones/Transiciones_Febrero_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Febrero) nogen

rename emi_2008_Febrero emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Febrero_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 



use "$data/Transiciones/Transiciones_Enero_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace

drop emi 

cap drop _merge 

merge 1:1 Origen_Destino using "$data/Transiciones/Transiciones_before_2012_`age'_`age_plus'_`g'_sin.dta", keepusing(emi_2008_Enero) nogen 

rename emi_2008_Enero emi

egen temp = sum(emi)

replace Total_2008 = temp if Origen_Destino == "imi"

drop temp 

save "$data/Transiciones/Transiciones_Enero_2007_2008_`age'_`age_plus'_`g'_sin.dta", replace 


local gru_edu = `gru_edu' + 1
local gru_edu2 = `gru_edu2' +1 

}

}









