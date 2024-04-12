README for flow gauge rvt filepaths
Created by: Madeline Tucker

"naturalized" folder - contains rvt files for gauges with naturalized flows

"diversions" folder - contains rvt files for gauge 05018000, which is located at the beginning of the St.Mary Canal diversion.
 This gauge was used as both the outflow from the main stream network and the inflow into the Milk River because the gauge
 050189000 (at the outlet of the St. Mary Canal) had an insufficient record length. The function :InflowHydrograph2 was used
 in both the inflow and outflow scenarios, with negative flows for outflow and positive flows for inflow. Thus, these diversion
 files assume no water losses occur in the diversion.
 
 "hydat" and "USGS" folders - contains rvt files for gauges that were filtered when checking for subbasins with multiple gauges.
 Please refer to the write-up "station_filtering" for filtering methodology. The rvt files can be dragged out of separate folders
 and into the main "obs" folder if being used in the model.
 
 "redirect.txt" file - contains RedirectToFile commands for the rvt files within the "hydat" and "USGS" folders. Just copy and
 paste into rvt file as needed. 