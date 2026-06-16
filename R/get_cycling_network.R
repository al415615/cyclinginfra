
# R/get_cycling_network.R
# Function 1: get_cycling_network()
# Downloads all cycling related OSM ways for a city and returns a cycling_network instance.
 
#' Download the cycling network of a city from OpenStreetMap
#'
#' Queries the Overpass API via `osmdata` for cycling related way features
#' within a square bounding box centred on the requested city. Results are saved in cache to disk as `.rds` files so repeated calls do not download data all over again.
#'
#' @param city A single non-empty character string passed to
#'   [osmdata::getbb()], for instance, `"Muenster, Germany"`.
#' @param crs A single numeric EPSG code for the output CRS. Defaults to
#'   `4326` (WGS 84).
#' @param bbox_km Radius (in km) of the square bounding box around the city
#'   centre. Defaults to `5`.
#'
#' @return An instance of class `cycling_network` (a list with components `city`, `lines`, and `download_date`).
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' print(net)
#' plot(net)
#' }
#'
#' @export
get_cycling_network <- function(city, crs = 4326, bbox_km = 5) {
    
    # input validation (same as in the constructor)
    if (!is.character(city) || length(city) != 1 || nchar(city) == 0) {
    stop("`city` must be a single non-empty character string, ", "e.g. 'Muenster, Germany'.", call. = FALSE)
    }
    if (!is.numeric(crs) || length(crs) != 1) {
   stop("`crs` must be a single numeric EPSG code, e.g. 4326.", call. = FALSE)    }
    if (!is.numeric(bbox_km) || length(bbox_km) != 1 || bbox_km <= 0) {
      stop("`bbox_km` must be a positive number indicating the radius in km", "e.g. 5", call. = FALSE)
    }
  

    # cache: if we already have the file in the cache, no need to calculate again (Muenster is executed twice)
    cache_file <- paste0(gsub("[^a-zA-Z0-9]", "_", city), "_", bbox_km, "km_cycling.rds")
    
    if (file.exists(cache_file)) {
      message("Loading cached data for: ", city)
      return(readRDS(cache_file))
    }
    
    message("Downloading cycling network for: ", city)

    # find the center of the city we are interested in
    centre <- tryCatch(
      osmdata::getbb(city, format_out = "matrix"),
      error = function(e) stop("Could not find city '", city, "' in OpenStreetMap.")
    )

    # establish the boundary
    lon_centre <- mean(centre["x", ])
    lat_centre <- mean(centre["y", ])

    delta_lat <- bbox_km / 111
    delta_lon <- bbox_km / (111 * cos(lat_centre * pi / 180))
      
    bbox <- c(
      left   = lon_centre - delta_lon,
      bottom = lat_centre - delta_lat,
      right  = lon_centre + delta_lon,
      top    = lat_centre + delta_lat
    )
    
    # create the bounding box query for the given city
    q <- osmdata::opq(bbox = bbox, timeout = 120) 
    
    # One query with multiple features (this is to avoid timeout when I make too many queries)
    raw <- osmdata::osmdata_sf(
      osmdata::add_osm_features(q, features = list(
        "highway"  = "cycleway",
        "cycleway" = "lane",
        "cycleway" = "track",
        "cycleway" = "shared_lane",
        "cycleway" = "opposite",
        "cycleway" = "opposite_lane",
        "cycleway" = "opposite_track",
        "bicycle"  = "designated",
        "bicycle"  = "yes"
      ))
    )$osm_lines

    
    if (is.null(raw) || nrow(raw) == 0) {
      stop("No cycling infrastructure found for '", city, "'.", call. = FALSE)
    }
    
    # Assign osm_tag 
    raw$osm_tag <- dplyr::case_when(
      !is.na(raw$highway)  & raw$highway  == "cycleway"        ~ "highway=cycleway",
      !is.na(raw$cycleway) & raw$cycleway == "track"           ~ "cycleway=track",
      !is.na(raw$cycleway) & raw$cycleway == "opposite_track"  ~ "cycleway=opposite_track",
      !is.na(raw$cycleway) & raw$cycleway == "lane"            ~ "cycleway=lane",
      !is.na(raw$cycleway) & raw$cycleway == "opposite_lane"   ~ "cycleway=opposite_lane",
      !is.na(raw$cycleway) & raw$cycleway == "opposite"        ~ "cycleway=opposite",
      !is.na(raw$cycleway) & raw$cycleway == "shared_lane"     ~ "cycleway=shared_lane",
      !is.na(raw$bicycle)  & raw$bicycle  == "designated"      ~ "bicycle=designated",
      !is.na(raw$bicycle)  & raw$bicycle  == "yes"             ~ "bicycle=yes",
      TRUE ~ "other"
    )
    
    # Filter just recognized tag
    all_lines <- raw[raw$osm_tag != "other", c("osm_tag", "geometry")]

    # check that we got some data back
    if (is.null(all_lines) || nrow(all_lines) == 0) {
      stop("No cycling infrastructure found for '", city, "'. ")
    }
    
    # keep only geometrically valid LINESTRINGS
    all_lines <- all_lines[sf::st_is_valid(all_lines), ]
    
    # transform to the CRS specified
    all_lines <- sf::st_transform(all_lines, crs = crs)
    
    # save in the cache so it can be accessed
    result <- new_cycling_network(city = city, sf_lines = all_lines)
    saveRDS(result, cache_file)
    message("Downloaded ", nrow(all_lines), " cycling segments.")   

    # return the cycling_network instance
    result
  }