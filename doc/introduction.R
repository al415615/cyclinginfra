## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo    = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width  = 7,
  fig.height = 4,
  out.width  = "100%"
)

## ----safety-map, fig.width = 12, fig.height = 5-------------------------------
library(cyclinginfra)

# load the pre-downloaded cycling network of Muenster
data(munster)
print(munster)
plot(munster)

# classify the infrastructure
munster_classified <- classify_bike_infrastructure(munster)
print(munster_classified)

# create the safety map
plot_cycling_safety_map(munster_classified)

## ----compare------------------------------------------------------------------
# compare Münster and Amsterdam
data(amsterdam)
amsterdam_classified <- classify_bike_infrastructure(amsterdam)
compare_cities(munster_classified, amsterdam_classified)

## ----connectivity-------------------------------------------------------------
analyze_connectivity(munster)

## ----real-usage, eval = FALSE-------------------------------------------------
# # download directly from OSM (requires internet connection)
# munster <- get_cycling_network("Muenster, Germany")
# print(munster)
# plot(munster)
# 
# munster_classified <- classify_bike_infrastructure(munster)
# print(munster_classified)
# plot_cycling_safety_map(munster_classified)
# 
# # compare with another city
# amsterdam <- get_cycling_network("Amsterdam, Netherlands")
# amsterdam_classified <- classify_bike_infrastructure(amsterdam)
# plot_cycling_safety_map(amsterdam_classified)
# 
# # side-by-side comparison of two cities
# compare_cities(munster_classified, amsterdam_classified)
# 
# # connectivity analysis
# analyze_connectivity(munster)

