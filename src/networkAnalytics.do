// Creates a log file
log using `"$logs/analysis.txt"', replace text name(analyze)

/*

For whatever reason, it doesn't seem to be possible to save any covariates or 
other metadata with the network in a way that it gets retained.  That said, the 
only thing that should be needed in any of the networks is the party affiliation.
To add that, just use one of the commands below depending on the networks being
used at the time:

*/

// Join Senate party affiliation data
// merge 1:1 _nodelab using `"$clean/senateMembers.dta"', nogen keepus(name party)

// Join House party affiliation data
// merge 1:1 _nodelab using `"$clean/houseMembers.dta"', nogen keepus(name party)

// Make sure any existing network data is cleared prior to creating new networks
cap nwclear

// Open log file to store results
log using `"$results/analysisLogs/houseResults.txt"', replace text name(house)

// Loads networks into Mata and also adds Stata variables in not useful format
nwuse `"$analysis/houseNetworks"', nwclear

// Need to load each network individually and then join the attributes to the
// data in order to label the nodes and look at party affiliations
foreach network in $housewgt $houseunwgt {

	// Clear the data out of Stata's memory
	clear

	// Display the network being iterated on
	di as res _n(2) "The following results are for the network named `network'." _n(2)

	// Loads the network
	nwload `network'

	// Joins the name and party attributes
	$mrghouse
		
	// Print info prior to results
	di as res _n "Summary of the Network - `network'" _n
	
	// Summary of the network
	nwsummarize `network'

	// Iterate over the house leadership macros
	foreach leader in $houseldrshp {
	
		// Execute the command for this leader
		$`leader'
		
		// Set the value of the node id for this leader
		loc leaderid `r(mean)'

		// Test whether or not this individual has any neighbors
		if `r(N)' != 0 {
	
			// Print info prior to results
			di as res _n "Estimation of Neighbors of the House leader `leader' Based on the Network - `network'" _n

			// Extract the neighbors of this leader
			nwneighbor `network', ego(`leaderid')
			
		} // End IF Block for node with neighbors
		
		// Or print a message with info
		else di as err "House leader `leader' has no neighbors in the network `network'"
	
	} // End Loop over the leadership positions to estimate neighbors
	
	// Print info prior to results
	di as res _n "Estimation of Reachability Network Based On - `network'" _n
	
	// Estimate reachability network from this network
	nwreach `network', name(`network'_reach) 

	// Print info prior to results
	di as res _n "Summary of the Reachability Network Estimated From - `network'" _n
	
	// Summarize the reachability of the network
	nwsummarize `network'_reach, matonly
	
	// Print info prior to results
	di as res _n "Estimation of Closeness Measures for the Network - `network'" _n
	
	// Estimate closeness metrics
	nwcloseness `network', generate(close far near) unconnected(max)
	
	// Estimate Katz distance metric
	// nwkatz `network', generate(katz)

	// Print info prior to results
	di as res _n "Estimation of Degree Centrality Measures for the Network - `network'" _n
	
	// Estimate degree centrality metric for unweighted networks
	if regexm(`"`network'"', "un") nwdegree `network', generate(degree) isolates standardize

	// Estimates degree centrality metric for weighted networks
	else nwdegree `network', generate(degree) isolates standardize valued
	
	// Print info prior to results
	di as res _n "Estimation of Betweenness Centrality Measures for the Network - `network'" _n
	
	// Estimate betweenness centrality
	nwbetween `network', generate(between) standardize
	
	// Print info prior to results
	di as res _n "Estimation of Geodesic Paths for the Network - `network'" _n
	
	// Estimates shortest paths between nodes
	nwgeodesic `network', unconnected(max) 
	
	// Print info prior to results
	di as res _n "Estimation of the Number of Components in the Network - `network'" _n
	
	// Estimates number of components in network
	nwcomponents `network', generate(`network'_component)
	
	// Print info prior to results
	di as res _n "Estimation of the Largest Component in the Network - `network'" _n
	
	// Estimates members of the largest component
	nwcomponents `network', lgc generate(`network'_lgc)
	
	// Print info prior to results
	di as res _n "Estimation of Eigenvector Centrality within the Network - `network'" _n

	// Estimates the eigenvector centrality
	nwevcent `network', generate(`network'_eigencent)
		
} // End Loop over house networks

