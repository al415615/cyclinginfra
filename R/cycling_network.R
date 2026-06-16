
# R/cycling_network.R
# S3 class: cycling_network
# Represents raw cycling infrastructure downloaded from OpenStreetMap.
 
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

