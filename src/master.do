// Makes sure any log files are closed before starting the script
cap log c _all

// Open log file
log using ~/Desktop/kyLegislation/logs/master, smcl replace name(master)

// Move to root directory
loc root ~/Desktop/kyLegislation

// Set global for location of log files
glo logs `root'/logs

// Set global for location of raw data sets that are used in this project 
glo raw `root'/data/raw/2018/regular

// Set global for location of clean data sets that are used in this project
glo clean `root'/data/clean/2018

// Set global for location of data sets that get used for analysis
glo analysis `root'/data/clean/analysis

// Set global for location of results
glo results `root'/results

// Set global for location of project's source code
glo src `root'/src

// Stores stub for merge command to get party affiliation joined to the data
loc mrgcmd merge 1:1 _nodelab using

// Stores the options to pass to the merge command to join party affilation data
loc mrgopts nogen keepus(name party nodepos)

// Constructs the command to join house members' party affiliations to the data
glo mrghouse `mrgcmd' `"$clean/houseMembers.dta"', `mrgopts'

// Constructs the command to join senate members' party affiliations to the data
glo mrgsenate `mrgcmd' `"$clean/senateMembers.dta"', `mrgopts'

// Reference for weighted networks for the house
glo housewgt housenonedwgt houseedwgt

// Reference for unweighted networks for the house
glo houseunwgt housenonedunwgt houseedunwgt

// Reference for weighted networks for the senate
glo senatewgt senatenonedwgt senateedwgt

// Reference for unweighted networks for the senate
glo senateunwgt senatenonedunwgt senateedunwgt

// Reference to get node id for house education committee chair
glo hedchair su _nodeid if name == "John Carney"

// Reference to get node id for house education committee vice chair
glo hedvicechair su _nodeid if name == "Steve Riley"

// Reference to get node id for senate education committee chair
glo sedchair su _nodeid if name == "George Wise"

// Reference to get node id for senate education committee vice chair
glo sedvicechair su _nodeid if name == "Stephen West"

// Reference to senate president
glo spres su _nodeid if name == "Robert Stivers"

// Reference to find id for house speaker pro tempore
glo sprotemp su _nodeid if name == "Jimmy Higdon"

// Reference to senate majority leader
glo smajldr su _nodeid if name == "Damon Thayer"

// Reference to senate majority whip
glo smajwhip su _nodeid if name == "Mike Wilson"

// Reference to senate minority leader
glo sminldr su _nodeid if name == "Ray Jones"

// Reference to senate minority whip
glo sminwhip su _nodeid if name == "Dennis Parrett"

// Reference to speaker of the house
glo hpres su _nodeid if name == ""

// Reference to find id for house speaker pro tempore
glo hprotemp su _nodeid if name == "David Osborne"

// Reference to house majority leader
glo hmajldr su _nodeid if name == "Jonathan Shell"

// Reference to house majority whip
glo hmajwhip su _nodeid if name == "Kevin Bratcher"

// Reference to house minority leader
glo hminldr su _nodeid if name == "Rocky Adkins"

// Reference to house minority whip
glo hminwhip su _nodeid if name == "Wilson Stone"

// Macro that contains the names of the global macros for senate leadership
glo senateldrshp spres sprotemp smajldr smajwhip sminldr sminwhip sedchair sedvicechair

// Macro that contains the names of the global macros for house leadership
glo houseldrshp hprotemp hmajldr hmajwhip hminldr hminwhip hedchair hedvicechair

// Run the script that cleans the legiscan data
do `"$src/cleanData.do"'

// Run the script that constructs the networks
do `"$src/createNetworks.do"'

// Run the script that does the analysis
do `"$src/networkAnalytics.do"'

// Run the script that does the visualization
do `"$src/networkVisualization.do"'

// Close log file for controller script
log c master

// File extensions for cleanup after LaTeX Compilation
loc fileext aux bbl bcf blg log nav out run.xml snm synctex.gz toc

// Compile slides
! pdflatex `root'/poster/stata2018.tex && pdflatex `root'/poster/stata2018.tex
! biber `root'/poster/stata2018 && pdflatex `root'/poster/stata2018.tex

// Loop over file extensions to cleanup the poster subdirectory
foreach f of loc fileext {
	erase `root'/poster/stata2018.`f'	
}

loc sh1 cd ~/Desktop/kyLegislation && git add . 
loc commitmsg "Updating scripts and output at `c(current_time)' on `c(current_date)'"
loc sh2 git commit -m "`commitmsg'"

// Commit the changes
! `sh1' && `sh2' && git push -u origin master

// End of controller script
