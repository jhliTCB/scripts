############################################################################
#cr
#cr            (C) Copyright 1995-2013 The Board of Trustees of the
#cr                        University of Illinois
#cr                         All Rights Reserved
#cr
############################################################################
#
# $Id: communityNetwork.tcl,v 1.8 2014/02/20 20:16:08 kvandivo Exp $
#

# communityNetwork - import network data from networkAnalysis and create 3D graphs
#               in VMD; requires networkView
#   John Eargle - eargle@illinois.edu
#    5 Nov 2008
#   13 Feb 2009

package provide networkview 1.41

namespace eval ::NetworkView {

    variable communityLoaded ;# whether community data is loaded or not
    array set communityLoaded {}

    variable communityNodes ;# array with community node information
    # accessed through network index and community index
    # netIndex,communityCount: number of communities
    # netIndex,cIndex,coordinate: {x,y,z} location
    # netIndex,cIndex,objectIndex: OpenGL object index for deletion
    # netIndex,cIndex,nodeIndex,x: node indices for nodes in the community
    # netIndex,cIndex,value: arbitrary value assigned to communityNode
    # netIndex,cIndex,active: displayed or not
    # netIndex,cIndex,color: display color
    array set communityNodes {}

    variable communityEdges ;# array with community edge information
    # accessed through network index and pair of indices (ci1,ci2) for the communityNodes at each end
    # netIndex,ci1,ci2,weight: edge distance
    # netIndex,maxweight: maximum weight
    # netIndex,minweight: minimum weight
    # netIndex,ci1,ci2,betweenness: number of shortest paths crossing the edge
    # netIndex,ci1,ci2,objectIndex: OpenGL object index for deletion
    # netIndex,ci1,ci2,active: displayed or not
    # netIndex,ci1,ci2,color: display color
    array set communityEdges {}

    variable criticalNodes ;# array with critical node information
    # accessed through network index and community index
    # netIndex,nodeList: list of all criticalNodes
    # netIndex,cIndex,nodeCount: number of critical nodes in this community
    # netIndex,cIndex,index: node index for critical node belonging to a given community
    # netIndex,cIndex1,cIndex2,nodePairCount: number of critical node pairs connecting these two communities
    # netIndex,cIndex1,cIndex2,index: node index for critical node pair between two communities
    array set criticalNodes {}

    variable criticalEdges ;# array with critical edge information
    # accessed through network index and pair of indices (ci1,ci2) for the communityNodes at each end
    # netIndex,edgeList: list of all criticalEdges as pairs of nodes
    # netIndex,ci1,ci2,edgeIndex: edge indices for critical edges between two communities
    array set criticalEdges {}

}


