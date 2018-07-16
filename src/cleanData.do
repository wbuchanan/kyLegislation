// Creates a log file
log using `"$logs/dataCleaning.txt"', replace text name(cleaning)

// Set macro with file names
loc files : dir `"$raw"' files "*.csv", respect

// Loop over the files
foreach f of loc files {

	// Remove the file suffix from the file name
	loc file : subinstr loc f ".csv" "", all
	
	// Read in the file
	import delimited using `"$raw/`file'.csv"', varn(1) case(l) clear
	
	// Logic for bills file
	if `"`file'"' == "bills" {
	
		// Create an indicator for education bills by searching for :
		// educ
		// school
		// schools
		// epsb
		// kde
		g byte ised = ustrregexm(title, "(educ)|(schools?)|(epsb)|(kde)", 1)
	
		// Create a year indicator
		g int year = 2018
		
		// Keep only the necessary subset of the data
		keep bill_number ised bill_id year

		// Create an indicator for the house chamber bills
		g byte house = substr(bill_number, 1, 1) == "H"

		// Create an indicator for the senate chamber bills
		g byte senate = substr(bill_number, 1, 1) == "S"
		
		// Drop all records that are not bills (e.g., resolutions, chamber rules)
		drop if !ustrregexm(bill_number, "[SH]B[0-9]+")

		// Sorts the data
		sort year house senate bill_id

	} // End Logic for Bills file
	
	// Logic for the people file
	else if `"`file'"' == "people" {
	
		// Make sponsor id variable a string
		tostring sponsor_id, replace
	
		// Create a person ID
		g peopleid = sponsor_id
		
		// Create indicator for the house
		g byte house = role == "Rep"
		
		// Create indicator for the senate
		g byte senate = role == "Sen"
		
		// Set the year value
		g int year = 2018
		
		// Keep smallest subset of variables possible
		keep name party role district house senate sponsor_id peopleid year

		// Make role numeric
		replace role = cond(role == "Rep", "0", "1")

		// Defines value labels
		la def role 0 "Representative" 1 "Senator", modify

		// Make the party variable numeric
		replace party = cond(party == "D", "1", cond(party == "I", "-1", "0"))

		// Define value labels
		la def party 1 "Democrat" 0 "Republican" -1 "Independent", modify

		// Strip house/senate designation from districts
		replace district = ustrregexra(district, "(HD-)|(SD-)|(NA)", "")

		// Create variable used to join the data later
		g _nodelab = "_" + sponsor_id
		
		// Loop over variables that need to get cast as numeric
		destring role party district, replace 
		
		// Create node positions for later
		g byte nodepos = cond(party == 1, 2, 7)

		// Apply value labels
		la val party party
		la val role role

		// Drop any duplicate records
		duplicates drop
		
		// Test the primary key assumption
		isid sponsor_id year
		
		// Sort the data
		sort sponsor_id year

	} // End Logic for the People files
	
	// Logic for sponsorship dataset
	else if `"`file'"' == "sponsors" {
	
		// Add a year indicator to the data
		g int year = 2018
		
		// Add indicator for sponsorship to the dataset
		g byte didsponsor = 1
		
		// Make sure sponsor id field is string
		tostring sponsor_id, replace
	
	} // End ELSE block for sponsors dataset
	
	// Optimize the storage of the data
	compress
	
	// Save these data
	save `"$clean/`file'.dta"', replace
	
} // End Loop over the files

// Load the people data set to construct the person bill data set
use `"$clean/people.dta"', clear

// Preserve the state of the people data set
preserve

	// Keep only the house members
	keep if house == 1
	
	// Save a version of the file for only the house members
	save `"$clean/houseMembers.dta"', replace
	
// Restore the data set and preserve again
restore, preserve

	// Keep only the senate members
	keep if house != 1
	
	// Save a version of the file for only the senate members
	save `"$clean/senateMembers.dta"', replace
	
// Restore the data to original state
restore

// Don't retain the _nodelab variable for this part of the process
drop _nodelab

// Preserve these data in memory
preserve

	// Join all bill data to all individuals in each chamber
	joinby year house senate using `"$clean/bills.dta"'
	
	// Add note to data set
	note : `"people file joined with bills using joinby year house senate using `"$clean/bills.dta"'"'
	
	// Make sure sponsor ID is still string
	tostring sponsor_id, replace
	
	// Join the sponsorship data to this file
	merge 1:1 sponsor_id year bill_id using `"$clean/sponsors.dta"', keep(1 3) nogen

	// Save the file
	save `"$clean/sponsorBills.dta"', replace
	
	// Loop over sponsor data
	foreach d in name party role district {
	
		// Rename the data
		rename `d' cospons`d'
		
	} // End Loop over sponsor data
	
	// Add variable labels
	la var cosponsname "Cosponsoring Legislator Name"
	la var cosponsparty "Cosponsoring Legislator Party" 
	la var cosponsrole "Cosponsoring Legislator Chamber"
	la var cosponsdistrict "Cosponsoring Legislator District"

	// Add another note
	note : "This version of the file is modified to indicate cosponsors"
		
	// Renames some of the variables
	rename (sponsor_id didsponsor)(cosponsid didcosponsor)
	
	// Drops variables that are not needed in the cosponsorship file
	drop bill_number ised peopleid
	
	// Save the data in a new file
	save `"$clean/cosponsorsBills.dta"', replace
	
// Restore the data
restore

// Load the file with the sponsors and bill indicators
use `"$clean/sponsorBills.dta"', clear

