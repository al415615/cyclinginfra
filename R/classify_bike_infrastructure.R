# R/classify_bike_infrastructure.R

utils::globalVariables(c("infra_type", "total_length_km"))

# Function 2: classify_bike_infrastructure()
# Classifies each segment in a cycling_network by safety level and returns a cycling_classification instance.
 
#' Classify cycling segments by infrastructure type
#'
#' Takes a `cycling_network` instance and assigns each road segment to 
#' one of the five ordered safety levels based on its OpenStreetMap tags. Returns a 
#' `cycling_classification` instance that extends the input with the
#' classification and aggregate length statistics.
#'
#' **Safety levels** (best → worst):
#' \describe{
#'   \item{dedicated track}{Physically separated from motor traffic
#'     (`highway=cycleway`, `cycleway=track`).}
#'   \item{footway track}{Shared path with pedestrians, still separated from
#'     cars (`bicycle=designated`).}
#'   \item{painted lane}{Bike lane painted on the road
#'     (`cycleway=lane`, `cycleway=opposite_lane`, `cycleway=opposite`).}
#'   \item{shared lane}{Lane shared with cars, light marking only
#'     (`cycleway=shared_lane`).}
#'   \item{shared road}{Bikes permitted on normal road, no dedicated space
#'     (`bicycle=yes`).}
#' }
#' 
#' @importFrom stats aggregate reorder
#'
#' @param network A `cycling_network` instance returned by
#'   `get_cycling_network()`.
#'
#' @return A `cycling_classification` instance.
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' cl  <- classify_bike_infrastructure(net)
#' print(cl)
#' summary(cl)
#' plot(cl)
#' }
#'
#' @export
classify_bike_infrastructure <- function(network) {
  
  # input validation (same as in the contructor)
  if (!inherits(network, "cycling_network")) {
    stop("`network` must be a `cycling_network` object",
        "Use get_cycling_network() first.", call. = FALSE)
  }
  
  lines <- network$lines
  
  # classify each segment based on OSM tags
  lines$infra_type <- dplyr::case_when(

    # LEVEL 1: lane completely separated from traffic
    lines$osm_tag == "highway=cycleway"       ~ "dedicated track",
    lines$osm_tag == "cycleway=track"         ~ "dedicated track",
    lines$osm_tag == "cycleway=opposite_track" ~ "dedicated track",
    # LEVEL 2: bike lane next to pedestrian lane (Muenster Radwege)
    lines$osm_tag == "bicycle=designated"     ~ "footway track",
    # LEVEL 3: bike lane painted on road
    lines$osm_tag == "cycleway=lane"          ~ "painted lane",
    lines$osm_tag == "cycleway=opposite_lane" ~ "painted lane",
    lines$osm_tag == "cycleway=opposite"      ~ "painted lane",
    # LEVEL 4: bikes and cars no separation
    lines$osm_tag == "cycleway=shared_lane"   ~ "shared lane",
    # LEVEL 5: bike allowed in normal road
    lines$osm_tag == "bicycle=yes"            ~ "shared road",
    TRUE ~ "unknown"
  )
  
  # summary statistics: total length (SUM operation) in km per infrastructure type
  # st_length() returns length in m for projected CRS
  lines$length_m <- as.numeric(sf::st_length(lines))
  
  summary_stats <- aggregate(
    length_m ~ infra_type,
    data = lines,
    FUN  = function(x) round(sum(x) / 1000, 2)  # convert m to km
  )
  names(summary_stats) <- c("infra_type", "total_length_km")
  
  # sort by total length descending (predominant infrastructure type first)
  summary_stats <- summary_stats[order(-summary_stats$total_length_km), ]
  
  # return the cycling_classification instance
  new_cycling_classification(
    network          = network,
    classified_lines = lines,
    summary_stats    = summary_stats
  )
}
