
# R/cycling_network.R
# S3 class: cycling_network
# Represents raw cycling infrastructure downloaded from OpenStreetMap.

utils::globalVariables(c("infra_type", "total_length_km"))
utils::globalVariables(c("connectivity"))
 
#' Create a cycling_network instance
#'
#' Constructor for the `cycling_network` S3 class. This instance stores the
#' cycling infrastructure geometries for a given city together with metadata
#' such as the city name, download date and coordinate reference system.
#'
#' @param city A single non-empty character string naming the city (for instance, `"Muenster, Germany"`).
#' 
#' @param sf_lines An `sf` object containing LINESTRING geometries of the cycling network.
#'
#' @return An instance of class `cycling_network` (a list with components `city`, `lines`, and `download_date`).
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' }
#'
#' @export
new_cycling_network <- function(city, sf_lines) {

   # validate the length of the city argument (it is not empty)
    if (!is.character(city) || length(city) != 1 || nchar(city) == 0) {
      stop("`city` cannot be an empty character string, e.g. 'Muenster, Germany'", call. = FALSE)
    }
    
    # validate that sf_lines is an sf object (argument type)
    if (!inherits(sf_lines, "sf")) {
      stop("`sf_lines` must be an sf object", call. = FALSE)
    }
    
    # object structure as a list with class attribute
    structure(
      list(
        city         = city,
        lines        = sf_lines,   # LINESTRING geometries of the cycling network
        download_date = Sys.Date()  # date when the data was downloaded
      ),
      class = "cycling_network"
    )
}



# METHODS OF THE CLASS

#' Print a cycling_network instance.
#'
#' Displays a short summary of the cycling network instance to the console.
#'
#' @param x A `cycling_network` instance.
#' 
#' @param ... Further arguments (currently ignored).
#'
#' @return `x`, invisibly.
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' print(net)
#' }
#'
#' @export
print.cycling_network <- function(x, ...) {
  cat("cycling_network object\n")
  cat("  City         :", x$city, "\n")
  cat("  Download date:", format(x$download_date), "\n")
  cat("  Network lines:", nrow(x$lines), "segments\n")
  cat("  CRS          :", sf::st_crs(x$lines)$input, "\n")
  invisible(x)
}



#' Plot a cycling_network instance
#'
#' Produces a `ggplot2` map of the raw cycling network without classification.
#'
#' @param x A `cycling_network` instance.
#' @param ... Further arguments (currently ignored).
#'
#' @return A `ggplot` object, invisibly.
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' plot(net)
#' }
#'
#' @export
plot.cycling_network <- function(x, ...) {
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(
      data      = x$lines,
      ggplot2::aes(color = "cycling infrastructure"),
      linewidth = 0.4
    ) +
    ggplot2::scale_color_manual(
      values = c("cycling infrastructure" = "steelblue"),
      name   = NULL
    ) +
    ggplot2::labs(
      title    = paste("Cycling network:", x$city),
      subtitle = paste("Downloaded on", format(x$download_date)),
      caption  = "Source: OpenStreetMap contributors"
    ) +
    ggplot2::theme_minimal()
 
  print(p)
  invisible(p)
}



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
#' @param ... Further arguments passed to methods.
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
classify_bike_infrastructure <- function(network, ...) {
  UseMethod("classify_bike_infrastructure")
}
#' 
#' 
#' @rdname classify_bike_infrastructure
#' @export
classify_bike_infrastructure.default <- function(network, ...) {
  stop("` no applicable method for 'classify_bike_infrastructure' applied to an object of class '",
       paste(class(network), collapse = "/"), "'.", call. = FALSE)
}
#'
#'  
#' @export
classify_bike_infrastructure <- function(network,...) {
  
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


#' Analyse the connectivity of a cycling network
#'
#' Converts a `cycling_network` instance into an `sfnetworks` graph and
#' identifies connected components. Segments belonging to the same connected
#' component can be reached from one another without leaving the cycling
#' network. Isolated segments (small components) indicate poorly connected
#' areas.
#'
#' @param network A `cycling_network` instance returned by
#'   `get_cycling_network()`.
#' @param min_size Integer. Components with fewer segments than this value
#'   are labelled as "isolated". Defaults to `10`.
#'
#' @param ... Further arguments passed to methods.
#' 
#' @return A `ggplot` object showing the network coloured by connectivity,
#'   invisibly.
#'
#' @examples
#' \dontrun{
#' net <- get_cycling_network("Muenster, Germany")
#' analyze_connectivity(net)
#' }
#'
#' @export
analyze_connectivity <- function(network, min_size = 10, ...) {
  UseMethod("analyze_connectivity")
}
#' 
#' @rdname analyze_connectivity
#' @export
analyze_connectivity.default <- function(network, min_size = 10, ...) {
  stop(
    "` no applicable method for 'analyze_connectivity' applied to an object of class '",
    paste(class(network), collapse = "/"), "'.",
    call. = FALSE
  )
}
#' 
#' @export
analyze_connectivity <- function(network, min_size = 10) {

  # convert to sfnetwork
  net_sf <- sfnetworks::as_sfnetwork(network$lines, directed = FALSE)

  # compute connected components on nodes
  net_sf <- tidygraph::activate(net_sf, "nodes") |>
    tidygraph::mutate(component = tidygraph::group_components())

  # extract node components
  node_components <- sf::st_drop_geometry(
    sf::st_as_sf(tidygraph::activate(net_sf, "nodes"))
  )$component

  # activate edges and assign component from their start node
  net_sf <- tidygraph::activate(net_sf, "edges")
  edges <- sf::st_as_sf(net_sf)
  edges$component <- node_components[edges$from]

  # count size of each component
  comp_sizes <- table(edges$component)

  # label small components as isolated
  edges$connectivity <- ifelse(
    comp_sizes[as.character(edges$component)] >= min_size,
    "connected",
    "isolated"
  )

  # plot
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(
      data      = edges,
      ggplot2::aes(color = connectivity),
      linewidth = 0.5
    ) +
    ggplot2::scale_color_manual(
      values = c("connected" = "forestgreen", "isolated" = "tomato"),
      name   = "Connectivity"
    ) +
    ggplot2::labs(
      title    = paste("Cycling network connectivity:", network$city),
      subtitle = paste("Isolated = components with fewer than", min_size, "segments"),
      caption  = "Source: OpenStreetMap contributors"
    ) +
    ggplot2::theme_minimal()

  print(p)
  invisible(p)
}