// Drops the people ID
drop peopleid

// Joins the data with the cosponsors 
joinby bill_id year house senate using `"$clean/cosponsorsBills.dta"'

// Drops all duplicate records
duplicates drop

// Sets the cosponsorship indicators to use non-missing values
foreach v in didcosponsor didsponsor {

	// Sets the values to 0 if they are missing
	replace `v' = 0 if mi(`v')
	
} // End Loop over the cosponsorship indicators

// Label the variables in the data set
la var sponsor_id "Legiscan Person ID"
la var name "Legislator Name"
la var party "Legislator Party"
la var role "Legislator Chamber"
la var district "Legislator District"
la var house "Indicator for House Bills/Resolutions"
la var senate "Indicator for Senate Bills/Resolutions"
la var year "Legislative Session Year"
la var bill_number "KY Legislation Identifier"
la var bill_id "Legiscan Unique ID for KY Legislation"
la var ised "Indicator of whether or not the bill is education related"
la var didsponsor "Indicator of whether or not the legislator sponsored the bill"
la var cosponsid "Legiscan Person ID for Bill Cosponsors"
la var didcosponsor "Indicator of whether or not the cosponsor cosponsored the bill"

/*

Check things from this point down to make sure the adjacency matrix gets 
constructed correctly.  Make sure that nwcommands are installed and available
in the Stata instance.

*/

// Drops cases where the individual is listed as sponsor and cosponsor
drop if name == cosponsname

// Creates a dyad indicator.  These can be used to create weights
// Value should be 1 if name and cosponsname both sponsored the bill
// Value should be -1 if name sponsored the bill and cosponsname did not sponsor
// Value should be 0 if neither name nor cosponsname sponsored the bill
// Attempting to only map positive ties
bys sponsor_id bill_id (cosponsid): g byte dyad =							 ///   
cond(sponsor_id == cosponsid, ., cond(didsponsor + didcosponsor == 2, 1, 0))   
// cond(didsponsor + didcosponsor == 1, -1, 0)))

// Sort once for the next two operations
sort sponsor_id cosponsid year

// Creates a within year weight for each pair of legislators
by sponsor_id cosponsid year: egen nwwiyrwgt = total(dyad)

// Creates a within year weight for each pair of legislators for education bills
by sponsor_id cosponsid year: egen nwwiyrwgted = total(dyad) if ised == 1

// Sort once for the next two operations
sort sponsor_id cosponsid

// Creates a between year weight for each pair of legislators
by sponsor_id cosponsid: egen nwbeyrwgt = total(dyad)

// Creates a between year weight for each pair of legislators for education bills
by sponsor_id cosponsid: egen nwbeyrwgted = total(dyad) if ised == 1

// Subtract education legislation from the total legislation measures
replace nwwiyrwgt = nwwiyrwgt - nwwiyrwgted
replace nwbeyrwgt = nwbeyrwgt - nwbeyrwgted

// Generate binary indicator for unweighted network for non-education legislation
g byte nonedpair = nwwiyrwgt > 0

// Generate binary indicator for unweighted network for education legislation
g byte isedpair = nwwiyrwgted > 0

// Add variable labels to the variables just created
la var dyad "Cosponsorship Dyad Indicator"
la var nwwiyrwgt "Within year network weight"
la var nwwiyrwgted "Within year network weight for education legislation"
la var nwbeyrwgt "Between year network weight"
la var nwbeyrwgted "Between year network weight for education legislation"
la var nonedpair "Binary Indicator for Non-Education Legislative Ties"
la var isedpair "Binary Indicator for Education Legislative Ties"

// Compress the data set
compress

// Keeps a subset of the data
keep sponsor_id name party district house year bill_number bill_id ised 	 ///   
didsponsor cosponsname cosponsparty cosponsdistrict didcosponsor dyad 		 ///   
nwwiyrwgt nwbeyrwgt nwwiyrwgted nwbeyrwgted cosponsid nonedpair isedpair	 ///   
nodepos

// Saves the full 
save `"$clean/sponsorBillPeople.dta"', replace

// Only keeps the records needed to construct the adjacency matrix
keep if ised == 1

// Drops other variables that are unnecessary
drop ised bill_number bill_id didsponsor dyad didcosponsor 

// Drop duplicated records from 70,103,624 records to 201,280 records 
duplicates drop

// Test primary key assumption
isid sponsor_id cosponsid year

// Sorts the data to make it faster to subset later
sort year house sponsor_id cosponsid

// Preserve the current state of the data
preserve

	// Keep only records for the house
	keep if house == 1

	// Saves the file used for the analysis
	save `"$analysis/kyHouseData.dta"', replace

// Restore the dataset and preserve again
restore, preserve
	
	// Keep only records for the house
	keep if house == 0

	// Saves the file used for the analysis
	save `"$analysis/kySenateData.dta"', replace

// Restore the dataset and preserve again
restore, preserve

	// Saves the file used for the analysis
	save `"$analysis/kyLegislationData.dta"', replace

// Restore the dataset to original state
restore
		
// Close the log file
log c cleaning		
		