# Initialize the data structures that carry community network information.  readNetworkFile has to be called first so that the node indices are set
# @param communityFilename file assigning nodes to specific communities
# @param betweennessFilename 
# param2 is ommitted!!! just cat output.log >> $communityFilename
proc ::NetworkView::readCommunityFile { communityFilename } {

#    puts ">readCommunityFile"

    #variable molid
    variable currentNetwork
    #variable nodes
    variable nodes2
    variable nodeCoordinate
    #variable edges
    variable communityLoaded
    variable communityNodes
    variable communityEdges
    variable criticalNodes
    variable criticalEdges

    set criticalNodes($currentNetwork,nodeList) [list ]
    set criticalEdges($currentNetwork,edgeList) [list ]
    set numNodesTotal 0 ;# count nodes to see if it matches number of nodes loaded
    set community1 -1
    set community2 -1

    # Check that a network is loaded
    if {$currentNetwork == -1} {
    puts "Error: readCommunityFile - no network loaded"
    return
    }

    set communityFile [open $communityFilename "r"]

    # Read in data for communityNodes and criticalNodes
    set line [gets $communityFile]
    #[regexp {optimum number of communities is (\d*)} $line matchVar numCommunities]
    if {[regexp {optimum number of communities is (\d*)} $line matchVar numCommunities]} {
    puts "Number of communities: $numCommunities"
    } else {
    puts "Error: readCommunityFile - could not read number of communities"
    return
    }

    for {set i 0} {$i < $numCommunities} {incr i} {
    for {set j [expr $i+1]} {$j < $numCommunities} {incr j} {
        set criticalNodes($currentNetwork,$i,$j,nodePairCount) 0
    }
    }

    set i 0
    while {![eof $communityFile]} {
    set line [gets $communityFile]
    # Set up communityNodes
    if {[regexp {residues in community (\d+) are: (.*)} $line matchVar communityIndex indexString]} {
        set communityIndex [expr $communityIndex-1]
        incr i
        set centerPoint {0 0 0}
        set j 0
        set numNodes 0
#       puts -nonewline "Community $communityIndex: "
        foreach index $indexString {
#          puts -nonewline " $index,"
          set communityNodes($currentNetwork,$communityIndex,nodeIndex,$j) $index
          #set centerPoint [vecadd $centerPoint $nodes($currentNetwork,$index,coordinate)]
          set centerPoint [vecadd $centerPoint [lindex $nodes2 $currentNetwork $nodeCoordinate $index]]
          incr numNodes
          incr j
        }
        set communityNodes($currentNetwork,$communityIndex,coordinate) [vecscale $centerPoint [expr 1.0/$numNodes]]
        set communityNodes($currentNetwork,$communityIndex,active) 1
        set communityNodes($currentNetwork,$communityIndex,color) blue
        incr numNodesTotal $numNodes
       puts ""    
    } elseif {[regexp {edge connectivities between communities (\d+) and (\d+)} $line matchVar c1 c2]} {
        # Store community indices to set up criticalNodes
        set community1 [expr $c1-1]
        set community2 [expr $c2-1]
    } elseif {[regexp {(\d+) (\d+) \d+\.\d+} $line matchVar index1 index2]} {
        # Set up criticalNodePairs
        set currentNodePairIndex $criticalNodes($currentNetwork,$community1,$community2,nodePairCount)
        set criticalNodes($currentNetwork,$community1,$community2,$currentNodePairIndex) [list $index1 $index2]
        lappend criticalNodes($currentNetwork,nodeList) $index1
        lappend criticalNodes($currentNetwork,nodeList) $index2
        incr criticalNodes($currentNetwork,$community1,$community2,nodePairCount)
        #lappend criticalEdges($currentNetwork,edgeList) [list $index1 $index2]
        lappend criticalEdges($currentNetwork,edgeList) "$index1,$index2"
    }
    
    }
    close $communityFile

    if {$i != $numCommunities} {
    puts "Error: readCommunityFile - stated number of communities different from number read in ($numCommunities vs. $i)"
    return
    }
    set communityNodes($currentNetwork,communityCount) $numCommunities

#    set betweennessFile [open $betweennessFilename "r"]
    set betweennessFile [open $communityFilename "r"]

    # Set up communityEdges from Total Community Flow data
    set line [gets $betweennessFile]
    while {![regexp {Total Community Flow is} $line] && ![eof $betweennessFile]} {
    set line [gets $betweennessFile]
    }
    set line [gets $betweennessFile]
    set i 0
    while {![regexp {Intercommunity Flow is} $line] && ![eof $betweennessFile]} {
    set betweennesses [concat $line]
    #puts $betweennesses
    for {set j 0} {$j < [llength $betweennesses]} {incr j} {
        set tempVal [lindex $betweennesses [expr $j]]
        if {$tempVal != 0} {
        #set edges($i,$j) $tempVal
        #puts "edges($i,$j) $tempVal"
        set communityEdges($currentNetwork,$i,$j,betweenness) $tempVal
        set communityEdges($currentNetwork,$i,$j,active) 1
        set communityEdges($currentNetwork,$i,$j,color) blue
        }
    }
    
    set line [gets $betweennessFile]
    incr i
    }
    close $betweennessFile

    #drawCommunityNetwork
    
    set communityLoaded($currentNetwork) 1

#    puts "<readCommunityFile"
    return
}


# Retrieve nodeIndices for all nodes in a given community
# @param communityId ID for community whose nodes should be fetched
# @return List of nodeIndices
proc ::NetworkView::getCommunityNodes { args } {

    variable currentNetwork
    variable communityNodes

    set communityId -1
    set nodeIndices [list ]

    if {[llength $args] == 1} {
    set communityId [lindex $args 0]
    } else {
    puts "Error: ::NetworkView::getCommunityNodes - wrong number of arguments"
    puts "  getCommunityNodes communityId"
    puts "    communityId: ID for community whose nodes should be fetched"
    return
    }

#    foreach {nodeIndex} [array get communityNodes "$communityId,nodeIndex,*"] {
#        lappend nodeIndices $nodeIndex
#    }

    foreach {key nodeIndex} [array get communityNodes "$currentNetwork,$communityId,nodeIndex,*"] {
    lappend nodeIndices $nodeIndex
    }

    return $nodeIndices
}