loc wgt1 `: word 1 of $housewgt'
loc wgt2 `: word 2 of $housewgt'
loc unwgt1 `: word 1 of $houseunwgt'
loc unwgt2 `: word 2 of $houseunwgt'

// Print info about networks for correlation
di as res _n "Correlation between the `wgt1' and `wgt2' networks" _n 

// Estimate correlations between Non-Education and Education related networks in
// the house with weighted ties
cap noi nwcorrelate $housewgt, permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt1'_`wgt2'-correlation.gph"', replace

// Print info about networks for correlation
di as res _n "Correlation between the `unwgt1' and `unwgt2' networks" _n 

// Same as above but with unweighted ties
cap noi nwcorrelate $houseunwgt, permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt1'_`unwgt2'-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the weighted non-education network
nwload `wgt1'

// Join the political party data
$mrghouse

// Print info about correlation
di as res _n "Correlation between `wgt1' and political party affiliation" _n 

// Correlation between the house non-education weighted network and political party
cap noi nwcorrelate `wgt1', attribute(party) permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt1'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the weighted education network
nwload `wgt2'

// Join the political party data
$mrghouse

// Print info about correlation
di as res _n "Correlation between `wgt2' and political party affiliation" _n 

// Correlation between the house education weighted network and political party
cap noi nwcorrelate `wgt2', attribute(party) permutations(5000)
	
// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt2'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the unweighted non-education network
nwload `unwgt1'

// Join the political party data
$mrghouse

// Print info about correlation
di as res _n "Correlation between `unwgt1' and political party affiliation" _n 

// Correlation between the house non-education unweighted network and political party
cap noi nwcorrelate `unwgt1', attribute(party) permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt1'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the unweighted education network
nwload `unwgt2'

// Join the political party data
$mrghouse

// Print info about correlation
di as res _n "Correlation between `unwgt2' and political party affiliation" _n 

// Correlation between the house education unweighted network and political party
cap noi nwcorrelate `unwgt2', attribute(party) permutations(5000)
	
// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt2'_party-correlation.gph"', replace

// Save new file with all the networks generated from the analysis
nwsave $analysis/houseAnalyzedNetworks, replace

// Drop all networks from memory
nwclear

// Close the log file
log c house

// Open log file to store results
log using `"$results/analysisLogs/senateResults.txt"', replace text name(senate)
	
