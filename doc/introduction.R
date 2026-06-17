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

## -----------------------------------------------------------------------------
# compare Münster and Amsterdam
munster_classified <- classify_bike_infrastructure(munster)

## -----------------------------------------------------------------------------
data(amsterdam)
amsterdam_classified <- classify_bike_infrastructure(amsterdam)

## ----safety-map-amsterdam, fig.width = 12, fig.height = 5---------------------
plot_cycling_safety_map(munster_classified)
plot_cycling_safety_map(amsterdam_classified)

