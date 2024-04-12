#cumulative graphs for havre, babb, malta
library(tidyverse)
library(RavenR)
library(rnoaa)
library(xts)
library(ggpubr)

#get the noaa data
key = "gUBQxqsIaMPuBrtYOYRpLViPCvqWEAoC"
options(noaakey = key)

#get location ids
#allstns <- ghcnd_stations()



#search in station list for sites we are interested in
sites <- tibble(Names = c('Havre', 'Babb', 'Malta'),
                Lat = c(48.548, 48.867,48.356),
                Lon = c(-109.676, -113.437,-107.872))

# stns <- meteo_nearby_stations(lat_lon_df = sites, lat_colname = 'Lat', lon_colname = 'Lon', station_data = allstns, radius = 100)
# 
# babb <- grep('BABB', allstns$name)
# babbpp <- allstns[babb,] %>%
#   filter(state == 'MT',
#          element == 'PRCP')
# 
# havre <- grep('HAVRE', allstns$name)
# havrepp <- allstns[havre,] %>%
#   filter(state == 'MT',
#          element == 'PRCP')
# 
# malta <- grep('MALTA', allstns$name)
# maltapp <- allstns[malta,] %>%
#   filter(state == 'MT',
#          element == 'PRCP')
# 
# #choose best stations to take
# 
# best <- rbind(maltapp[4,], havrepp[5,], babbpp[2,]) %>%
#   mutate(shortname = c('Malta', 'Havre', 'Babb'))
# 
# getdat <- function(id, shortname, ...){
#   
#   dat <- ghcnd(id)
#   
#   wide <- dat %>% filter(element == 'PRCP', year >= 1980) %>%
#     select(id, year, month, starts_with('VALUE'))
# 
#   #make long
#   out <- wide %>% pivot_longer(cols = starts_with('VALUE'),
#                                names_to = 'day',
#                                values_to = 'PP') %>%
#     na.omit() %>%
#     mutate(day = as.numeric(str_remove(day, 'VALUE'))) %>%
#     select(Year = year, Month = month, Day = day, PP, id) %>%
#     mutate(Name = shortname)
#   
# }

#what units is this precip in?
#https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
#indicates tenths of mm
# ppdat <- pmap_df(list(best$id, best$shortname), getdat) %>%
#   mutate(PP = PP/10)
# saveRDS(ppdat, 'outputs/mt_precip_data.RDS')

ppdat <- readRDS('outputs/mt_precip_data.RDS')
#read in raven precip
precip_t <- rvn_custom_read("model/output/PRECIP_Daily_Average_ByHRUGroup.csv")
precip <- precip_t %>%
  as_tibble %>%
  mutate(Date = index(precip_t),
         Month = month(Date),
        Year = year(Date), 
        Day = day(Date)) %>%
  select(Day, Month, Year, Malta, Havre, Babb) %>%
  pivot_longer(cols = c(Malta, Havre, Babb),
               names_to = "Name",
               values_to = "PP.sim")


allpp <- full_join(ppdat, precip, by = c('Day', 'Month', 'Year', 'Name'))


#make cumulative graph
allpp %>%
  na.omit() %>%
  group_by(Name) %>%
  mutate(PP.obs = cumsum(PP),
         PP.rdrs = cumsum(PP.sim)) %>%
  ggplot(aes(x = PP.obs, y = PP.rdrs)) +
  geom_point() +
  facet_wrap(~Name) +
  stat_smooth(method = 'lm', se = F, formula = y~ x-1)+
  stat_regline_equation(formula = y~x-1) +
  coord_equal() +
  geom_abline(slope = 1) +
 #lims(x = c(0,25000), y = c(0,25000)) +
  theme_bw()
ggsave('outputs/precip_doublemass_v2.png', width = 6, height = 3)


#just try havre annual
allpp %>%
  na.omit() %>%
  filter(Name == 'Havre', Year %in% c(2000:2010)) %>%
  group_by(Year) %>%
  mutate(PP.obs = cumsum(PP),
         PP.rdrs = cumsum(PP.sim)) %>%
  ggplot(aes(x = PP.obs, y = PP.rdrs)) +
  geom_point() +
  facet_wrap(~Year) +
  stat_smooth(method = 'lm', se = F, formula = y~ x-1)+
  stat_regline_equation(formula = y~x-1) +
  coord_equal() +
  geom_abline(slope = 1) +
  #lims(x = c(0,25000), y = c(0,25000)) +
  theme_bw()

#just try havre monthly
allpp %>%
  na.omit() %>%
  filter(Name == 'Havre', Year %in% c(2000:2010)) %>%
  group_by(Month) %>%
  mutate(PP.obs = cumsum(PP),
         PP.rdrs = cumsum(PP.sim)) %>%
  ggplot(aes(x = PP.obs, y = PP.rdrs)) +
  geom_point() +
  facet_wrap(~Month) +
  stat_smooth(method = 'lm', se = F, formula = y~ x-1)+
  stat_regline_equation(formula = y~x-1) +
  coord_equal() +
  geom_abline(slope = 1) +
  #lims(x = c(0,25000), y = c(0,25000)) +
  theme_bw()


#density to investigate trace values
allpp %>%
  pivot_longer(cols = c(PP, PP.sim), names_to = 'source', values_to = 'mm')  %>%
  ggplot(aes(x = mm, color = source)) +
  geom_density() +
  facet_wrap(~Name) +
  scale_x_log10()


#summing of values < 0.5mm
allpp %>%
  pivot_longer(cols = c(PP, PP.sim), names_to = 'source', values_to = 'mm')  %>%
 filter(mm < 0.5) %>%
  group_by(Name, source) %>%
  summarize(sum = sum(mm), n = n())