# Retrieve nodeIndices for all critical nodes
# @return List of nodeIndices
proc ::NetworkView::getCriticalNodes { args } {

    #variable communityNodes
    variable currentNetwork
    variable criticalNodes

#    set nodeIndices [list ]

    if {[llength $args] == 0} {
    } else {
    puts "Error: ::NetworkView::getCriticalNodes - wrong number of arguments"
    puts "  getCriticalNodes"
    return
    }

#    for {set i 0} {$i < $communityNodes($currentNetwork,communityCount)} {incr i} {
#    for {set j [expr $i+1]} {$j < $communityNodes($currentNetwork,communityCount)} {incr j} {
#        lappend nodeIndices [lindex 0 $nodePair]
#        lappend nodeIndices [lindex 1 $nodePair]
#    }
#    }

    return $criticalNodes($currentNetwork,nodeList)
}


# Retrieve nodeIndex pairs for all critical edges
# @return List of nodeIndex pairs
proc ::NetworkView::getCriticalEdges { args } {

    variable currentNetwork
    variable criticalEdges

    if {[llength $args] == 0} {
    } else {
    puts "Error: ::NetworkView::getCriticalEdges - wrong number of arguments"
    puts "  getCriticalEdges"
    return
    }

    return $criticalEdges($currentNetwork,edgeList)
}

proc ::NetworkView::formatNodeXml { suID node dX dY dsize slst } {
    set ind_size [expr [lsearch [lsort $slst] $dsize] + 1]
    set tot_nodes [llength $slst]
    set lfont_size [format "%d" [expr 35 + 20 / $tot_nodes * $ind_size]]
    puts "$suID $node $dX $dY $dsize $slst $lfont_size"
    set xmlOutput "  <node id=\"$suID\" label=\"C$node\">
  <att name=\"shared name\" value=\"C$node\" type=\"string\" cy:type=\"String\"/>
  <att name=\"name\" value=\"C$node\" type=\"string\" cy:type=\"String\"/>
  <att name=\"selected\" value=\"0\" type=\"boolean\" cy:type=\"Boolean\"/>
  <att name=\"x\" value=\"$dX\" type=\"real\" cy:type=\"Double\"/>
  <att name=\"y\" value=\"$dY\" type=\"real\" cy:type=\"Double\"/>
  <att name=\"community\" value=\"$node\" type=\"integer\" cy:type=\"Integer\"/>
  <att name=\"origin_size\" value=\"$dsize\" type=\"integer\" cy:type=\"Integer\"/>
  <graphics z=\"0.0\" x=\"$dX\" width=\"0.0\" w=\"$dsize\" fill=\"#CCFFCC\" outline=\"#CCCCCC\" h=\"$dsize\" y=\"$dY\" type=\"ELLIPSE\">
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_9\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_1\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_7\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_4\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_TRANSPARENCY\" value=\"255\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_2\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_6\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_POSITION\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_3\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_4\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_9\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_2\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_7\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_7\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_8\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_5\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_1\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_5\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_8\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_DEPTH\" value=\"0.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_9\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_4\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_3\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_6\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_BORDER_TRANSPARENCY\" value=\"255\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_SELECTED_PAINT\" value=\"#FFFF00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_8\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_COLOR\" value=\"#000000\" type=\"string\" cy:type=\"String\"/>
     <att name=\"COMPOUND_NODE_SHAPE\" value=\"ROUND_RECTANGLE\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_TOOLTIP\" value=\"\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_5\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_2\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL\" value=\"C$node\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_FONT_SIZE\" value=\"$lfont_size\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_TRANSPARENCY\" value=\"255\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_POSITION_3\" value=\"C,C,c,0.00,0.00\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_WIDTH\" value=\"200.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_LABEL_FONT_FACE\" value=\"SansSerif.plain,plain,12\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_SELECTED\" value=\"false\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_BORDER_STROKE\" value=\"SOLID\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_VISIBLE\" value=\"true\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_NESTED_NETWORK_IMAGE_VISIBLE\" value=\"true\" type=\"string\" cy:type=\"String\"/>
     <att name=\"COMPOUND_NODE_PADDING\" value=\"10.0\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_6\" value=\"org.cytoscape.ding.customgraphics.NullCustomGraphics,0,\[ Remove Graphics \],\" type=\"string\" cy:type=\"String\"/>
     <att name=\"NODE_CUSTOMGRAPHICS_SIZE_1\" value=\"35.0\" type=\"string\" cy:type=\"String\"/>
  </graphics>
  </node>"
    return $xmlOutput
}

