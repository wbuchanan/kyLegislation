/*

I'm not sure the weighted and unweighted versions of the graphs should be 
identical, but guess it makes sense of the ties are treated as binary in most of
the cases.  This is just a start and more will definitely be needed to generate 
the final graphs for the poster.

*/

// Creates a log file
log using `"$logs/dataviz.txt"', replace text name(visualize)

// Defines local macro to add note to graphs
loc note "2018 Kentucky Legislative Data from LegiScan (http://www.legiscan.com)."

// Loads networks into Mata and also adds Stata variables in not useful format
nwuse `"$analysis/senateAnalyzedNetworks"', nwclear

// Sets some of the options for exporting the graphs as Encapsulated PostScript
graph set eps orientation p
graph set eps fontface Times
graph set eps preview on
graph set eps logo off
graph set eps cmyk on

// Set note to display for the caption
loc capnote "Names shown for top 25% of Eigenvector Centrality Distribution."

loc note `"`capnote'  `note'"'

loc senatenonedwgt "Senate Weighted Network of Non-Education Legislation"
loc senateedwgt "Senate Weighted Network of Education Legislation"
loc senatenonedunwgt "Senate Unweighted Network of Non-Education Legislation"
loc senateedunwgt "Senate Unweighted Network of Education Legislation"

// Loops over the senate networks
foreach network in $senatewgt $senateunwgt {

	// Clear Stata variables from memory
	clear
	
	// Load the network
	nwload `network'

	// Keep only valid records
	keep if !mi(_nodeid) & !mi(_nodelab)
	
	// Join the political party data
	$mrgsenate

	// Keep only valid records
	keep if !mi(_nodeid) & !mi(_nodelab)
	
	// Estimates the eigenvector centrality
	nwevcent `network', generate(`network'_eigencent)

	// Summary of Eigenvector centrality values
	su `network'_eigencent, de
	
	// Removes names for everyone outside of the top 25% 
	replace name = "" if `network'_eigencent < `r(p75)'
	
	// Change the end of line delimiter to a semicolon
	#d ;
	
	// Creates graph of the senate networks
	nwplot `network', xsize(11) ysize(8) name(`network', replace)
	label(name) labelopt(mlabs(vsmall) mlabc(black) mlabgap(*1.5) mlabpos(12))  
	color(party, colorpalette(red%50 blue%50) nodeclash(0.75)) 
	size(`network'_eigencent, sizebin(10) legendoff) edgefactor(0.75) 
	arcstyle(curved) arcsplines(50)	arcbend(0.35) 
	layout(mds, iterations(5000)) 	nodefactor(1.5) 
	edgecolor(, edgecolorpalette(orange%15)) 
	ti(`"``network''"', span c(black) size(large) pos(12) ring(7)) 
	note(`"`note'"', c(black) size(vsmall) pos(7) ring(7)) 
	plotr(margin(zero) ic(ltbluishgray)) 
	graphr(margin(zero) ic(ltbluishgray) lc(black) lw(vthin)) 
	legendopt(pos(12) ring(6) size(small) 
	region(lc(ltbluishgray) fc(ltbluishgray))) ;

	// Change end of line delimiter back to carriage return
	#d cr

	// Saves the network graph
	gr save `"$results/graphs/stata/`network'-graph.gph"', replace
	
	// Exports the graph as a PDF document
	gr export `"$results/graphs/pub/`network'-graph.pdf"', as(pdf) replace
		
} // End Loop over senate networks

// Loads the house networks
nwuse `"$analysis/houseAnalyzedNetworks"', nwclear

loc housenonedwgt "House Weighted Network of Non-Education Legislation"
loc houseedwgt "House Weighted Network of Education Legislation"
loc housenonedunwgt "House Unweighted Network of Non-Education Legislation"
loc houseedunwgt "House Unweighted Network of Education Legislation"

// Loops over house networks
foreach network in $housewgt $houseunwgt {
	
	// Clear Stata variables from memory
	clear
	
	// Load the network
	nwload `network'

	// Keep only valid records
	keep if !mi(_nodeid) & !mi(_nodelab)
	
	// Join the political party data
	$mrghouse

	// Estimates the eigenvector centrality
	nwevcent `network', generate(`network'_eigencent)
	
	su `network'_eigencent, de
	
	replace name = "" if `network'_eigencent < `r(p75)'
	
	// Keep only valid records
	keep if !mi(_nodeid) & !mi(_nodelab)
	
	if ustrregexm(`"`network'"', "noned") == 1 {
		loc edgef 0.25
		loc nodef 0.5
	}
	else {
		loc edgef 1.15
		loc nodef 1
	}
	
	#d ;
	
	// Creates graph of the senate networks
	nwplot `network', xsize(11) ysize(8) name(`network', replace)
	label(name) labelopt(mlabs(tiny) mlabc(black) mlabgap(*1.25) mlabp(12)) 
	color(party, colorpalette(red%50 blue%50) nodeclash(1000000)) 	
	size(`network'_eigencent, sizebin(10) nodeclash(1000000) legendoff) 
	edgefactor(`edgef')	 
	arcstyle(curved) arcsplines(15)	arcbend(0.35)					
	layout(mds, iterations(5000)) nodefactor(`nodef')	
	edgecolor(, edgecolorpalette(orange%15)) 
	ti(`"``network''"', span c(black) size(large) pos(12) ring(7)) 
	note(`"`note'"', c(black) size(vsmall) span pos(7) ring(7)) 
	plotr(margin(zero) ic(ltbluishgray)) 
	graphr(margin(zero) ic(ltbluishgray) lc(black) lw(vthin)) 
	legendopt(pos(12) ring(6) size(small) 
	region(lc(ltbluishgray) fc(ltbluishgray))) ;
		
	#d cr
	
	// Saves the network graph
	gr save `"$results/graphs/stata/`network'-graph.gph"', replace
	
	// Exports the graph as a PDF document
	gr export `"$results/graphs/pub/`network'-graph.pdf"', as(pdf) replace
	
} // End Loop over house networks

// Close the log file
log c visualize
