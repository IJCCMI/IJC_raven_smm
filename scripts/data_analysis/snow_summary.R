#compare snow surveys with corresponding hrus
library(tidyverse)
library(RavenR)
library(xts)

#get snow obs
fnames <- list.files('inputs/snow', pattern = '.csv')

reader <- function(fname){
  
  name <- str_remove(fname, '.csv')
  
  raw <- read_csv(file.path('inputs/snow', fname), skip = 67)
  
  dat <- raw[,1:2]
  names(dat) <- c('Date', 'obs')

  dat %>% mutate(obs = obs * 25.4,
                 Name = name)
  
  }

swe_obs <- map_df(fnames, reader)


#get snow sim
snow_t <- rvn_custom_read("model/output/SNOW_Daily_Average_ByHRUGroup.csv")
snow <- snow_t %>%
  as_tibble %>%
  mutate(Date = as.Date(index(snow_t))) %>%
  select(Date, RockyBoy, ManyGlacier, FlatTop) %>%
  pivot_longer(cols = c(RockyBoy, ManyGlacier, FlatTop),
               names_to = "Name",
               values_to = "sim")

#join together
swe_all <- snow %>%
  left_join(swe_obs, by = c('Date', 'Name')) %>%
  pivot_longer(cols = c(sim, obs), names_to = 'Source', values_to = 'SWE')


#make a plot
swe_all %>% 
  ggplot(aes(x = Date, y = SWE, color = Source)) +
  geom_line() +
  facet_wrap(~Name, ncol = 1, scales = 'free_y') +
  labs(x = 'Date', y = 'SWE (mm)') +
  theme_bw()
ggsave('outputs/swe_vs_model.png')