proc ::NetworkView::formatEdgeXml { suID node1 node2 eu1 eu2 interaction } {
    set xmlOutput "  <edge id=\"$suID\" label=\"C$node1 ($interaction) C$node2\" source=\"$eu1\" target=\"$eu2\" cy:directed=\"1\">
  <att name=\"shared name\" value=\"C$node1 ($interaction) C$node2\" type=\"string\" cy:type=\"String\"/>
  <att name=\"shared interaction\" value=\"$interaction\" type=\"string\" cy:type=\"String\"/>
  <att name=\"name\" value=\"C$node1 ($interaction) C$node2\" type=\"string\" cy:type=\"String\"/>
  <att name=\"selected\" value=\"0\" type=\"boolean\" cy:type=\"Boolean\"/>
  <att name=\"interaction\" value=\"$interaction\" type=\"string\" cy:type=\"String\"/>
  <graphics width=\"$interaction\" fill=\"#848484\">
    <att name=\"EDGE_VISIBLE\" value=\"true\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL\" value=\"\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TARGET_ARROW_SIZE\" value=\"6.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LINE_TYPE\" value=\"SOLID\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_STROKE_SELECTED_PAINT\" value=\"#FF0000\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_SELECTED\" value=\"false\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_BEND\" value=\"\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TOOLTIP\" value=\"\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL_WIDTH\" value=\"200.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TRANSPARENCY\" value=\"255\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL_COLOR\" value=\"#000000\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TARGET_ARROW_SELECTED_PAINT\" value=\"#FFFF00\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_SOURCE_ARROW_UNSELECTED_PAINT\" value=\"#000000\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_SOURCE_ARROW_SELECTED_PAINT\" value=\"#FFFF00\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TARGET_ARROW_SHAPE\" value=\"NONE\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL_FONT_SIZE\" value=\"10\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL_TRANSPARENCY\" value=\"255\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_LABEL_FONT_FACE\" value=\"Dialog.plain,plain,10\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_SOURCE_ARROW_SIZE\" value=\"6.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_CURVED\" value=\"true\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_SOURCE_ARROW_SHAPE\" value=\"NONE\" type=\"string\" cy:type=\"String\"/>
    <att name=\"EDGE_TARGET_ARROW_UNSELECTED_PAINT\" value=\"#000000\" type=\"string\" cy:type=\"String\"/>
  </graphics>
  </edge>"
    return $xmlOutput
}

proc ::NetworkView::formatXmlHead { title } {
    set system_clock [clock format [clock seconds] -format "%Y-%m-%d %H:%m:%S"]
    set OutputXml "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<graph id=\"51\" label=\"83\" directed=\"1\" cy:documentVersion=\"3.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:cy=\"http://www.cytoscape.org\" xmlns=\"http://www.cs.rpi.edu/XGMML\">
  <att name=\"networkMetadata\">
    <rdf:RDF>
      <rdf:Description rdf:about=\"http://www.cytoscape.org/\">
        <dc:type>Protein-Protein Interaction</dc:type>
        <dc:description>N/A</dc:description>
        <dc:identifier>N/A</dc:identifier>
        <dc:date>$system_clock</dc:date>
        <dc:title>83</dc:title>
        <dc:source>http://www.cytoscape.org/</dc:source>
        <dc:format>Cytoscape-XGMML</dc:format>
      </rdf:Description>
    </rdf:RDF>
  </att>
  <att name=\"shared name\" value=\"$title\" type=\"string\" cy:type=\"String\"/>
  <att name=\"name\" value=\"$title\" type=\"string\" cy:type=\"String\"/>
  <att name=\"selected\" value=\"1\" type=\"boolean\" cy:type=\"Boolean\"/>
  <att name=\"__Annotations\" type=\"list\" cy:type=\"List\" cy:elementType=\"String\">
  </att>
  <att name=\"layoutAlgorithm\" value=\"Prefuse Force Directed Layout\" type=\"string\" cy:type=\"String\" cy:hidden=\"1\"/>
  <graphics>
    <att name=\"NETWORK_HEIGHT\" value=\"489.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_ANNOTATION_SELECTION\" value=\"false\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_BACKGROUND_PAINT\" value=\"#FFFFFF\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_SCALE_FACTOR\" value=\"0.4149770383776926\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_TITLE\" value=\"\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_CENTER_Z_LOCATION\" value=\"0.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_CENTER_X_LOCATION\" value=\"602.9720092424044\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_DEPTH\" value=\"0.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_EDGE_SELECTION\" value=\"true\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_NODE_SELECTION\" value=\"true\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_FORCE_HIGH_DETAIL\" value=\"false\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_WIDTH\" value=\"804.0\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_NODE_LABEL_SELECTION\" value=\"false\" type=\"string\" cy:type=\"String\"/>
    <att name=\"NETWORK_CENTER_Y_LOCATION\" value=\"-722.4760961864087\" type=\"string\" cy:type=\"String\"/>
  </graphics>"
    return $OutputXml
}