// Loads networks into Mata and also adds Stata variables in not useful format
nwuse `"$analysis/senateNetworks"', nwclear

// Need to load each network individually and then join the attributes to the
// data in order to label the nodes and look at party affiliations
foreach network in $senatewgt $senateunwgt {

	// Clear the data out of Stata's memory
	clear

	// Display the network being iterated on
	di as res "The following results are for the network named `network'." _n

	// Loads the network
	nwload `network'

	// Joins the name and party attributes
	$mrgsenate
	
	// Print info prior to results
	di as res _n "Summary of the Network - `network'" _n
	
	// Summary of the network
	nwsummarize `network'

	// Iterate over the senate leadership macros
	foreach leader in $senateldrshp {
	
		// Execute the command for this leader
		$`leader'
		
		// Set the value of the node id for this leader
		loc leaderid `r(mean)'
	
		// Test whether or not this individual has any neighbors
		if `r(N)' != 0 {
	
			// Print info prior to results
			di as res _n "Estimation of Neighbors of the Senate leader `leader' Based on the Network - `network'" _n

			// Extract the neighbors of this leader
			nwneighbor `network', ego(`leaderid')
			
		} // End IF Block for node with neighbors
		
		// Or print a message with info
		else di as err "Senate leader `leader' has no neighbors in the network `network'"

	} // End Loop over the leadership positions to estimate neighbors
	
	// Print info prior to results
	di as res _n "Estimation of Reachability Network Based On - `network'" _n
	
	// Estimate reachability network from this network
	nwreach `network', name(`network'_reach) 

	// Print info prior to results
	di as res _n "Summary of the Reachability Network Estimated From - `network'" _n
	
	// Summarize the reachability of the network
	nwsummarize `network'_reach, matonly
	
	// Print info prior to results
	di as res _n "Estimation of Closeness Measures for the Network - `network'" _n
	
	// Estimate closeness metrics
	nwcloseness `network', generate(close far near) unconnected(max)
	
	// Estimate Katz distance metric
	// nwkatz `network', generate(katz)

	// Print info prior to results
	di as res _n "Estimation of Degree Centrality Measures for the Network - `network'" _n
	
	// Estimate degree centrality metric for unweighted networks
	if regexm(`"`network'"', "un") nwdegree `network', generate(degree) isolates standardize

	// Estimates degree centrality metric for weighted networks
	else nwdegree `network', generate(degree) isolates standardize valued
	
	// Print info prior to results
	di as res _n "Estimation of Betweenness Centrality Measures for the Network - `network'" _n
	
	// Estimate betweenness centrality
	nwbetween `network', generate(between) standardize
	
	// Print info prior to results
	di as res _n "Estimation of Geodesic Paths for the Network - `network'" _n
	
	// Estimates shortest paths between nodes
	nwgeodesic `network', unconnected(max) 
	
	// Print info prior to results
	di as res _n "Estimation of the Number of Components in the Network - `network'" _n
	
	// Estimates number of components in network
	nwcomponents `network', generate(`network'_component)
	
	// Print info prior to results
	di as res _n "Estimation of the Largest Component in the Network - `network'" _n
	
	// Estimates members of the largest component
	nwcomponents `network', lgc generate(`network'_lgc)
	
	// Print info prior to results
	di as res _n "Estimation of Eigenvector Centrality within the Network - `network'" _n

	// Estimates the eigenvector centrality
	nwevcent `network', generate(`network'_eigencent)
	
} // End Loop over house networks

loc wgt1 `: word 1 of $senatewgt'
loc wgt2 `: word 2 of $senatewgt'
loc unwgt1 `: word 1 of $senateunwgt'
loc unwgt2 `: word 2 of $senateunwgt'

// Print info about networks for correlation
di as res _n "Correlation between the `wgt1' and `wgt2' networks" _n 

// Estimate correlations between Non-Education and Education related networks in
// the senate with weighted ties
cap noi nwcorrelate `wgt1' `wgt2', permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt1'_`wgt2'-correlation.gph"', replace

// Print info about networks for correlation
di as res _n "Correlation between the `unwgt1' and `unwgt2' networks" _n 

// Same as above but with unweighted ties
cap noi nwcorrelate `unwgt1' `unwgt2', permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt1'_`unwgt2'-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the weighted non-education network
nwload `wgt1'

// Join the political party data
$mrgsenate

// Print info about correlation
di as res _n "Correlation between `wgt1' and political party affiliation" _n 

// Correlation between the senate non-education weighted network and political party
cap noi nwcorrelate `wgt1', attribute(party) permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt1'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the weighted education network
nwload `wgt2'

// Join the political party data
$mrgsenate

// Print info about correlation
di as res _n "Correlation between `wgt2' and political party affiliation" _n 

// Correlation between the senate education weighted network and political party
cap noi nwcorrelate `wgt2', attribute(party) permutations(5000)
	
// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`wgt2'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the unweighted non-education network
nwload `unwgt1'

// Join the political party data
$mrgsenate

// Print info about correlation
di as res _n "Correlation between `unwgt1' and political party affiliation" _n 

// Correlation between the senate non-education unweighted network and political party
cap noi nwcorrelate `unwgt1', attribute(party) permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt1'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Load the unweighted education network
nwload `unwgt2'

// Join the political party data
$mrgsenate

// Print info about correlation
di as res _n "Correlation between `unwgt2' and political party affiliation" _n 

// Correlation between the senate education unweighted network and political party
cap noi nwcorrelate `unwgt2', attribute(party) permutations(5000)

// Saves the correlation visualization
cap noi gr save `"$results/graphs/stata/`unwgt2'_party-correlation.gph"', replace

// Clear the data out of Stata's memory
clear

// Save new file with all the networks generated from the analysis
nwsave $analysis/senateAnalyzedNetworks, replace
		
// Close the log file
log c senate	

// Close the main log file
log c analyze
