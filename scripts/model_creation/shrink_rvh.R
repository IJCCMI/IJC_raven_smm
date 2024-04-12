#write the RVH file from the filled hru tables

library(tidyverse)
library(RavenR)
library(foreign)
library(dplyr)


rvh.infile <- 'model/alt_models/fullhbv/StMary_Milk.rvh'
rvh.outfile <- 'model/StMary_Milk.rvh'

subs <- read.dbf('./inputs/spatial/processed/smm_subbasins_cleaned.dbf')

###########################################################
subs <- subs %>%
  mutate(XSection = paste0('Chn_', subs$ID),
         DS_ID = ifelse(is.na(DS_ID), -1, DS_ID),
         Gauged = ifelse(DS_ID == -1, 1, 0),
         Name = paste0('sub', ID)
           )

#milk
milksubs <- subs %>%
  filter(HUC04 == '1005') %>%
  pull(ID)

stmarysubs <- subs %>%
  filter(HUC04 == '0904') %>%
  pull(ID)

##########################################3
rvh <- rvn_rvh_read(rvh.infile)

HRUtable <- rvh$HRUtable

subtable <- rvh$SBtable

#get total wetland and water area by subbasin
water <- HRUtable %>%
  group_by(SBID) %>%
  summarize(TotalArea = sum(Area),
            WetlandArea = sum(Area[SoilProfile == 'WETLAND']),
            LakeArea = sum(Area[SoilProfile == 'LAKE'])) %>%
  mutate(WetlandFrac = round(WetlandArea/TotalArea,3),
         LakeFrac = round(LakeArea/TotalArea, 3))

#write_csv(water, 'tables/SB_water_summary.csv')

########################333
#reassign lake and wetland HRUs.  Lakes, glaciers, rocks can stay if in the hbv area.
#must reassign soilprofile


hbvhrus <- HRUtable %>% filter(Elevation > 1200) %>%
  #filter((SBID %in% milksubs & Elevation > 1200) | (SBID %in% stmarysubs & Elevation > 1400)) %>%
  pull(ID)

hyprhrus <- HRUtable %>% filter(!(ID %in% hbvhrus)) %>% pull(ID)

#land use only changes where we allow veg on lakes in hypr (assuming they would grow in in a natural state)
#soil profile changes for lakes and wetlands, glaciers and rocks (though nonexistent) in hypr, only for wetlands in hbv
HRUtable <- HRUtable %>% mutate(LandUse = ifelse(ID %in% hyprhrus & SoilProfile == 'LAKE', 'Shrubgrass', LandUse), 
                                SoilProfile = case_when(ID %in% hyprhrus & SoilProfile == 'LAKE' ~ 'Soil_1',
                                                        ID %in% hyprhrus & SoilProfile == 'WETLAND' ~ 'Soil_1',
                                                        ID %in% hyprhrus & SoilProfile == 'GLACIER' ~ 'Soil_1',
                                                        ID %in% hyprhrus & SoilProfile == 'ROCK' ~ 'Soil_1',
                                                        ID %in% hbvhrus & SoilProfile == 'WETLAND' ~ 'Soil_2',
                                                        TRUE ~ SoilProfile))
                                                    
  
#second level re-assignment based on calibration and discussions with James C/Bryan T (Oct/Nov)
#split soil 1 in half (stmary and milk) to make a new soil class (3)
#split shrubgrass in half (stmary and milk)
HRUtable <- HRUtable %>% mutate(LandUse = ifelse(SBID %in% stmarysubs & LandUse == 'Shrubgrass', 'Shrubgrass_StMary', LandUse),
                                Vegetation = LandUse,
                                SoilProfile = ifelse(SBID %in% milksubs & SoilProfile == 'Soil_1', 'Soil_3', SoilProfile))



#clean up hrus
#hypr model can run with way less hrus

#Protected HRUs
  #HRUs containing snow sites
  #hrus containing reservoirs
  #hrus containing other obs such as Evaporation?
  #dont know what these are yet
  # protected <- c(snow_sites,reservoirs)
#dont need to protect all lakes maybe?  only reservoirs?
glaciers <- HRUtable %>%
  filter(SoilProfile == 'GLACIER') %>%
  pull(ID)

#protect glaciers, snow surveys and cities
protected = c(glaciers, 340, 1390, 338, 118, 509, 436)

#using RVH.cleanHRUs in RavenR
HRUtabshort <- rvn_rvh_cleanhrus(HRUtable, rvh$SBtable, area_tol = 0.01,
                                 ProtectedHRUs = protected,
                                 merge = TRUE, elev_tol = 100, slope_tol = 15, aspect_tol = 30)




HRUtable <- HRUtabshort


rvn_rvh_write(rvh.outfile, rvh$SBtable, HRUtable)

#format milkhrus into string with newline character every 100
widther <- function(hruvec, width){
  
  lhru <- length(hruvec)
  lsplit <- floor(lhru/width)
  splitvec <- character()
  for (i in 1:lsplit){
    
    start <- (i-1)*width +1
    end <- i*width
    sub <- hruvec[start:end]
    out <- paste(paste(sub, collapse = ',', sep = " "), "\n")
    splitvec <- paste(splitvec, out)
  }
  final <- hruvec[(end+1):length(hruvec)]
  out <- paste(paste(final, collapse = ',', sep = " "), "\n")
  splitvec <- paste(splitvec, out)
  
  return(splitvec)
}





#st. mary only (huc = 0904)
stmaryhrus <- HRUtable %>% filter(SBID %in% stmarysubs) %>%
  pull(ID)

