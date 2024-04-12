#write the RVH file from the filled hru tables

library(tidyverse)
library(RavenR)
library(foreign)
library(dplyr)

model.files <- "./model/"

rvh.outfile <- paste0(model.files, 'StMary_Milk.rvh')

###########################################################

path <- './inputs/spatial/processed/'

subs <- read.dbf(paste0(path, 'smm_subbasins_cleaned.dbf'))

hrus <- read.dbf(paste0(path, 'smm_hrus_filled_R2.dbf'))

gaugeinfo <- read_csv('tables/naturalized_flows_summary.csv')

sum(hrus$Area)
###########################################################
#CREATE SUB TABLE
#Update Channel Lengths 

#dont yet know about gauging, make all ungauged except bottoms
subs <- subs %>%
  mutate(XSection = paste0('Chn_', subs$ID),
         DS_ID = ifelse(is.na(DS_ID), -1, DS_ID),
         Gauged = ifelse(DS_ID == -1, 1, 0),
         Name = paste0('sub', ID)
         )

#head(subs)

SBtable <- subs %>% dplyr::select(SBID = ID, 
                           Name = Name,
                        Downstream_ID = DS_ID,
                        Profile = XSection,
                        ReachLength = ChanLen,
                        Gauged = Gauged) %>%
  arrange(SBID)

#add all sbs that are in the naturalized flow dataset as gauged as well
#turn off non-contrib gauged too
#eventually turn that on to estimate 2-year flow to make overflow (reconnection of non-contributing areas)
SBtable <- SBtable %>%
  mutate(Gauged = ifelse(SBID %in% gaugeinfo$subbasin_id, 1, 0))


#################################################
#estimate time of concentration
#default toc formula from james craig (C code)
#t_conc = 0.76/24*pow(_basin_area,0.38); //in days, basin contributing area in km2
#tp = 0.33* toc as loose estimator
#use toc multiplier as calibration tool if necessary

toc <- subs %>% mutate(TOC = 0.76/24*(Area_km2)^0.38,
                       TP = 0.33*TOC,
                       SBID = ID) %>%
  select(SBID, TP, TOC) %>%
  mutate_if(is.numeric, function(x) round(x,5))

TOCoutFile <- paste0(model.files, "SubBasinParams.rvh")

cat(file=TOCoutFile, append=F, sep="",
"#########################################################################","\n",
":FileType rvh ASCII Raven 3.7","\n",
":Application       R","\n",
":WrittenBy         Joel Trubilowicz ","\n",
":CreationDate  ",    paste(Sys.time()),"\n",
"#---------------------------------------------------------","\n",
":SubBasinProperties","\n",
":Parameters		 TIME_TO_PEAK	 TIME_CONC","\n",
":Units 				 d             d","\n")
write.table(toc,TOCoutFile,append=T,col.names=F,row.names=F,sep=",",quote=F)
cat(file=TOCoutFile, append=T, sep="",
":EndSubBasinProperties","\n")
################################################

#############################################################
#hrus
hrus <- hrus %>%
    dplyr::mutate(Aquifer = '[NONE]', #only one now
                  Terrain = '[NONE]', #only one now
                  SBID = SUB_ID)

#pre-simpified at raster add point
# #write a lookup table for each of our categorical data
# 
# #HRU_Type is based on SoilProfile = special soil profiles = GLACIER, LAKE, ROCK, STANDARD
# # #format land use and vegetation into raven styles, based on Globcover
# 
# globlookup <- read_csv('./tables/LandCoverLookup.csv')
# 
# globlookup <- dplyr::distinct(globlookup,SimplifiedLandCover, .keep_all = TRUE)
# summary(globlookup)
# summary(hrus)
# # #separate landcover and veg into styles specified by globcover
# hrus <- left_join(hrus, globlookup, by = c('LandCover' = 'SimplifiedLandCover'))