# Print out a gdf (GUESS) file based on the community structure
# @param gdfFilename File name for a .gdf format file
# Updated by Junhao Li @KTH: 
#   add two more output files for simple visulization in Cytoscape.
#   TODO:  Been able to check the existance of isolated communities(0-edege nodes)
#       in Cytoscape, -> "import network from file" -> chose the $sifFilename
#       then import the $csvFilename for the Node table
proc ::NetworkView::writeCommunityGdf { gdfFilename } {

    variable currentNetwork
    variable molids
    variable communityNodes
    variable communityEdges

    set filePrefix [lindex [split $gdfFilename "."] 0]
    set xgmmlFilename "$filePrefix.xgmml"
    set sifFilename "$filePrefix.sif"
    set csvFilename "$filePrefix.csv"
    set gdfFile [open $gdfFilename "w"]
    set xgmmlFile [open $xgmmlFilename "w"]
    set sifFile [open $sifFilename "w"]
    set csvFile [open $csvFilename "w"]

    #Write the Heads for .xgmml, .csv, and .gdf
    set sysPrefix [lindex [split $filePrefix "/"] end]
    set xgmml_head [formatXmlHead $sysPrefix]
    puts $xgmmlFile "$xgmml_head"
    puts $gdfFile "nodedef>name VARCHAR,x DOUBLE,y DOUBLE,community INTEGER,origin_size INTEGER,visible BOOLEAN,color VARCHAR,strokecolor VARCHAR,labelcolor VARCHAR,fixed BOOLEAN,width INTEGER,height INTEGER,style INTEGER,label VARCHAR,labelvisible BOOLEAN"
    puts $csvFile "name,x,y,communityID,origin_size"

    #Get community info for .xgmml, .csv, and .gdf
    set dict_communities [dict create ]
    set size_list {}
    foreach {communityKey coord} [array get communityNodes "$currentNetwork,*,coordinate"] {
    #puts $gdfFile "C$community,$community,[expr $size * 20]"
    regexp {\d+,(\d+),coordinate} $communityKey matchVar community
    set rotationMatrix [molinfo $molids($currentNetwork) get rotate_matrix]
    set rotationCoord [vectrans [lindex $rotationMatrix 0] $coord]
    set xCoord [expr 10 * [lindex $rotationCoord 0]]
    set yCoord [expr -10 * [lindex $rotationCoord 1]]
    set size [llength [array get communityNodes "$currentNetwork,$community,nodeIndex,*"]]
    # get newformat for guess 2007.08.13
    # true,cornflowerblue,cadetblue,,false,2,40.0,40.0,,,false,0.0
    lappend size_list $size
    set attr_list {}
    lappend attr_list "$xCoord" "$yCoord" "$community" "$size"
    dict append dict_communities "C$community" "$attr_list"
    puts $gdfFile "C$community,$xCoord,$yCoord,$community,$size,true,cornflowerblue,cadetblue,,false,$size,$size,2,,true"
    puts $csvFile "C$community,$xCoord,$yCoord,$community,$size"
    }

    # Write out community edge information with betweenness values
    # get sum of betweenness
    set b_sum 0.0
    puts "###########################################################"
    set community_data [array get communityEdges "$currentNetwork,*,*,betweenness"]
    puts $community_data
    foreach {edge between} $community_data {
        set b_sum [format "%.2f" [expr $b_sum + $between]]
    }

    #puts $gdfFile "edgedef> node1,node2,betweenness int"
    puts $gdfFile "edgedef>node1 VARCHAR,node2 VARCHAR,betweenness INTEGER,__edgeid INTEGER,visible BOOLEAN,color VARCHAR,labelcolor VARCHAR,width DOUBLE,weight DOUBLE,directed BOOLEAN,label VARCHAR,labelvisible BOOLEAN"

    set b_id 0
    set suid 60
    set all_Comms [dict keys $dict_communities]
    set check_duplicate {}
    puts $b_sum
    puts $all_Comms

    foreach {edgeKey  betweenness}  $community_data  {
        regexp {\d+,(\d+),(\d+),betweenness} $edgeKey matchVar node1 node2
        set scaled_betweenness [format "%.1f" [expr $betweenness / $b_sum * 200.0 + 1.0]]
        if {$node1 < $node2} {
            #puts $gdfFile "C$node1,C$node2,[format "%.0f" [expr $betweenness / 100.0]]"
            #puts $gdfFile "C$node1,C$node2,[format "%.0f" $betweenness]"
            set ind_dup1 [lsearch $check_duplicate "C$node1"]
            set ind_dup2 [lsearch $check_duplicate "C$node2"]
            if {$ind_dup1 == -1} {
                incr suid
                set dx [lindex [dict get $dict_communities "C$node1"] 0]
                set dy [lindex [dict get $dict_communities "C$node1"] 1]
                set ds [lindex [dict get $dict_communities "C$node1"] 3]
                set temp [dict get $dict_communities "C$node1"]
                lappend temp $suid
                dict set dict_communities "C$node1" "$temp"
                puts $xgmmlFile [formatNodeXml $suid $node1 $dx $dy $ds $size_list]
                lappend check_duplicate "C$node1"
            }
            if {$ind_dup2 == -1} {
                incr suid
                set dx [lindex [dict get $dict_communities "C$node2"] 0]
                set dy [lindex [dict get $dict_communities "C$node2"] 1]
                set ds [lindex [dict get $dict_communities "C$node2"] 3]
                set temp [dict get $dict_communities "C$node2"]
                lappend temp $suid
                dict set dict_communities "C$node2" "$temp"
                puts $xgmmlFile [formatNodeXml $suid $node2 $dx $dy $ds $size_list]
                lappend check_duplicate "C$node2"
            }
            #Write the edges in time
            incr suid
            set eu1 [lindex [dict get $dict_communities "C$node1"] 4]
            set eu2 [lindex [dict get $dict_communities "C$node2"] 4]
            puts $xgmmlFile [formatEdgeXml $suid $node1 $node2 $eu1 $eu2 $scaled_betweenness]
            puts $gdfFile "C$node1,C$node2,$betweenness,$b_id,true,dandelion,,$scaled_betweenness,1.0,false,,false"
            puts $sifFile "C$node1   $scaled_betweenness   C$node2"
            incr b_id
        }
    }
    #end of looping betweennees

    if {[llength $all_Comms] != [llength $check_duplicate]} {
        foreach no_edge_node $all_Comms {
            if { [lsearch $check_duplicate $no_edge_node] == -1 } {
                incr suid
                set dx [lindex [dict get $dict_communities "$no_edge_node"] 0]
                set dy [lindex [dict get $dict_communities "$no_edge_node"] 1]
                set cid [lindex [dict get $dict_communities "$no_edge_node"] 2]
                set ds [lindex [dict get $dict_communities "$no_edge_node"] 3]
                puts $xgmmlFile [formatNodeXml $suid $cid $dx $dy $ds $size_list]
            }
        }
    }
    puts $xgmmlFile "</graph>"

    close $gdfFile
    close $xgmmlFile
    close $sifFile
    close $csvFile

    return
}


