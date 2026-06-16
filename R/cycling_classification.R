# R/cycling_classification.R
# S3 class: cycling_classification
# Extends cycling_network by adding a safety classification per segment.
 
#' Create a cycling_classification object
#'
#' Constructor for the `cycling_classification` S3 class, which extends
#' `cycling_network` with an infrastructure type classification and aggregate length statistics per type.
#'
#' @param network A `cycling_network` object (output of `get_cycling_network()`).
#' 
#' @param classified_lines An `sf` object with at least an `infra_type` column holding the safety classification for each segment.
#' 
#' @param summary_stats A `data.frame` with columns `infra_type` and `total_length_km`.
#'
#' @return An object of classes `c("cycling_classification", "cycling_network")`.
#'
#' @examples
#' \dontrun{
#' net  <- get_cycling_network("Muenster, Germany")
#' cl   <- classify_bike_infrastructure(net)
#' }
#'
#' @export
new_cycling_classification <- function(network, classified_lines, summary_stats) {
  
  # validate that network is a cycling_network object
  if (!inherits(network, "cycling_network")) {
    stop("`network` must be a `cycling_network` object", call. = FALSE)
  }
  
  # validate that classified_lines is an sf object with the required column (argument type)
  if (!inherits(classified_lines, "sf")) {
    stop("`classified_lines` must be an sf object", call. = FALSE)
  }
  if (!"infra_type" %in% names(classified_lines)) {
    stop("`classified_lines` must contain a column named `infra_type`", call. = FALSE)
  }
  
  # object structure extending the original network
  structure(
    list(
      city           = network$city,
      lines          = network$lines,
      download_date  = network$download_date,
      classified     = classified_lines,  # sf with infra_type column added
      summary        = summary_stats      # data.frame with length per category
    ),
    class = c("cycling_classification", "cycling_network")
  )
}



# METHODS OF THE CLASS

 
#' Print a cycling_classification instance
#'
#' Displays the city, download date, number of classified segments and the infrastructure type summary table.
#'
#' @param x A `cycling_classification` instance
#' @param ... Further arguments (currently ignored).
#'
#' @return `x`, invisibly.
#'
#' @examples
#' \dontrun{
#' cl <- classify_bike_infrastructure(get_cycling_network("Muenster, Germany"))
#' print(cl)
#' }
#'
#' @export
  print.cycling_classification <- function(x, ...) {
    cat("cycling_classification object\n")
    cat("  City         :", x$city, "\n")
    cat("  Download date:", format(x$download_date), "\n")
    cat("  Segments     :", nrow(x$classified), "\n")
    cat("\nInfrastructure summary (km per type):\n")
    print(knitr::kable(x$summary, row.names = FALSE))
    invisible(x)
  }



#' Plot a cycling_classification object
#'
#' Produces a `ggplot2` safety map of the cycling network coloured by
#' infrastructure type, with an optional base map tile.
#'
#' @param x A `cycling_classification` instance.
#' @param basemap Logical. Whether to add a basemap underneath the
#'   network (requires `ggspatial` and Internet access). Default is `FALSE`
#'   so that the plot always works without a network connection.
#' @param ... Further arguments (currently ignored).
#'
#' @return A `ggplot` object, invisibly.
#'
#' @examples
#' \dontrun{
#' cl <- classify_bike_infrastructure(get_cycling_network("Muenster, Germany"))
#' plot(cl)
#' plot(cl, basemap = TRUE)
#' }
#'
#' @export
plot.cycling_classification <- function(x, basemap = FALSE, ...) {
 
  safety_colours <- c(
    "dedicated track" = "forestgreen",
    "footway track"   = "steelblue",
    "painted lane"    = "goldenrod",
    "shared lane"     = "orange",
    "shared road"     = "tomato",
    "unknown"         = "grey70"
  )
 
  p <- ggplot2::ggplot()
 
  if (basemap) {
    p <- p + ggspatial::annotation_map_tile(type = "cartolight", zoom = 13, quiet = TRUE)
  }
 
  p <- p +
    ggplot2::geom_sf(
      data      = x$classified,
      ggplot2::aes(color = infra_type),
      linewidth = 0.5
    ) +
    ggplot2::scale_color_manual(
      values = safety_colours,
      name   = "Infrastructure type"
    ) +
    ggplot2::labs(
      title    = paste("Cycling infrastructure:", x$city),
      subtitle = "Classified by safety level",
      caption  = "Source: OpenStreetMap contributors"
    ) +
    ggplot2::theme_minimal()
 
  print(p)
  invisible(p)
}
 
