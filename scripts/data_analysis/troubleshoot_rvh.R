#random troubleshooting diagnostics
#jwt june 2023

library(igraph)

SubBasinTab = SBtable
HRUtab = HRUtable




#calculate total upstream area
links<-data.frame(SBID=SBtab$SBID,downID=SBtab$Downstream_ID)
links<-subset.data.frame(links,downID>=0) # get rid of -1


#which dsid arentin us

for (j in 1:nrow(links)) {
  
  if(links[j,2] %in% links[,1] == F) {print(links[j,])}
  
}


#create network graph structure
net <- graph_from_data_frame(d=links, vertices=SBtab, directed=TRUE)
egon <- ego(net,order=100, nodes=V(net),mode="in")
# size <- ego_size(net,order=100, nodes=V(net),mode="in")
count=1
for (i in 1:nrow(SBtab)){
  SBID = SBtab$SBID[i]
  up <- subset.data.frame(SBtab, SBID %in% as_ids(egon[[i]]))
  SBtab$TotalUpstreamArea[i] <- sum(up$Area)
  count=count+1
}