# Draw nodes that each represent an entire community and the edges between them
proc ::NetworkView::drawCommunityNetwork {} {
    
#    puts ">drawCommunityNetwork"

    drawCommunityNodes
    drawCommunityEdges

#    puts "<drawCommunityNetwork"
    return
}


# Draw nodes that each represent an entire community
proc ::NetworkView::drawCommunityNodes {} {

    #variable molid
    variable currentNetwork
    variable communityNodes
    variable sphereRadius
    variable sphereResolution

    set radius $sphereRadius
    set resolution $sphereResolution

    foreach colorKey [array get communityNodes "$currentNetwork,*,color"] {
    regexp {\d+,(\d+),} $colorKey matchVar index
    #puts "drawNode $index $radius $resolution"
    drawCommunityNode $index $radius $resolution
    }

    return
}


# Draw edges that connect community nodes
proc ::NetworkView::drawCommunityEdges {} {

    variable currentNetwork
    variable communityEdges
    variable cylinderRadius
    variable cylinderResolution

    set radius $cylinderRadius
    set resolution $cylinderResolution

    foreach colorKey [array get communityEdges "$currentNetwork,*,color"] {
    regexp {\d+,(\d+),(\d+),} $colorKey matchVar index1 index2
    drawCommunityEdge $index1 $index2 $radius $resolution
    }

    return
}


# Delete current communityNode OpenGL object and redraw a new one if active
# @param index1 Index of community node
# @param radius Sphere radius
# @param resolution Sphere resolution
proc ::NetworkView::drawCommunityNode { index radius resolution } {

    #puts ">drawCommunityNode"
    variable currentNetwork
    variable molids
    variable communityNodes

    # if OpenGL object already exists, delete
    set objectIndices [array get communityNodes "$currentNetwork,$index,objectIndex"]
    if {[llength $objectIndices] > 0} {
    graphics $molids($currentNetwork) delete $communityNodes([lindex $objectIndices 0])
    }

    if {$communityNodes($currentNetwork,$index,active) != 0} {
    graphics $molids($currentNetwork) color $communityNodes($currentNetwork,$index,color)
    set communityNodes($currentNetwork,$index,objectIndex) [graphics $molids($currentNetwork) sphere $communityNodes($currentNetwork,$index,coordinate) radius $radius resolution $resolution]
    }

    #puts "<drawCommunityNode"
    return
}


