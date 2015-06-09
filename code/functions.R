# ============================================================================
# Name        : functions.R
# Author      : Jason D. Miller
# Copyright   : (c) 2015, Please give a citation if you use this code
# Description : Libraries, functions, and options for parental_expenditures.R
# ============================================================================

# Libraries ---------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(car, caret, descr, devtools, doParallel, downloader, mhurdle, 
               MonetDB.R, RDSTK, reshape, R.utils, sqldf, sas7bdat, SAScii)

install.packages("sqlsurvey", 
                 repos = c( "http://cran.r-project.org", 
                            "http://R-Forge.R-project.org" ) , dep=TRUE )
require(sqlsurvey)

# Options -----------------------------------------------------------------
options("scipen"=100, "digits"=4, "monetdb.sequential" = T)
