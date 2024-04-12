#make a regime curve for the stmary and milk rivers
#JWT ECCC Sept 2023

#things to show:
# sim/naturalized flows (at lower part of basin)
# aep, pet
# precip
# snow storage
# depression storage  + lake storage?

library(tidyverse)
library(RavenR)
library(xts)
library(lubridate)

tab <- read.csv("tables/naturalized_flows_summary.csv")

#stations to actually use:
#stmary at intl boundary (113518) (1210 km2)
#milk at eastern crossing (114036) 11700 km2


hy <- rvn_hyd_read("model/output/Hydrographs.csv")


stmary_hyd <- rvn_hyd_extract(subs = paste0("sub", c(113518)), hyd = hy)
stmary_flow <- merge(stmary_hyd$sim, stmary_hyd$obs)
stmary_tab <- as_tibble(stmary_flow) %>%
  mutate(Date = index(stmary_flow),
         Basin = "StMary")

milk_hyd <- rvn_hyd_extract(subs = paste0("sub", c(114036)), hyd = hy)
milk_flow <- merge(milk_hyd$sim, milk_hyd$obs)
milk_tab <- as_tibble(milk_flow) %>%
  mutate(Date = index(milk_flow),
         Basin = "Milk")

flow <- rbind(stmary_tab, milk_tab)

area_stmary <- 1210 * 1000^2 #m2
area_milk <- 11700 * 1000^2

monthly_flow <- flow %>%
  mutate(Month = month(Date), Year = year(Date),
         sim = ifelse(Basin == "StMary",
                      sim * 86400 / area_stmary * 1000,
                      sim * 86400 / area_milk * 1000),
         obs = ifelse(Basin == "StMary",
                      obs * 86400 / area_stmary * 1000,
                      obs * 86400 / area_milk * 1000)) %>%
  group_by(Month, Year, Basin) %>%
  summarize(USGS = mean(obs, na.rm = TRUE),
            Raven = mean(sim, na.rm = TRUE)) %>%
  pivot_longer(cols = c(USGS, Raven), values_to = 'Flow', names_to = 'Source' )



#AET
aet_t <- rvn_custom_read("model/output/AET_Monthly_Average_ByHRUGroup.csv")
aet <- aet_t %>%
  as_tibble %>%
  mutate(Date = index(aet_t),
         Month = month(Date),
         Year = year(Date)) %>%
  select(Month, Year, StMary, Milk) %>%
  pivot_longer(cols = c(StMary, Milk), names_to = "Basin", values_to = "AET") %>%
  mutate(Source = 'Raven')

#PET
pet_t <- rvn_custom_read("model/output/PET_Monthly_Average_ByHRUGroup.csv")
pet <- pet_t %>%
  as_tibble %>%
  mutate(Date = index(pet_t),
         Month = month(Date),
         Year = year(Date)) %>%
  select(Month, Year, StMary, Milk) %>%
  pivot_longer(cols = c(StMary, Milk), names_to = "Basin", values_to = "PET") %>%
  mutate(Source = 'Raven')

# #Snow
# snow_t <- rvn_custom_read("model/output/Snow_Monthly_Average_ByHRUGroup.csv")
# snow <- snow_t %>%
#   as_tibble %>%
#   mutate(Date = index(snow_t),
#          Month = month(Date),
#          Year = year(Date)) %>%
#   select(Month, Year, StMary, Milk) %>%
#   pivot_longer(cols = c(StMary, Milk), names_to = "Basin", values_to = "Snow")
# 
# #Depression
# depression_t <- rvn_custom_read("model/output/DEPRESSION_Monthly_Average_ByHRUGroup.csv")
# depression <- depression_t %>%
#   as_tibble %>%
#   mutate(Date = index(snow_t),
#          Month = month(Date),
#          Year = year(Date)) %>%
#   select(Month, Year, StMary, Milk) %>%
#   pivot_longer(cols = c(StMary, Milk),
#                names_to = "Basin",
#                values_to = "Depression")