# Delete current communityEdge OpenGL object and redraw a new one if active
# @param index1 Index of first community node
# @param index2 Index of second community node
# @param radius Cylinder radius
# @param resolution Cylinder resolution
proc ::NetworkView::drawCommunityEdge { index1 index2 radius resolution } {

    #puts ">drawEdge"
    #puts "($index1,$index2) radius: $radius, resolution: $resolution"
    variable currentNetwork
    variable molids
    variable communityNodes
    variable communityEdges

    # if OpenGL object already exists, delete
    set objectIndices [array get communityEdges "$currentNetwork,$index1,$index2,objectIndex"]
    if {[llength $objectIndices] > 0} {
    graphics $molids($currentNetwork) delete $communityEdges([lindex $objectIndices 0])
    }

    if {$communityEdges($currentNetwork,$index1,$index2,active) != 0} {
    graphics $molids($currentNetwork) color $communityEdges($currentNetwork,$index1,$index2,color)
    set communityEdges($currentNetwork,$index1,$index2,objectIndex) [graphics $molids($currentNetwork) cylinder $communityNodes($currentNetwork,$index1,coordinate) $communityNodes($currentNetwork,$index2,coordinate) radius $radius resolution $resolution]
    }

    #puts "<drawEdge"
    return
}





################################################################################
#                                                                              #
#  All procs below apply to network nodes/edges within specified communities,  #
#  not community nodes/edges.                                                  #
#                                                                              #
################################################################################


# Activate all network nodes within a specific community
# @param communityId Community ID specifying the network nodes to be activated
# @param activateOrDeactivate Activate (1 - default) or deactivate (0)
proc ::NetworkView::activateCommunity { args } {

    set communityId -1
    set setOrUnset 1

    if {[llength $args] == 1} {
    set communityId [lindex $args 0]
    } elseif {[llength $args] == 2} {
    set communityId [lindex $args 0]
    set setOrUnset [lindex $args 1]
    } else {
    puts "Error: ::NetworkView::activateCommunity - wrong number of arguments"
    puts "  activateCommunity communityId \[activateOrDeactivate\]"
    puts "    communityId: ID for community to be activated"
    puts "    activateOrDeactivate: 0 to deactivate, 1 to activate (default)"
    return
    }

    set nodeIndices [getCommunityNodes $communityId]
    activateNodes $nodeIndices $setOrUnset
    activateInternalEdges $nodeIndices $setOrUnset

    return
}


# Deactivate a specific community
# @param communityId Community ID specifying the network nodes to be deactivated
proc ::NetworkView::deactivateCommunity { communityId } {

    activateCommunity $communityId 0

    return
}


# Use community definitions to activate the network
# @param activateOrDeactivate Activate (1 - default) or deactivate (0)
# @param communityIds List of community IDs specifying the network nodes to be activated; default "all"
proc ::NetworkView::activateCommunities { args } {

    variable currentNetwork
    variable communityNodes

    set setOrUnset 1
    set communityIds [list ]
    set nodeIndices [list ]

    if {[llength $args] == 0} {
    foreach {communityKey active} [array get communityNodes "$currentNetwork,*,active"] {
        regexp {\d+,(\d+),active} $communityKey matchVar communityId
        lappend communityIds $communityId
    }
    } elseif {[llength $args] == 1} {
    set setOrUnset [lindex $args 0]
    foreach {communityKey active} [array get communityNodes "$currentNetwork,*,active"] {
        regexp {\d+,(\d+),active} $communityKey matchVar communityId
        lappend communityIds $communityId
    }
    } elseif {[llength $args] == 2} {
    set setOrUnset [lindex $args 0]
    set communityIds [lindex $args 1]
    } else {
    puts "Error: ::NetworkView::activateCommunities - wrong number of arguments"
    puts "  activateCommunities \[activateOrDeactivate \[communityIds\]\]"
    puts "    activateOrDeactivate: 0 to deactivate, 1 to activate (default)"
    puts "    communityIds: ID for communities to be activated; default all"
    return
    }

    foreach communityId $communityIds {
    set nodeIndices [concat $nodeIndices [getCommunityNodes $communityId]]
    }

    activateNodes $nodeIndices $setOrUnset
    activateInternalEdges $nodeIndices $setOrUnset
    
    return
}


# Use community definitions to deactivate the network
# @param communityIds List of community IDs specifying the network nodes to be activated
proc ::NetworkView::deactivateCommunities { communityIds } {

    activateCommunities 0 $communityIds
    
    return
}


