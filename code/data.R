# ============================================================================
# Name        : data.R
# Author      : Jason D. Miller
# Copyright   : (c) 2015, Please give a citation if you use this code
# Description : Data for parental_expenditures.R
# ============================================================================

# Consumer Expenditure Survey ---------------------------------------------
if(CES.refresh){
  years.to.download <- 2014:1996
  
  # create the temporary file location to download all files
  tf <- tempfile()
  
  # loop through each year requested by the user
  for ( year in years.to.download ){
    
    # year-specific output directory
    output.directory <- paste0( getwd() , "/" , year , "/" )
    
    # if the year-specific output directory doesn't exist, create it
    try( dir.create( output.directory ) , silent = T )
    
    # determine the exact path to the current year of microdata on the bureau of labor statistics ftp site
    # for each of the four main consumer expenditure public use microdata files
    intrvw.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/intrvw" , substr( year , 3 , 4 ) , ".zip" )
    expn.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/expn" , substr( year , 3 , 4 ) , ".zip" )
    diary.ftp <- paste0( "http://www.bls.gov/cex/pumd/data/stata/diary" , substr( year , 3 , 4 ) , ".zip" )
    docs.ftp <- paste0( "http://www.bls.gov/cex/pumd/documentation/documentation" , substr( year , 3 , 4 ) , ".zip" )
    
    # loop through the interview, expenditure, diary, and documentation files and..
    # download each to a temporary file
    # unzip each to a directory within the current working directory
    # save in each of the requested formats
    for ( fn in c( "intrvw" , "expn" , "diary" , "docs" ) ){
      
      # filetype-specific output directory
      output.directory <- paste0( getwd() , "/" , year , "/" , fn )
      
      # if the filetype-specific output directory doesn't exist, create it
      try( dir.create( output.directory ) , silent = T )
      
      # copy over the filetype-specific ftp path
      ftp <- get( paste( fn , "ftp" , sep = "." ) )
      
      # download the filetype-specific zipped file
      # and save it as the temporary file
      download.file( ftp , tf , mode = 'wb' )
      
      # unzip all of the files in the downloaded .zip file into the current working directory
      # then save all of their unzipped locations into a character vector called 'files'
      files <- unzip( tf , exdir = output.directory )
      # note that this saves *all* of the files contained in the .zip
      
      # loop through each of the dta files and (depending on the conversion options set above) save files in necessary formats
      
      # identify dta files
      dta.files <- files[ grep( '\\.dta' , files ) ]
      
      # loop through a character vector containing the complete filepath
      # of each of the dta files downloaded to the local disk..
      for ( i in dta.files ){
        
        # figure out where the final '/' lies in the string
        sl <- max( gregexpr( "\\/" , i )[[1]] )  	
        
        # use that to figure out the filename (without the directory)
        dta.fn <- substr( i , sl + 1 , nchar( i ) ) 
        
        # figure out where the last '.' lies in the string
        dp <- max( gregexpr( "\\." , i )[[ 1 ]] )
        
        # use that to figure out the filename (without the directory or the extension)
        df.name <- substr( i , sl + 1 , dp - 1 )
        
        # if the user requests that the file be converted to an R data file (.rda) or comma separated value file (.csv)
        # then the file must be read into r
        if ( rda | csv ){
          
          # read the current stata-readable (.dta) file into R
          # save it to an object named by what's contained in the df.name character string
          assign( df.name , read.dta( i ) )
          
          # if the user requests saving the file as an R data file (.rda), save it immediately
          if ( rda ) save( list = df.name , file = paste0( output.directory , "/" , df.name , ".rda" ) )
          
          # if the user requests saving the file as a comma separated value file (.csv), save it immediately
          if ( csv ) write.csv( get( df.name ) , , file = paste0( output.directory , "/" , df.name , ".csv" ) )
          
          # since the file has been read into RAM, it should be deleted as well
          rm( list = df.name )
          
          # clear up RAM
          gc()
          
        }
        
        # if the user did not request that the file be stored as a stata-readable file (.dta),
        # then delete the original file from the local disk
        if ( !dta ) file.remove( i )
        
      }
    }
  }
  
  folders <- dir()
  for (i in 1:length(folders)){
    setwd(folders[i])
    filenames  <- list.files("diary", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    filenames  <- list.files("expn", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    filenames  <- list.files("intrvw", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    setwd("..")
  }
}

if(CES.saved){
  tmp <- getwd()
  tmp <- sub("/code", "", tmp) # Ensure correct WD
  tmp <- sub("/data", "", tmp) # Ensure correct WD
  setwd(tmp)
  folders <- dir("data")
  for (i in 1:length(folders)){
    setwd("data")
    setwd(folders[i])
    filenames  <- list.files("diary", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    filenames  <- list.files("expn", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    filenames  <- list.files("intrvw", pattern="*.rda", full.names=T)
    for(i in 1:length(filenames)){load(filenames[i])}
    setwd(tmp)
  }
}

# ACS ---------------------------------------------------------------------
# NOTE: This is supplementary, in case we wish to expand the scope of the
#       original analysis
# NOTE: You'll need to install MonetDB (which is free) to run this script
#       https://www.monetdb.org/downloads/Windows/Oct2014-SP3/
if(ACS){
  single.year.datasets.to.download <- 2005:2013
  three.year.datasets.to.download  <- 2007:2013
  five.year.datasets.to.download   <- 2009:2013
  
  url <- "https://raw.github.com/ajdamico/usgsd/master/American%20Community%20Survey/download%20all%20microdata.R"
  source_url(url , prompt = FALSE , echo = TRUE )
}
