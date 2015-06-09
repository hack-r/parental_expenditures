# ============================================================================
# Name        : data.R
# Author      : Jason D. Miller
# Copyright   : (c) 2015, Please give a citation if you use this code
# Description : Data for parental_expenditures.R... or, more precisely, ALL
#                ACS public microdata
# ============================================================================

#setwd("..//data")

# NOTE: You'll need to install MonetDB (which is free) to run this script
#       https://www.monetdb.org/downloads/Windows/Oct2014-SP3/

options( "monetdb.sequential" = TRUE )
single.year.datasets.to.download <- 2005:2013
three.year.datasets.to.download  <- 2007:2013
five.year.datasets.to.download   <- 2009:2013

url <- "https://raw.github.com/ajdamico/usgsd/master/American%20Community%20Survey/download%20all%20microdata.R"
source_url(url , prompt = FALSE , echo = TRUE )
