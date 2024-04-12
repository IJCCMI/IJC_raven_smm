#populate the hru shapefile with spatial data
#joel trubilowicz, may 2023

library(tidyverse)
#library(raster)
library(terra)
library(sf)
library(fasterize)
library(viridis)
library(exactextractr)

#############################
#file names (grids are pre-clipped)
#subbasins
sub <- 'smm_subbasins_R1'
#hrus
hru <-  'smm_hrus_R2'
#outer basin
outer <- 'SMM_outer_Boundary'

gispath <- './inputs/spatial/'


hrus <- st_read(paste0(gispath, '/ingeo/', hru, '.shp')) %>%
  st_zm()

#make hru IDs
hrus$HRU_ID <- seq(1,length(hrus$POLY_AREA))

outer <- st_read(paste0(gispath, '/ingeo/', outer, '.shp')) %>%
  st_zm() 

#####################################################
#clean up subbasin data to only what is needed
subs <- st_read(paste0(gispath, '/ingeo/', sub, '.shp')) %>%
  st_zm()

#subbasin IDs to match those from 
nhm_seg_translate <- subs %>%
  dplyr::select(hru_nhm, seg_nhm) %>%
  st_drop_geometry() %>%
mutate(hru_nhm = ifelse(seg_nhm == 0, -1, hru_nhm)) %>%
  distinct(hru_nhm, seg_nhm)
write_csv(nhm_seg_translate, 'tables/nhm_seg_id_translate.csv')

subs$Area = st_area(subs)

subs <- subs %>%
  mutate(ID = hru_nhm,
         SUB_seg_ID = seg_nhm,
         DS_seg_ID = as.numeric(ds_seg_nhm),
         Area_km2 = round(Area/1000^2,2)) %>%
  dplyr::select(ID, 
                SUB_seg_ID,
         DS_seg_ID,
         ChanLen = LENGTH,
         seg_slope,
         HUC04,
         Area_km2) %>%
  #join doesnt work because you get many to
  left_join(nhm_seg_translate, by = c('DS_seg_ID' = 'seg_nhm')) %>%
  rename(DS_ID = hru_nhm)

write_sf(subs, paste0(gispath, 'processed/smm_subbasins_cleaned.shp'))

##################################################
#get centroids in LL
cents <-
  st_centroid(hrus) %>%
  st_transform(4326) %>%
  st_coordinates

hrus <- hrus %>%
  mutate(Lat = cents[,2],
         Lon = cents[,1])

#######################################################
#file names 
#aspect
aspect.file <- paste0(gispath, 'processed/smm_aspect.tif')
#dem
dem.file <-  paste0(gispath, 'ingeo/raster/smm_merit_dem.tif')
#slope
slope.file <-  paste0(gispath, 'processed/smm_merit_slope.tif')
# #########################

###########################################
#Analysis
#Start with HRU grid draped over subbasins (1km)

###########################################
#1 crop dem to watershed 
dem <- rast(dem.file) 
dem <- dem %>%
  crop(., ext(outer)) %>%
  mask(., outer)  
 


plot(dem)

#writeRaster(dem, dem.file)
#dem <- raster(dem.file)
# ###########################################
#
#
# ##########################################################################
# # #2 create slope raster
slope <- terrain(dem, v = 'slope', unit = 'degrees')
writeRaster(slope, slope.file, overwrite = T)
#slope <- raster(slope.file)

#plot(slope)
#summary(slope)
#########################################################################

#########################################################################
# #3 create aspect raster
aspect <- terrain(dem, v = 'aspect', unit = 'radians')
writeRaster(aspect, aspect.file, overwrite = T)
#aspect <- raster(aspect.file)

#plot(aspect)

#4 calculate northness and eastness
asp.val <- getValues(aspect)
#northness <- cos(asp.val)
#eastness <- sin(asp.val)
#north <- setValues(aspect, northness)
#east <- setValues(aspect, eastness)

#new style with terra
north = cos(aspect)
east = sin(aspect)
#####################################################################

#########################################################################
#2 add area, mean eastness, northness, elevation and slope to each polygon 
#hrus <- as_Spatial(hrus)

hrus$elevation <- exact_extract(dem, hrus, 'mean', progress = T)
hrus$northness <- exact_extract(north, hrus, 'mean', progress =T)
hrus$eastness <- exact_extract(east, hrus, 'mean', progress =T)
hrus$slope <- exact_extract(slope, hrus, 'mean', progress = T)
#########################################################################


#########################################################################
#intermediate cleanup
hrus.out <- hrus %>%
#  st_as_sf(.) %>%
  mutate(SUB_ID = hru_nhm) %>%
  dplyr::select(SUB_ID,
                HRU_ID,
                Lat, Lon,
                Elev = elevation,
                slope = slope,
                northness,
                eastness)

hrus.out$Area <- st_area(hrus.out)/10000

summary(hrus.out)

write_sf(hrus.out, paste0(gispath, 'processed/smm_hrus_terrain_R3.shp'))
# #################################################################
####################################################################################3


hrus <- st_read(paste0(gispath, 'processed/smm_hrus_terrain_R3.shp'))

##############################
#mode function for categorical data
# Mode <- function(x, na.rm = T) {
#   if(na.rm){
#     x = x[!is.na(x)]
#   }
# 
#   ux <- unique(x)
#   return(ux[which.max(tabulate(match(x, ux)))])
# }
#########################################

