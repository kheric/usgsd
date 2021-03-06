# analyze survey data for free (http://asdfree.com) with the r language
# new york city housing and vacancy survey
# 2002-2014

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NYCHVS/" )
# years.to.download <- c( 2002 , 2005 , 2008 , 2011 , 2014 )
# source_url( "https://raw.githubusercontent.com/ajdamico/usgsd/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/2002%20-%202011%20-%20download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


###############################################################
# download most recent decade of NYC Housing & Vacancy Survey #
# files with R then save every file as an R data frame (.rda) #
###############################################################


# set your working directory.
# all NYCHVS files will be stored here
# after downloading and importing it.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/NYCHVS/" )
# ..in order to set your current working directory


# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "downloader" ) )


# uncomment this line to download all available data sets
# uncomment this line by removing the `#` at the front
# years.to.download <- c( 2002 , 2005 , 2008 , 2011 , 2014 )

# uncomment to only download the most current available year
# years.to.download <- 2011
# but why not just download them all?  ;)


library(downloader)		# downloads and then runs the source() function on scripts from github
library(SAScii) 		# load the SAScii package (imports ascii data with a SAS script)


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


# initiate a function that will clean up doubly-embedded /* */ - which are allowed in SAS but not SAScii
# remove double embedded /* */ in the code, which the SAScii package does not like
nychvs.sas.cleanup <-
	function( z ) {
	
		# create a temporary file on the local disk
		cleaned.sas.input.script <- tempfile()

		# read the script into memory
		y <- readLines( z )
		
		# also, while we're removing stuff we don't like, throw out `TAB` characters
		z <- gsub( "\t" , " " , SAS.uncomment( SAS.uncomment( y , "/*" , "*/" ) , "/*" , "*/" ) )
		
		# get rid of this crap
		z <- gsub( "comma([0-9])\\.([0-9])" , "\\1.\\2" , z )

		# re-write the furman SAS file into an uncommented SAS script
		writeLines( z , cleaned.sas.input.script )
	
		# return the filepath of the saved script on the local disk
		cleaned.sas.input.script
	}
	



# create the temporary file location to download all files
tf <- tempfile()

# loop through each year requested by the user
for ( year in years.to.download ){


	# create three year-specific variables:
	
	# the last two digits of the current year
	subyear <- substr( year , 3 , 4 )
	
	# '05' and `2005` if the year is 2002 --
	# because those files are stored in the 2005 directory
	# of the census bureau's website
	latesubyear <- ifelse( year == 2002 , '05' , subyear )
	lateyear <- ifelse( year == 2002 , 2005 , year )

	# they started naming things differently in 2011
	if ( year == 2014 ) {
		filetypes <- c( 'occ' , 'vac' ) 
	} else {
		if( year == 2011 ) {
			filetypes <- c( 'occ' , 'vac' , 'pers' ) 
		} else {
			filetypes <- c( 'occ' , 'vac' , 'per' , 'ni' )
		}
	}
	
	web <- ifelse( year > 2005 , '_web' , '' )
	
	prefix <- ifelse( year > 2008 , paste0( "/uf_" , latesubyear ) , paste0( "/lng" , latesubyear ) )
	
	# loop through each available filetype
	for ( filetype in filetypes ){

		# construct the url of the file to download #

		census.url <-
			paste0( 
				"http://www.census.gov/housing/nychvs/data/" , 
				lateyear , 
				prefix , 
				"_" , 
				filetype , 
				ifelse( year > 2008 , '' , subyear ) , 
				ifelse( 
					year == 2011 & filetype %in% c( 'occ' , 'pers' ) , 
					'_rev' , 
					web 
				) , 
				ifelse( 
					year == 2011 & filetype == 'vac' , 
					".txt" , 
					".dat" 
				)
			)

		# the `census.url` object now contains the complete filepath
			
		# construct the url of the SAS importation script #
		
		if( year < 2014 ){
			# massive thanx to http://furmancenter.org for providing these.
			furman.sas.import.script <- 
				paste( 
					'https://raw.github.com/ajdamico/usgsd/master/New%20York%20City%20Housing%20and%20Vacancy%20Survey/NYU%20Furman%20Center%20SAS%20code/hvs' , 
					subyear , 
					filetype , 
					'load.sas' , 
					sep = "_" 
				)

			# save the sas import instructions to the local disk..
			download( furman.sas.import.script , tf )
			
			beginline <- 1
			
		} else {

			# set the import script begin lines.
			if( filetype == 'occ' ) {
				beginline <- 9 
			} else if ( filetype == 'vac' ) {
				beginline <- 412 
			} else stop( "this filetype hasn't been implemented yet." )
			
			# download the new sas scripts provided.
			download( 
				paste0( 
					"http://www.census.gov/housing/nychvs/data/" , 
					year , 
					"/sas_import_program.txt" 
				) , 
				tf 
			)
					
		}

		# ..and clean it up using the function defined above
		cleaned.sas.script <- nychvs.sas.cleanup( tf )

		# read the file into a data frame
		x <- 
			read.SAScii( 
				census.url ,
				cleaned.sas.script ,
				beginline = beginline
			)

		# set all column names to lowercase (since R is case-sensitive
		names( x ) <- tolower( names( x ) )
		
		# add a column of all ones
		x$one <- 1
		
		# household weights need to be divided by one hundred thousand,
		# person-weights need to be divided by ten for more recent years
		# but starting in 2014, this was no longer a problem.
		if ( year < 2014 ){
			if ( !( filetype %in% c( 'per' , 'pers' ) ) ) {
				x$hhweight <- x$hhweight / 10^5 
			} else if ( year > 2005 ) x$perwgt <- x$perwgt / 10
		}
		
		# save the data frame `x` to whatever the current filetype is
		assign( filetype , x )

		# then remove `x`..
		rm( x )

		# ..and clear up RAM
		gc()

	}

	# save all available filetypes to the local disk in your current working directory
	# (defined at the start of this program)
	save( list = filetypes , file = paste0( "nychvs" , subyear , ".rda" ) )

	# remove 'em all from memory..
	rm( list = filetypes )
	
	# ..and clear up RAM again
	gc()
	
}


# print a reminder: set the directory you just saved everything to as read-only!
message( paste( "all done.  you should set" , getwd() , "read-only so you don't accidentally alter these files." ) )

# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
