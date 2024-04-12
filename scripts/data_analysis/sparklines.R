#make sparklines of all the stations
#active or more than 10 years of data
#from real watersheds (not canals)

#may need to remove overlapping stations

library(tidyverse)
library(tidyhydat)
library(dataRetrieval)
library(ggthemes)
library(ggmap)
library(sf)
library(ggrepel)

usgs <- read_csv('tables/usgs_metadata.csv')
wsc <- read_csv('tables/wsc_meta_keep.csv')

#get the daily data and save as RDS files
wsc_dly <- hy_daily_flows(wsc$STATION_NUMBER)
saveRDS(wsc_dly, 'inputs/obs/wsc_daily_all.RDS')

usgs_dly <- readNWISdv(siteNumbers = usgs$ID, parameterCd = '00060')
saveRDS(usgs_dly, 'inputs/obs/usgs_daily_all.RDS')


wsc_dly <- readRDS('inputs/obs/wsc_daily_all.RDS')
usgs_dly <- readRDS('inputs/obs/usgs_daily_all.RDS')

#make data coverage for just st mary

wsc.sm <- wsc_dly %>%
  filter(substr(STATION_NUMBER, 1, 4) == '05AE') %>%
  select(ID = STATION_NUMBER, Date, Value) %>%
  left_join(select(wsc, ID = STATION_NUMBER, Name = STATION_NAME))

usgs.sm.id <- usgs %>%
  filter(substr(as.character(HUC), 1, 4) == '1001')

usgs.sm <- usgs_dly %>%
  filter(site_no %in% usgs.sm.id$ID) %>%
  select(ID = site_no, Date, Value = X_00060_00003) %>%
  mutate(Value = Value * 0.0283168) %>%
  left_join(select(usgs, ID, Name))

all <- rbind(wsc.sm, usgs.sm)

#only WSC data on st.mary river

all %>%
  mutate(FN = paste(ID, '-', Name)) %>%
  ggplot(aes(x = Date, y = Value)) +
  facet_grid(FN ~ ., scales = "free_y") + 
  geom_point(size=0.1) + 
  theme_tufte(base_family = 'sans') + 
  theme(axis.title=element_blank(), 
        axis.text.y = element_blank(), axis.ticks = element_blank()) +
  theme(strip.text.y = element_text(angle = 0, vjust=0.2, hjust=0)) +
  ggtitle('St. Mary River')
ggsave('scratch/stm_data.png', width = 7.5, height = 3.5)



wsc.milk <- wsc_dly %>%
  filter(substr(STATION_NUMBER, 1, 4) != '05AE') %>%
  select(ID = STATION_NUMBER, Date, Value) %>%
  left_join(select(wsc, ID = STATION_NUMBER, Name = STATION_NAME))

usgs.milk.id <- usgs %>%
  filter(substr(as.character(HUC), 1, 4) != '1001')

usgs.milk <- usgs_dly %>%
  filter(site_no %in% usgs.milk.id$ID) %>%
  select(ID = site_no, Date, Value = X_00060_00003) %>%
  mutate(Value = Value * 0.0283168) %>%
  left_join(select(usgs, ID, Name))

all.milk <- rbind(wsc.milk, usgs.milk)

#need to remove duplicates
meta <- rbind(select(usgs, ID, Name),
              select(wsc, ID = STATION_NUMBER, Name = STATION_NAME))

#keep usgs gauge as default since RT data is easier to get
dup <- c('11AB107', '11AE006','11AE007', '11AA031','11AE005', '11AE009', '11AA033', '11AD001', '11AB105')

all.milk <- all.milk %>%
  filter(!(ID %in% dup))


milk.nmes <-
  tibble(ID = unique(all.milk$ID)) %>%
  left_join(meta, by = 'ID')

allmeta <- wsc %>%
  mutate(Active = ifelse(HYD_STATUS == 'ACTIVE', T, F)) %>%
  select(ID = STATION_NUMBER, Name = STATION_NAME, Lat = LATITUDE, Lon = LONGITUDE, Area = DRAINAGE_AREA_GROSS, Active) %>%
  rbind(select(usgs, ID, Name, Lat, Lon, Area, Active)) %>%
  filter(!(ID %in% dup))


milknamed <- c('06132200', '11AA001', '11AA005', '06135000', '06168500', '06154500', '06174500', '06140500')

#important to me not on mainstem
tribs <- c('11AB027', '11AC041', '11AB006', '06133500', '06132200', '06154500', '06168500')

mainstem <- allmeta %>% 
  filter(substr(Name, 1, 4) == 'Milk' | substr(Name, 1, 4) == 'MILK') %>%
  arrange(Area) %>% 
  mutate(FN = paste(ID, '-', Name))

all.milk <- all.milk %>%
  mutate(FN = paste(ID, '-', Name))

all.milk$FN = factor(all.milk$FN, levels = mainstem$FN)


#mainstem river coverage
all.milk %>%
  filter(ID %in% mainstem$ID) %>%
  ggplot(aes(x = Date, y = Value)) +
  facet_grid(FN ~ ., scales = "free_y") + 
  geom_point(size=0.1) + 
  theme_tufte(base_family = 'sans') + 
  theme(axis.title=element_blank(), 
        axis.text.y = element_blank(), axis.ticks = element_blank()) +
  theme(strip.text.y = element_text(angle = 0, vjust=0.2, hjust=0)) +
  ggtitle('Milk River - Mainstem Gauges')
ggsave('scratch/milk_data.png', width = 7.5, height = 4.5)

#tribs
all.milk %>%
  filter(ID %in% tribs) %>%
  mutate(FN = paste(ID, '-', Name)) %>%
  ggplot(aes(x = Date, y = Value)) +
  facet_grid(FN ~ ., scales = "free_y") + 
  geom_point(size=0.1) + 
  theme_tufte(base_family = 'sans') + 
  theme(axis.title=element_blank(), 
        axis.text.y = element_blank(), axis.ticks = element_blank()) +
  theme(strip.text.y = element_text(angle = 0, vjust=0.2, hjust=0)) +
  ggtitle('Milk River - Major Tributaries')
ggsave('scratch/milk_tribdata.png', width = 7.5, height = 3.5)

