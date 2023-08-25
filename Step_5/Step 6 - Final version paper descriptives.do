********************************************************************************
********************************************************************************

*                	Step 6 - Final version paper descriptives		           *

********************************************************************************
********************************************************************************

/*
				* Creacion: 	 02/Jun/2022
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
	global graphs 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Graphs/Ejercicios_GEIH/Transiciones"
	global tables 	"/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Output/Tables/Ejercicios_GEIH/Transiciones"
	global logs     "/Users/nicolasmancera/Dropbox/Trayectorias_Laborales_Colombia/Data_analysis/Log_files/Ejercicios_GEIH/Transiciones"

	cd "$data/Transiciones/stylized_facts_data"
	
	cap log close 
	
	log using "${logs}/Step 6 - Final version paper descriptives.smcl", replace 
	
********************************************************************************
*						Section 1  - All 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_all", replace 

	
********************************************************************************
*						Section 2  - Men 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_men", replace 


********************************************************************************
*						Section 3  - Women 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_women", replace 


********************************************************************************
*						Section 4  - Con 						   *
********************************************************************************

local education "con"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_con", replace 



********************************************************************************
*						Section 5  - Sin 						   *
********************************************************************************

local education "sin"

foreach educ of local education {
	
local ages "20 30 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_sin", replace 




********************************************************************************
*						Section 6  - 20_29 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "20" 

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_20_29", replace 



********************************************************************************
*						Section 7  - 30_39 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "30" 

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_30_39", replace 


********************************************************************************
*						Section 8  - 40_49 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "40" 

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_40_49", replace 



********************************************************************************
*						Section 9  - 50_59 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "50" // 20 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_50_59", replace 



********************************************************************************
*						Section 10  - 60_69 						   *
********************************************************************************

local education "con sin"

foreach educ of local education {
	
local ages "60" // 20 40 50 60"

foreach age of local ages {
	
local age_plus = `age' + 9

local gender "men women" 

foreach g of local gender {

local years  "2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020"   
local month	 "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"

foreach  mes of local month  {
	
	local prior = 2007
	
foreach y of local years {

append using "${data}/Transiciones/RAS_Output/age_gender_education/transition_matrix_`mes'_`prior'_`y'_`age'_`age_plus'_`g'_`educ'.dta", force 

local prior = `prior' + 1

				}
			}
		}
	}	

}


keep col_tot Origen
collapse (mean) col_tot, by(Origen)
save "${data}/20220602_descriptives_60_69", replace 


use "${data}/20220602_descriptives_all", clear 
rename col_tot all  
merge 1:1 Origen using "${data}/20220602_descriptives_men", nogen keep(3)
rename col_tot men   
merge 1:1 Origen using "${data}/20220602_descriptives_women", nogen keep(3)
rename col_tot women  
merge 1:1 Origen using "${data}/20220602_descriptives_con",  nogen keep(3)
rename col_tot con  
merge 1:1 Origen using "${data}/20220602_descriptives_sin", nogen keep(3)
rename col_tot sin  
merge 1:1 Origen using "${data}/20220602_descriptives_20_29", nogen keep(3)
rename col_tot a20_29  
merge 1:1 Origen using "${data}/20220602_descriptives_30_39", nogen keep(3)
rename col_tot a30_39  
merge 1:1 Origen using "${data}/20220602_descriptives_40_49", nogen keep(3)
rename col_tot a40_49  
merge 1:1 Origen using "${data}/20220602_descriptives_50_59", nogen keep(3)
rename col_tot a50_59
merge 1:1 Origen using "${data}/20220602_descriptives_60_69", nogen keep(3)
rename col_tot a60_69  


save "${data}/20220602_descriptives_main", clear 

log close 