# Color a specific community
# @param communityId Community ID specifying the network nodes to be colored
# @param colorId 0-blue (default), 1-red, ...
proc ::NetworkView::colorCommunity { args } {

    set communityId -1
    set color 0

    if {[llength $args] == 1} {
    set communityId [lindex $args 0]
    } elseif {[llength $args] == 2} {
    set communityId [lindex $args 0]
    set color [lindex $args 1]
    } else {
    puts "Error: ::NetworkView::colorCommunity - wrong number of arguments"
    puts "  colorCommunity communityId \[colorId\]"
    puts "    communityId: ID for community to be colored"
    puts "    colorId: 0-blue (default), 1-red, ..."
    return
    }

    set nodeIndices [getCommunityNodes $communityId]
    colorNodes $nodeIndices $color
    colorInternalEdges $nodeIndices $color

    return
}


# Use community definitions to color the network
# @param communityColorId Color for within communities (0-blue (default), 1-red, ...)
# @param interfaceColorId Color for within communities (0-blue (default), 1-red, ...)
# @param communityIds List of community IDs specifying the network nodes to be colored
proc ::NetworkView::colorCommunities { args } {

#    puts ">colorCommunities"

    variable currentNetwork
    variable communityNodes

    set communityColor 0
    set interfaceColor 1
    set communityIds [list ]
    set nodeIndices [list ]

    if {[llength $args] == 2} {
    set communityColor [lindex $args 0]
    set interfaceColor [lindex $args 1]
    foreach {communityKey active} [array get communityNodes "$currentNetwork,*,active"] {
        regexp {\d+,(\d+),active} $communityKey matchVar communityId
        lappend communityIds $communityId
    }
    } elseif {[llength $args] == 3} {
    set communityColor [lindex $args 0]
    set interfaceColor [lindex $args 1]
    set communityIds [lindex $args 2]
    } else {
    puts "Error: ::NetworkView::colorCommunities - wrong number of arguments"
    puts "  colorCommunities  communityColorId interfaceColorId \[communityIds\]"
    puts "    communityColorId: 0-blue (default), 1-red, ..."
    puts "    interfaceColorId: 0-blue (default), 1-red, ..."
    puts "    communityIds: ID for communities to be colored; default all"
    return
    }

    
    foreach communityId $communityIds {
    set nodeIndices [concat $nodeIndices [getCommunityNodes $communityId]]
    }

    colorNodes $nodeIndices $interfaceColor
    colorInternalEdges $nodeIndices $interfaceColor

    foreach communityId $communityIds {
    set nodeIndices [getCommunityNodes $communityId]
    colorNodes $nodeIndices $communityColor
    colorInternalEdges $nodeIndices $communityColor
    }
    
#    puts "<colorCommunities"
    return
}


# Activate critical nodes
# @param activateOrDeactivate Activate (1 - default) or deactivate (0)
proc ::NetworkView::activateCriticalNodes { args } {

    set setOrUnset 1

    if {[llength $args] == 0} {
    } elseif {[llength $args] == 1} {
    set setOrUnset [lindex $args 0]
    } else {
    puts "Error: ::NetworkView::activateCriticalNodes - wrong number of arguments"
    puts "  activateCriticalNodes \[activateOrDeactivate\]"
    puts "    activateOrDeactivate: 0 to deactivate, 1 to activate (default)"
    return
    }

    set nodeIndices [getCriticalNodes]
    activateNodes $nodeIndices $setOrUnset

    set nodeIndexPairs [getCriticalEdges]
    # >New - 7 Jun 2010
    activateEdges $nodeIndexPairs $setOrUnset
    # <New

    #foreach indexPair $nodeIndexPairs {
    #activateInternalEdges $indexPair $setOrUnset
    #}

    return
}


# Deactivate critical nodes
proc ::NetworkView::deactivateCriticalNodes { } {

    activateCriticalNodes 0

    return
}


# Color critical nodes
# @param colorId 0-blue (default), 1-red, ...
proc ::NetworkView::colorCriticalNodes { args } {

    set color 0

    if {[llength $args] == 0} {
    } elseif {[llength $args] == 1} {
    set color [lindex $args 0]
    } else {
    puts "Error: ::NetworkView::colorCriticalNodes - wrong number of arguments"
    puts "  colorCriticalNodes \[colorId\]"
    puts "    colorId: 0-blue (default), 1-red, ..."
    return
    }

    set nodeIndices [getCriticalNodes]
    colorNodes $nodeIndices $color

    set nodeIndexPairs [getCriticalEdges]
    # >New 7 June 2010
    colorEdges $nodeIndexPairs $color
    # <New

    #foreach indexPair $nodeIndexPairs {
    #colorEdges $indexPair $color
    #}

    return
}