HRUtable <- hrus %>%
  mutate(SoilProfile = case_when(LandCover == 'Water' ~ 'LAKE',
                                 LandCover == 'Open' ~ 'ROCK',
                                 LandCover == 'Glacier' ~ 'GLACIER',
                                 LandCover == 'Wetland' ~ 'WETLAND',
                                 TRUE ~ SoilClass),
         LandUse = case_when(LandCover == 'Water' ~ 'Open',
                              LandCover == 'Open' ~ 'Open',
                              LandCover == 'Glacier' ~ 'Open',
                              LandCover == 'Wetland' ~ 'Shrubgrass',
                              TRUE ~ as.character(LandCover)),
         Vegetation = case_when(LandUse == 'Water' ~ 'Open',
                      LandUse == 'Glacier' ~ 'Open',
                      LandUse == 'Wetland' ~ 'Open',
                      TRUE ~ LandUse),
         Terrain = '[NONE]',
         Slope = '[NONE]')

#Plot distribution
ggplot(HRUtable)+
  geom_bar(aes(x=SoilProfile, y= Area), stat = "identity")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


#CHeck area - should be in km2, 63633.79
sum(HRUtable$Area)
sum(subs$Area_km2)

#clean up fields - make sure Area is already in km2
HRUtable <- HRUtable %>%
  select(ID = HRU_ID, Area, Elevation = Elev, Latitude = Lat, Longitude = Lon, SBID = SUB_ID,
         LandUse, Vegetation, SoilProfile, Aquifer, Terrain, Slope = slope, Aspect = Aspect_CC) 


#some slivers dont have elevation, landuse or soils associated.  fill with default values, will be eliminated by RavenR next step anyways
#just need to avoid an error
HRUtable <- HRUtable %>%
  mutate(Elevation = ifelse(is.na(Elevation), mean(HRUtable$Elevation, na.rm = T), Elevation),
         LandUse = ifelse(is.na(LandUse), 'Shrubgrass', LandUse),
         Vegetation = ifelse(is.na(Vegetation), 'Shrubgrass', Vegetation),
         SoilProfile = ifelse(is.na(SoilProfile), 'Soil_1', SoilProfile))

rvn_rvh_write(rvh.outfile, SBtable, HRUtable)



##########################################3
#rvh <- rvn_rvh_read(rvh.outfile)
#clean up hrus
#August 2023 - start by not cleaning HRUS

#Protected HRUs
  #HRUs containing snow sites
  #hrus containing reservoirs
  #hrus containing other obs such as Evaporation?
  #dont know what these are yet
  # protected <- c(snow_sites,reservoirs)
#dont need to protect all lakes maybe?  only reservoirs?
#protect glaciers?
#protect wetlands?
watersites <- HRUtable %>%
  filter(SoilProfile == 'LAKE') %>%
  pull(ID)

wetlands <- HRUtable %>%
  filter(SoilProfile == 'WETLAND') %>%
  pull(ID)

glaciers <- HRUtable %>%
  filter(SoilProfile == 'GLACIER') %>%
  pull(ID)

# protected = c(watersites, wetlands, glaciers)
# 
# #using RVH.cleanHRUs in RavenR
# HRUtabshort <- rvn_rvh_cleanhrus(rvh$HRUtable, rvh$SBtable, area_tol = 0.01,
#                                  ProtectedHRUs = protected,
#                                  merge = TRUE, elev_tol = 100, slope_tol = 15, aspect_tol = 30)
# 
#    
# 
# 
# HRUtable <- HRUtabshort
# rvn_rvh_write(rvh.outfile, SBtable, HRUtable)

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


# Create HRU Groups
opensites <- HRUtable %>%
  filter(SoilProfile == 'ROCK') %>%
  pull(ID)


#st. mary only (huc = 0904)
stmarysubs <- subs %>%
  filter(HUC04 == '0904') %>%
  pull(ID)

stmaryhrus <- HRUtable %>% filter(SBID %in% stmarysubs) %>%
  pull(ID)

stmaryhru_collapse <- widther(stmaryhrus, 200)

#milk
milksubs <- subs %>%
  filter(HUC04 == '1005') %>%
  pull(ID)

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

#make an HRU group with all hrus for the lateral equilbrate command
all_collapse <- widther(HRUtable$ID, 200)

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
   stmaryhru_collapse,
   ":EndHRUGroup","\n\n",
    ":HRUGroup Milk","\n",
    milkhru_collapse,
   ":EndHRUGroup","\n\n",
   ":HRUGroup AllHRUs","\n",
   all_collapse,
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



