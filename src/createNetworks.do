// Creates a log file
log using `"$logs/createNetworks.txt"', replace text name(building)

// Make sure any existing network data is cleared prior to creating new networks
cap nwclear

// Saves the file used for the analysis
use `"$analysis/kyHouseData.dta"', clear

// Indicate records that do not have any ties in the education subnetworks
bys sponsor_id (cosponsid): egen connections = total(nwwiyrwgted)

// Get the sponsor ids for individuals who do not have any connections in the network
levelsof sponsor_id if connections == 0, loc(unconnected)

// Preserves the current state of the data
preserve 

	// Creates non-education weighted network for the house
	nwfromedge sponsor_id cosponsid nwwiyrwgt, name(housenonedwgt) 
	
// Restores and preserves original data again	
restore, preserve

	// Creates non-education unweighted network for the house
	nwfromedge sponsor_id cosponsid nonedpair, name(housenonedunwgt) 

// Restores and preserves original data again	
restore, preserve

	// Loop over sponsor ids for unconnected individuals
	foreach person of loc unconnected {
	
		di `"`person'"'
	
		// Remove the unconnected individuals from the file
		drop if sponsor_id == `"`person'"' | cosponsid == `"`person'"'
		
	} // End Loop to remove unconnected nodes	

	// Creates education weighted network for the house
	nwfromedge sponsor_id cosponsid nwwiyrwgted, name(houseedwgt) 
	
// Restores and preserves original data again	
restore, preserve

	// Loop over sponsor ids for unconnected individuals
	foreach person of loc unconnected {
	
		// Remove the unconnected individuals from the file
		drop if sponsor_id == `"`person'"' | cosponsid == `"`person'"'
		
	} // End Loop to remove unconnected nodes	

	// Creates education unweighted network for the house
	nwfromedge sponsor_id cosponsid isedpair, name(houseedunwgt) 
		
// Restores the data to its original state	
restore

// Confirms that all of the networks above are accessible
nwds

// Saves the networks for the house
nwsave $analysis/houseNetworks, replace

// Makes sure that all network data is cleared from memory before constructing
// Senate networks
nwclear

// Loads the data for the Kentucky Senate Legislation
use `"$analysis/kySenateData.dta"', clear

// Indicate records that do not have any ties in the education subnetworks
bys sponsor_id (cosponsid): egen connections = total(nwwiyrwgted)

// Get the sponsor ids for individuals who do not have any connections in the network
levelsof sponsor_id if connections == 0, loc(unconnected)

// Preserves the current state of the data
preserve

	// Creates non-education weighted network for the senate
	nwfromedge sponsor_id cosponsid nwwiyrwgt, name(senatenonedwgt) keeporiginal

// Restores and preserves original data again	
restore, preserve

	// Creates non-education unweighted network for the senate
	nwfromedge sponsor_id cosponsid nonedpair, name(senatenonedunwgt) keeporiginal

// Restores and preserves original data again	
restore, preserve

	// Loop over sponsor ids for unconnected individuals
	foreach person of loc unconnected {
	
		// Remove the unconnected individuals from the file
		drop if sponsor_id == `"`person'"' | cosponsid == `"`person'"'
		
	} // End Loop to remove unconnected nodes	

	// Creates education weighted network for the senate
	nwfromedge sponsor_id cosponsid nwwiyrwgted, name(senateedwgt) keeporiginal
	
// Restores and preserves original data again	
restore, preserve

	// Loop over sponsor ids for unconnected individuals
	foreach person of loc unconnected {
	
		// Remove the unconnected individuals from the file
		drop if sponsor_id == `"`person'"' | cosponsid == `"`person'"'
		
	} // End Loop to remove unconnected nodes	

	// Creates education unweighted network for the senate
	nwfromedge sponsor_id cosponsid isedpair, name(senateedunwgt) keeporiginal
	
// Restores the data to its original state	
restore

// Confirms that all of the networks above are accessible
nwds

// Saves the networks
nwsave $analysis/senateNetworks, replace

// Close the log file
log c building
