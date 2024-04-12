#add lake like reservoirs for the water hrus that are lakes.
#may need more in future.  one major is cypress lake in sw saskatchewan.  currently part of 4 different subbasins which doesnt seem ideal
#jwt june 2023

library(tidyverse)
library(RavenR)

rvh <- rvn_rvh_read('./model/StMary_Milk.rvh')

restab <- read_csv('./tables/reservoir_info.csv')


#add elevation, area from hru info

resinfo <- rvh$HRUtable %>%
  select(ID, SBID, Area, Elevation) %>%
  filter(ID %in% restab$`HRU ID`)

resall <- left_join(restab, resinfo, by = c('HRU ID' = 'ID'))

#Generate Profiles For Each Sub - based on SWAT trapezoidal channel. 
sink("./model/Reservoirs.rvh")


for (i in 1:nrow(resall)){
  
  cat(paste(":Reservoir ", resall$Name[i],"\n",sep=""))
  cat(paste("\t:SubBasinID ", resall$SBID.x[i],"\n",sep=""))
  cat(paste("\t:HRUID ", resall$`HRU ID`[i],"\n",sep=""))
  #use 0.6 weir coefficient for all
  cat(paste("\t:WeirCoefficient 0.6\n",sep=""))
  cat(paste("\t:CrestWidth ", resall$Crestwidth[i],"\n",sep=""))
  #use max depth 30m for all
  cat(paste("\t:MaxDepth 30.0\n",sep=""))
  cat(paste("\t:LakeArea ", round(resall$Area[i],1),"\n",sep=""))
  #use crest height 0 and calibrate to deviations from mean rather than absolute elevation
  #cat(paste("\t:AbsoluteCrestHeight ", resall$Elevation[i],"\n",sep=""))
  cat(paste("\t:AbsoluteCrestHeight 0\n",sep=""))
  cat(paste(":EndReservoir ", resall$Name[i],"\n\n",sep=""))
  
  
} 


sink()