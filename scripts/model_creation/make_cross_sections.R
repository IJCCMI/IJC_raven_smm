#Generate Cross Sections for Raven Model
#following methods used in Basinmaker (Hongren Shen)
#Based on Andreadis et al 2013 (A simple global river bankkfull width and depth database)


library(RavenR)
library(sf)
library(tidyverse)
library(fasterize)
library(raster)
library(exactextractr)

#Read in RVH file and Subbasin Shapefile 
model.files <- "./model/"
rvh <-rvn_rvh_read(paste0(model.files, 'StMary_Milk.rvh'))

#subbasins
subs_shp <- read_sf('./inputs/spatial/processed/smm_subbasins_cleaned.shp')

#shape provided by Brian Tolson to get constants k and c:
const <- read_sf('../../basinmaker/na_kc_zone_ply2/na_kc_zone_ply2.shp') %>%
  st_transform(st_crs(subs_shp))
  
#coarse raster to use as coordinate system
dem <- raster('inputs/spatial/ingeo/raster/smm_merit_dem.tif')

kras <- fasterize(const, dem, field = 'k')
cras <- fasterize(const, dem, field = 'c')


#add modal c and k to subbasins
subs_shp$k <- exact_extract(kras, subs_shp, 'mode', progress = T)
subs_shp$c <- exact_extract(cras, subs_shp, 'mode', progress = T)

#add k and c values to sbtable
kc <- subs_shp %>%
  dplyr::select(SBID = ID, k, c, seg_slope) %>%
  st_drop_geometry()

subs <- rvh$SBtable %>%
  left_join(kc, by = 'SBID')

#calculate maf using coeffs Q = kA^c
#Calculate width and depth from equation 2a and 2b in Andreadis

#as in basinmaker make min values for w and d
min_width = 0.1
min_d = 0.1

#min slope value too
#minimum slopes
min_slope = 0.001


subs <- subs %>%
  mutate(Q = k * TotalUpstreamArea ^c,
         W = 7.2 * Q ^0.3,
         d = 0.27 *Q ^0.3) %>%
  mutate(W = ifelse(W < min_width, min_width, W),
         d = ifelse(d < min_d, min_d, d),
         seg_slope = as.numeric(seg_slope),
         seg_slope = ifelse((is.na(seg_slope) | seg_slope < min_slope), min_slope, seg_slope))



#calculate roughness as in basinmaker
#calculateChannaln https://github.com/dustming/basinmaker/blob/master/basinmaker/func/pdtable.py#L3334 
subs <- subs %>% mutate(
                        zch = 2,
                        sidwd = zch*d,
                        botwd = W - 2 *sidwd,
                        Ach = botwd*d + 2*zch*d*d/2,
                        Pch = botwd + 2*d*(1+zch^2)^0.5,
                        Rch = Ach/Pch,  ### in meter
                        V = Q/Ach,
                        n = Rch^(2/3)*as.numeric(seg_slope)^(1/2)/V)

#as in basinmaker make max and min values for mannings n
#max value is too high for stmary milk though, decrease from 0.15 to 0.08
min_n = 0.025
max_n = 0.08


subs <- subs %>%
  mutate(n = case_when(n < min_n ~ min_n,
                       n > max_n ~ max_n,
                       is.na(n) ~ min_n,
                       TRUE ~ n))

#write sb table into tables
write_csv(subs, './tables/StMary_Milk_subbasin_properties.csv')

#Generate Profiles For Each Sub - based on SWAT trapezoidal channel. 
sink("./model/channel_sections.rvp")


for (i in 1:length(subs[,1])){
  #base trapezoidal channel
  xtrap <- c(0.00, subs$d[i]*2, subs$W[i]-subs$d[i]*2, subs$W[i])
  ytrap <- c(subs$d[i], 0.00, 0.00, subs$d[i])
  
  #pad middle and end with flat area
  xwide <- c(0.00, 0.00, (xtrap + subs$W[i]*2), (xtrap[4] + (subs$W[i] *4)), (xtrap[4] + (subs$W[i] *4)))
  ywide <- c(subs$d[i]+4, subs$d[i], ytrap, subs$d[i],subs$d[i]+4)
  
  # #make a test line
  # tibble(x = xwide, y = ywide) %>%
  #   ggplot(aes(x = x, y = y)) + 
  #   geom_line() +
  #   coord_equal()
  
  
  xsection <- cbind(xwide,ywide)
  xsection <- round(xsection,digits=2)
  cat(paste(":ChannelProfile Chn_", subs$SBID[i],"\n",sep=""))
  cat(paste("\t:Bedslope ", subs$seg_slope[i], "\n", sep=""))
  cat("\t:SurveyPoints\n\t\t")
  write.table(xsection,file="", sep="\t", quote = F, col.names=F, row.names=F, eol="\n\t\t")
  cat(":EndSurveyPoints\n\t")
  cat(":RoughnessZones\n\t\t")
  cat("0   ", subs$n[i], "\n\t")
  cat(":EndRoughnessZones\n")
  cat(":EndChannelProfile\n\n")
}
sink()

