#get metadata for usgs gauges in SMM
#combine with canadian metadata from Jamie K.
#JWT August 2022

library(tidyverse)
library(tidyhydat)
library(dataRetrieval)
library(lubridate)
library(sf)

#6 digit hucs of st.mary and milk in usa
hucs <- c("10010001", 
          "10010002", 
          "10050001",
          "10050002",
          "10050003",
          "10050004",
          "10050005",
          "10050006",
          "10050007",
          "10050008",
          "10050009",
          "10050010",
          "10050011",
          "10050012",
          "10050013",
          "10050014",
          "10050015",
          "10050016")


#discharge code
pcode <- "00060"

#search for sites
sites1 <- whatNWISdata(huc = hucs[1:10], parameterCd = pcode)
sites2 <- whatNWISdata(huc = hucs[11:18], parameterCd = pcode) 

sites <- rbind(sites1, sites2)

#get drainage area and contributing drainage area from here
sitesinfo <- readNWISsite(sites$site_no) %>%
  mutate(Area = round(drain_area_va * 2.58999, 1),
         Area_contrib = round(contrib_drain_area_va * 2.58999, 1)) %>%
  select(ID = site_no,
         Area,
         Area_contrib)

#things we want:
#id, name, state,huc code, lat, lon, elev, drainage area, contrib drainage area, start date, end date

sitemeta <- sites %>%
  select(ID = site_no,
         Name = station_nm,
         HUC = huc_cd,
         Lat = dec_lat_va,
         Lon = dec_long_va,
         Elev = alt_va,
         start = begin_date,
         end = end_date,
         count = count_nu) %>%
  mutate(Elev = round(Elev * 0.3048, 0)) %>%
  left_join(sitesinfo, by = 'ID')

#need to group multiple segments of same sites
#keep sites with more than 10 years of data or active in 2022
sitemeta_shrt <- sitemeta %>%
  group_by(ID, Name, HUC, Lat, Lon, Elev, Area, Area_contrib) %>%
  summarize(start = min(start),
            end = max(end),
            count = sum(count)) %>%
  mutate(Active = ifelse(year(end) == 2022, T, F)) %>%
  filter(((year(end) - year(start)) >= 30 | Active == T) & is.na(Area) == F)
write_csv(sitemeta_shrt, 'tables/usgs_metadata.csv')

# #write as kml
# usgs_sp <- st_as_sf(sitemeta_shrt, coords = c("Lon", "Lat"))
# write_sf(usgs_sp, 'output/usgs_meta.kml')


#clean up wsc data too
wscids <- foreign::read.dbf('inputs/spatial/eccc/SMM_Stations.dbf')$Station_Nu

wscmeta <- hy_stations(wscids)
wscrange <- hy_stn_data_range(wscids) %>%
  filter(DATA_TYPE == 'Q')

wscmeta <- wscmeta %>%
  left_join(wscrange, by = 'STATION_NUMBER')

wscmeta_shrt <- wscmeta %>%
  filter((Year_to - Year_from >= 30 | HYD_STATUS == 'Active') & DRAINAGE_AREA_GROSS > 0)
write_csv(wscmeta_shrt, 'tables/wsc_meta_keep.csv')

#kml of real hydrology stns in canada
library(sf)

wsc <- read_sf('./inputs/spatial/eccc/SMM_Stations.shp')

# wsc.shrt <- wsc %>%
#   filter(Station_Nu %in% wscmeta_shrt$Station_Nu)
# write_sf(wsc.shrt, 'output/wsc_meta.kml')         
