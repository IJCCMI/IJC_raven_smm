library(RavenR)
read_hru_group <- function(file_location, hru_group_name)
{
  lines <- readLines(file_location,warn = F)
  hru_numbers <- c()
  capture_numbers <- FALSE
  for (line in lines)
  {
    if (grepl(paste0(":HRUGroup", " ", hru_group_name), line))
    {
      capture_numbers <- TRUE
      next
    }
    if (grepl(":EndHRUGroup", line) && capture_numbers)
    {
      capture_numbers <- FALSE
      break
    }
    if (capture_numbers)
    {
      elements <- unlist(strsplit(line, "[,\\s]+"))
      hru_numbers <- c(hru_numbers, as.numeric(elements))
    }
  }
  return(hru_numbers)
}

file_path<-"StMary_Milk.rvh"
HYPR<-read_hru_group(file_path, "HYPR")
Milk<-read_hru_group(file_path, "Milk")
rvh<-rvn_rvh_read(file_path)
HYPR_Milk_id<-HYPR[HYPR %in% Milk]
rvh$HRUtable$SoilProfile[rvh$HRUtable$ID %in% HYPR_Milk_id] <-"Soil_3"
rvn_rvh_write(filename = "StMary_Milk_new.rvh",
              SBtable = rvh$SBtable,
              HRUtable = rvh$HRUtable) # you can later manually add the hru groups

