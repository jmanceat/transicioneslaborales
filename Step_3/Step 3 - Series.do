********************************************************************************
********************************************************************************

*                       	 Step 4 - Series						           *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	 15/Mar/2020
				* Autor:		 Nicolas Mancera 
				* Modificación:  07/Jul/2021 
*/


**# Seccion 0 - Preliminaries


	clear all
	set   more off
	
* Rutas de las bases de datos 

	global rawdata  "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data"
	global data 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Data"
	global graphs 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Graphs/Ejercicios_GEIH"
	global tables 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Tables/Ejercicios_GEIH"
	global logs     "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Log_files/Ejercicios_GEIH/Transiciones"

	cd "$rawdata"
	
	cap log close 
	
	log using "${logs}/Step 4 - Series.smcl", replace 
	


**# Section 1 - Figuras generales 

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

* Average  

keep if Origen == "e" 
keep e e_before
gen diff = e_before - e 

sum diff, meanonly 
global average_diff = r(mean)

dis $average_diff 


********************************* Before RAS ***********************************

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
 

global outcomes d e emi i m oc of oj on os ot p qpd

foreach var in $outcomes {
	
	replace `var'=. if (time>=ym(2020,3) & time<=ym(2020,7)) 
}

gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1

preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Unemployment_before.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Employment_before.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Self_before.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Employers_before.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Inactivity_before.png", width(1600) height(1200) replace	

restore 


********************************** After RAS ***********************************

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
gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1


preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Unemployment.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Employment.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Self.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Employers.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/All/Transition_Rate_Inactivity.png", width(1600) height(1200) replace	

restore 





********************************************************************************
*							Section 2  - Age plots							   *
********************************************************************************



local ages "10 20 30 40 50 60"


foreach age of local ages {


local age_plus = `age' + 9


* Fix pandemic values 

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/`age'_`age_plus'/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 

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


********************************* Before RAS ***********************************

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 


local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 


local prior = `prior' + 1

}

}

gen temp = "-"
egen time_string = concat(YEAR temp MES)
gen time = monthly(time_string, "YM")
format time %tm 
 

global outcomes d e emi i m oc of oj on os ot p qpd

foreach var in $outcomes {
	
	replace `var'=. if (time>=ym(2020,3) & time<=ym(2020,7)) 
}

gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1

preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Unemployment_before_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Employment_before_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Self_before_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Employers_before_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Inactivity_before_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 


********************************** After RAS ***********************************

clear all 

local years "2020"
tokenize "Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/5  {
	
	local prior = 2019
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 


local prior = `prior' + 1

}

}

local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/`age'_`age_plus'/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 

local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/`age'_`age_plus'/transition_rate_``mes''_`prior'_`y'_`age'_`age_plus'.dta", force 

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
gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1


preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Unemployment_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Employment_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Self_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Employers_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`age'_`age_plus'/Transition_Rate_Inactivity_`age'_`age_plus'.png", width(1600) height(1200) replace	

restore 



}






********************************************************************************
*							Section 3  - Gender plots						   *
********************************************************************************



local gender "men women"


foreach g of local gender {



* Fix pandemic values 

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`g'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/`g'/transition_rate_``mes''_`prior'_`y'_`g'.dta", force 

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


********************************* Before RAS ***********************************

clear all 

local years "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"
tokenize "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/12  {
	
	local prior = 2007
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`g'.dta", force 


local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`g'.dta", force 


local prior = `prior' + 1

}

}

gen temp = "-"
egen time_string = concat(YEAR temp MES)
gen time = monthly(time_string, "YM")
format time %tm 
 

global outcomes d e emi i m oc of oj on os ot p qpd

foreach var in $outcomes {
	
	replace `var'=. if (time>=ym(2020,3) & time<=ym(2020,7)) 
}

gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1

preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Unemployment_before_`g'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Employment_before_`g'.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Self_before_`g'.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Employers_before_`g'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Inactivity_before_`g'.png", width(1600) height(1200) replace	

restore 


********************************** After RAS ***********************************

clear all 

local years "2020"
tokenize "Agosto Septiembre Octubre Noviembre Diciembre"

forval mes = 1/5  {
	
	local prior = 2019
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`g'.dta", force 


local prior = `prior' + 1

}

}

local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/temp/Transiciones/Transiciones_``mes''_`prior'_`y'_`g'.dta", force 


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
	

append using "$data/Transiciones/RAS_Output/`g'/transition_rate_``mes''_`prior'_`y'_`g'.dta", force 

local prior = `prior' + 1

}

}


local years "2021"
tokenize "Enero Febrero"

forval mes = 1/2  {
	
	local prior = 2020
	
foreach y of local years {
	

append using "$data/Transiciones/RAS_Output/`g'/transition_rate_``mes''_`prior'_`y'_`g'.dta", force 

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
gen upper = 1

* Momentos 

local primer_empleo  2011m1
local no_data_ini 	 2020m3
local no_data_fin    2020m7 
local cesante 		 2013m6
local salud_unific   2012m7
local licencias      2017m1


preserve 

keep if Origen == "d"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Unemployment_`g'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "e"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Employment_`g'.png", width(1600) height(1200) replace	

restore 

preserve 

keep if Origen == "oc"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Self_`g'.png", width(1600) height(1200) replace	

restore 



preserve 

keep if Origen == "p"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Employers_`g'.png", width(1600) height(1200) replace	

restore 


preserve 

keep if Origen == "i"

tsset time 

twoway (tsline d e i oc p, cmissing(n n n n n)  ttitle("") lcolor(red black lime blue orange)  ///        
	   title("", size(medium) color(black))  ///
	   subtitle("", size(2.8)) ytitle("Tasa de Transición" , size(small)) 	               		      ///
	   ylabel(#10, angle(horizontal) format(%9.1f) nogrid labsize(small)) 	ysc(r(0 1))	      ///
	   xtitle("", size(tiny))	tlabel(2008m1 2009m1 2010m1 2011m1 2012m1 2013m1 2014m1 2015m1 ///
	   2016m1 2017m1 2018m1 2019m1 2020m1 2021m1,  labsize(small) format(%tmCY))                	 ///
	   legend(on  rows(1) symy(1) symxsize(6)  bm(tiny)  pos(6) size(2.8)                   ///		
	   region(lcolor(black)) label(1 "Desempleo") label(2 "Empleo Asalariado") label(3 "Inactividad") ///
	   label(4 "Cuenta Propia") label(5 "Empleador")) graphregion(fcolor		  (white) style(none) color(white)        ///
	   margin(r=6 l=3 t=3 b=1)) plotregion(fcolor(white) margin(none))   note(" ", size(2.5)) ///
	   note("") ttext(0.9 `primer_empleo' "Ley 1429 de 2010:" "Ley de primer empleo" ///
	   0.8 `salud_unific' "Acuerdo 032 de 2012:" "Unificación del" "plan obligatorio en salud" ///
	   0.9 `cesante' "Ley 1636 de 2013:" "Mecanismo de protección" "al cesante"  ///
	   0.8 `licencias' "Ley 1822 de 2017:" "Aumento del periodo" "de licencias de maternidad" ///
	   0.8 `no_data_ini' "Pandemia del" "Covid-19:" "Sin Datos", color(black) size(vsmall))), ///
	   tline(`primer_empleo' `no_data_ini' `no_data_ini' `no_data_fin' `cesante' `salud_unific' `licencias', ///
	   lc(gray) lp(shortdash) lw(thin)) 
	   graph export "$graphs/Transiciones/`g'/Transition_Rate_Inactivity_`g'.png", width(1600) height(1200) replace	

restore 



}

log close 
