#precip (could do rainfall and snowfall)
precip_t <- rvn_custom_read("model/output/PRECIP_Monthly_Average_ByHRUGroup.csv")
precip <- precip_t %>%
  as_tibble %>%
  mutate(Date = index(precip_t),
         Month = month(Date),
        Year = year(Date)) %>%
  select(Month, Year, StMary, Milk) %>%
  pivot_longer(cols = c(StMary, Milk),
               names_to = "Basin",
               values_to = "Precipitation") %>%
  mutate(Source = 'RDRS total precip')

#snow
snow_t <- rvn_custom_read("model/output/SNOWFALL_Monthly_Average_ByHRUGroup.csv")
snow <- snow_t %>%
  as_tibble %>%
  mutate(Date = index(snow_t),
         Month = month(Date),
        Year = year(Date)) %>%
  select(Month, Year, StMary, Milk) %>%
  pivot_longer(cols = c(StMary, Milk),
               names_to = "Basin",
               values_to = "Precipitation") %>%
  mutate(Source = 'Snow')

#snow
rain_t <- rvn_custom_read("model/output/RAINFALL_Monthly_Average_ByHRUGroup.csv")
rain <- rain_t %>%
  as_tibble %>%
  mutate(Date = index(rain_t),
         Month = month(Date),
         Year = year(Date)) %>%
  select(Month, Year, StMary, Milk) %>%
  pivot_longer(cols = c(StMary, Milk),
               names_to = "Basin",
               values_to = "Precipitation") %>%
  mutate(Source = 'rain')

allpp <- rbind(rain, snow, precip)

#combine them all together
alldat <- monthly_flow %>%
  full_join(aet, by = c("Year", "Month", "Basin", 'Source')) %>%
  full_join(pet, by = c("Year", "Month", "Basin", 'Source')) %>%
  full_join(precip, by = c("Year", "Month", "Basin", 'Source'))# %>%
  #full_join(allpp, by = c("Year", "Month", "Basin", 'Source'))

#convert to only 12 values, cut off spin up
sumdat <- alldat %>%
  filter(Year > 2000, Year < 2014) %>%
  group_by(Month, Basin, Source) %>%
  summarize(across(Flow:Precipitation, ~mean(.x, na.rm = T))) %>%
  pivot_longer(cols = c(-Month, -Basin, -Source), names_to = "Var", values_to = "mm")# %>%
  #convert to total mm per month
  

#add in the observations of modis precipip
  #aet modis
  #units are 0.1mm (per 8 days)
et_modis <- read_csv('inputs/earth_engine/modis_aet.csv') %>%
  mutate(#daymo = lubridate::days_in_month(month),
         stmary_mm = `St. Marys` /10/8,
         milk_mm = `Milk`  /10/8) %>%  
  select(Month = month, Milk = milk_mm, StMary = stmary_mm) %>%
  pivot_longer(cols = c(Milk, StMary), names_to = 'Basin', values_to = 'mm') %>%
  mutate(Var = 'AET', Source = 'MODIS')

sumdat <- rbind(sumdat, et_modis) %>%
  mutate(daymo = lubridate::days_in_month(Month), 
         mm = mm*daymo,
         Month = as_factor(Month),
         Var = factor(Var, levels = c('PET', 'AET', 'Precipitation', 'Flow')))

# sumdat %>%
#   #showing storage in depression and snow doesnt make sense, not really a flux
#   #filter(!(Var %in% c("Depression", "Snow"))) %>%
#   ggplot(aes(x = Month, y = mm, color = Source)) + 
#   geom_line() +
#   facet_wrap(~Basin, ncol = 1) +
#   theme_bw() +
#   scale_color_brewer(type = "qual", palette = 6)


#nicer plots for report
#completely split by watershed

#panels for flow (sim/obs), AET(sim/obs), precip/pet



sumdat %>% filter(Basin == 'StMary') %>%
  ggplot(aes(x = Month, y = mm, fill = Source)) +
  facet_wrap(~Var, nrow = 1) +
  geom_col(position = 'dodge') +
  theme_bw() +
  labs(y = 'mm/Month') +
  ggtitle('St. Mary River')
ggsave('outputs/waterbalance_stmary.png', width = 8, height = 2)

#separately show precip type across whole watershed by month