stmaryhru_collapse <- widther(stmaryhrus, 200)

#milk
milkhrus <- HRUtable %>% filter(SBID %in% milksubs) %>%
  pull(ID)


milkhru_collapse <- widther(milkhrus, 200)

#make hrugroups for model types
#hbv group = stmary and elevation above 1400 or milk and elev above 1200
#hypr group = everything else

hbvhrus <- HRUtable %>% filter((SBID %in% milksubs & Elevation > 1200) | (SBID %in% stmarysubs & Elevation > 1400)) %>%
  pull(ID)
hbv_collapse = widther(hbvhrus, 200) 

hyprhrus <- HRUtable %>% filter(!(ID %in% hbvhrus)) %>% pull(ID)
hypr_collapse <- widther(hyprhrus, 200)

#snow sites not known yet
# snowids <- snow_sites
cat(file=rvh.outfile, append=T, sep="", 
":HRUGroup Babb","\n",
  "118\n",
 ":EndHRUGroup","\n\n",
":HRUGroup Havre","\n",
  "509\n",
 ":EndHRUGroup","\n\n",
 ":HRUGroup Malta","\n",
  "436\n",
 ":EndHRUGroup","\n\n",
":HRUGroup ManyGlacier","\n",
  "340\n",
 ":EndHRUGroup","\n\n",
":HRUGroup RockyBoy","\n",
  "1390\n",
 ":EndHRUGroup","\n\n",
 ":HRUGroup FlatTop","\n",
  "338\n",
 ":EndHRUGroup","\n\n",
  ":HRUGroup HBVEC","\n",
  hbv_collapse,
  ":EndHRUGroup","\n\n",
  ":HRUGroup HYPR","\n",
  hypr_collapse,
  ":EndHRUGroup","\n\n",

   ":HRUGroup StMary","\n",
   paste(stmaryhrus,collapse = ','), "\n",
   ":EndHRUGroup","\n\n",
    ":HRUGroup Milk","\n",
    milkhru_collapse,
   ":EndHRUGroup","\n\n",
":HRUGroup Glaciers","\n",
paste(glaciers, collapse = ','),"\n",
":EndHRUGroup","\n\n",

    ":PopulateHRUGroup band600  With ELEVATION BETWEEN  600    800","\n",
    ":PopulateHRUGroup band800  With ELEVATION BETWEEN  800    1000","\n",
    ":PopulateHRUGroup band1000 With ELEVATION BETWEEN  1000 1200","\n",
    ":PopulateHRUGroup band1200 With ELEVATION BETWEEN  1200 1400","\n",
    ":PopulateHRUGroup band1400 With ELEVATION BETWEEN  1400 1600","\n",
    ":PopulateHRUGroup band1600 With ELEVATION BETWEEN  1600 1800","\n",
    ":PopulateHRUGroup band1800 With ELEVATION BETWEEN  1800 2000","\n",
    ":PopulateHRUGroup band2000 With ELEVATION BETWEEN  2000 2200","\n",
    ":PopulateHRUGroup band2200 With ELEVATION BETWEEN  2200 2400","\n",
    ":PopulateHRUGroup band2400 With ELEVATION BETWEEN  2400 2600","\n",
    ":PopulateHRUGroup band2600 With ELEVATION BETWEEN  2600 2800","\n",
    ":PopulateHRUGroup band2800 With ELEVATION BETWEEN  2800 3000","\n",
    "\n",
    "# contains reservoir data","\n",
    "#:RedirectToFile Reservoirs.rvh","\n",
    "# contains time to peak and time of concentration","\n",
    ":RedirectToFile SubBasinParams.rvh","\n\n"
  
)

#---------------------------------------------------------------
#need to shrink the gridweights file down
gridin <- read_table('model/alt_models/fullhbv/GridWeights.txt', skip = 7, col_names = F) %>%
  na.omit()

gridshort <- gridin %>% filter(X1 %in% HRUtabshort$ID)

gridout <- 'model/GridWeights.txt'

cat(file=gridout, append=F, sep="",
"  :GridWeights\n",
"    :NumberHRUs ", nrow(HRUtabshort),"\n",
"    :NumberGridCells 1938","\n",
"    #[HRU ID] [Cell #] [w_kl]\n")
write.table(gridshort, gridout,append=T,col.names=F,row.names=F,sep=" ",quote=F)
cat(file = gridout, append = T, 
    "    :EndGridWeights","\n")


#rvc file (initial conditions)
IniCond = data.frame(
  ID = HRUtable$ID,
  SOIL1 = 0.0,
  SNOW = 0.0,
  SNOW_LIQ = 0.0)


#-------------------------------------------------------------------------------
RVCoutFile = "./model/StMary_Milk.rvc"

cat(file=RVCoutFile, append=F, sep="",

    "#########################################################################","\n",
    ":FileType rvc ASCII Raven 3.7","\n",
    "# DataType         Raven Initial conditions file","\n",
    ":Application       R","\n",
    ":WrittenBy         Joel Trubilowicz","\n",
    ":CreationDate  ",    paste(Sys.time()),"\n",
    "#---------------------------------------------------------","\n",
    ":HRUStateVariableTable","\n",
    ":Attributes, SOIL[0], SNOW, SNOW_LIQ","\n",
    ":Units,           mm,   mm,   mm","\n")

write.table(IniCond,RVCoutFile,append=T,col.names=F,row.names=F,sep=",",quote=F)

cat(file=RVCoutFile, append=T, sep="",
    ":EndHRUStateVariableTable","\n"
  )