##############################################
##3 add modal landcover to each polygon
lc.file <- paste0(gispath, 'ingeo/raster/nalcms_clipped.tif')


#projectng and masking is pretty slow
lc <- rast(lc.file)
lc.proj <- project(lc, crs(hrus))
#lc.mask <- terra::mask(lc,proj, outer.shp)  
writeRaster(lc.proj, paste0(gispath, 'processed/nalcms_projected.tif'),overwrite = T)


# #map the landcover data to a factor
lc.legend <- read.csv('./tables/nalcms_classes.csv', stringsAsFactors = T)
lc.mat <- lc.legend %>%
  dplyr::select(Value, Simplified.Value) %>%
  mutate(Simplified.Value = as.integer(Simplified.Value))
# 
# #add integer class back on to table for future use
lc.legend <- lc.legend %>% mutate(Simplified.Class = lc.mat$Simplified.Value)
#write_csv(lc.legend, './tables/nalcms_classes.csv')
# 
# #reclassify based on table (slow)
lc.reclass <- classify(lc.proj, lc.mat, filename = paste0(gispath, 'processed/nalcms_simplified.tif'), overwrite = T)


#slow
hrus$lc <- exact_extract(x = lc.reclass, y = hrus, fun = 'mode', progress = T)

# #if it was in the water bodies table, also make into a lake. some lakes do not show up on modis
# hrus@data <- hrus@data %>%
#   mutate(lc = ifelse(Lake == T, 9, lc))

#change to a factor
hrus$LandCover <- factor(hrus$lc, 
                         levels = c(lc.legend$Simplified.Class), 
                         labels = c(lc.legend$Simplified.Value))

unique(hrus$LandCover)
##############################################


##############################################
##3 add modal soil to each polygon
soil.file <- paste0(gispath, 'ingeo/raster/soil_classes.tif')
soil <- rast(soil.file)%>%
  mask(., outer) 




#map the soil data to a factor
soil.legend <- read.csv('./tables/soil_classes.csv', stringsAsFactors = T)

soil.mat <- soil.legend %>%
  dplyr::select(Value, Simplified) %>%
  mutate(Simplified = as.integer(Simplified))

#add integer class back on to table for future use
soil.legend <- soil.legend %>% mutate(Simplified.Class = soil.mat$Simplified)
#write_csv(soil.legend, './tables/soil_classes.csv')

#reclassify based on table
soil.reclass <- classify(soil, soil.mat, filename = paste0(gispath, 'processed/soil_classes_simplified.tif'), overwrite = T)



hrus$soil <- exact_extract(soil.reclass, hrus, 'mode', progress = T)


#change to a factor
hrus$SoilClass <- factor(hrus$soil, 
                         levels = c(soil.legend$Simplified.Class), 
                         labels = c(soil.legend$Simplified))

unique(hrus$SoilClass)
##############################################




##############################################
# #6 calculate aspect in degrees for each polygon
hrus$Aspect <- NA


#if slope is NA, slope 0, and aspect 0
hrus <- hrus %>% 
  #st_as_sf(.) %>% 
  mutate(slope = ifelse(is.na(slope), 0, slope),
         Aspect = ifelse(is.na(northness) & is.na(eastness), 0, NA),
         northness = ifelse(is.na(northness), 0, northness),
         eastness = ifelse(is.na(eastness), 0, eastness),
         Aspect = 90 - 180/pi * atan2(northness, eastness),
         Aspect = ifelse(Aspect < 0, Aspect + 360, Aspect),
         Aspect.CC = 360-Aspect) #CC aspect per raven needs

#######################################################
#Calculate hru areas in km2
#hrus <- as_Spatial(hrus)

hrus$Area <- as.numeric(st_area(hrus)/1000/1000)

sum(hrus$Area)

total_area <- as.numeric(st_area(st_as_sf(outer))/1000/1000)

total_area

#Create Summary Plots to Check 

summary(hrus)
unique(hrus$LandCover)
#LAND COVER
ggplot()+
  geom_sf(data=hrus, aes(fill = LandCover), color = NA)+
  #scale_fill_manual(name = "Land Cover", values = c("darkgreen","lightgreen","gold","grey","blue","white","lightblue"), breaks = c("PacificForest","MontaneForest","Grassland","Barren","Water","Glacier","Snow"))+
  # geom_sf(data = outer, aes(), fill = NA)+
  theme_bw()+
  theme(panel.grid.major = element_blank())

ggplot()+
  geom_sf(data=hrus, aes(fill = SoilClass), color = NA)+
  theme_bw()+
  theme(panel.grid.major = element_blank())


# #Elevation
# ggplot()+
#   geom_sf(data=hrus, aes(fill = Elev), color = NA)+
#   scale_fill_viridis()+
#   theme_bw()+
#   theme(panel.grid.major = element_blank())
# #Slope
# ggplot()+
#   geom_sf(data=hrus, aes(fill = slope), color = NA)+
#   scale_fill_viridis()+
#   theme_bw()+
#   theme(panel.grid.major = element_blank())
# #Aspect
# ggplot()+
#   geom_sf(data=hrus, aes(fill = Aspect), color = NA)+
#   scale_fill_viridis()+
#   theme_bw()+
#   theme(panel.grid.major = element_blank())

# # #7 write it out
write_sf(hrus, paste0(gispath, '/processed/smm_hrus_filled_R2.shp'))
