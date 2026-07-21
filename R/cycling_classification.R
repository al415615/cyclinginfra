# R/cycling_classification.R
# S3 class: cycling_classification
# Extends cycling_network by adding a safety classification per segment.

utils::globalVariables(c("infra_type", "total_length_km"))
 
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
 
#' Plot a cycling safety map with summary statistics
#'
#' Creates a combined figure with a `ggplot2` safety map (left panel) coloured
#' by infrastructure type and a horizontal bar chart of total length per type
#' (right panel). Compared to the plain `plot()` method for
#' `cycling_classification`, this function always includes the statistics panel
#' and optionally prints the raw summary table to the console.
#'
#' @param classification A `cycling_classification` instance returned by `classify_bike_infrastructure()`.
#' 
#' @param show_stats Logical. If `TRUE` (default), prints summary statistics.
#' 
#' @param basemap Logical. If `TRUE`, adds a light basemap tile beneath the
#'   network (requires `ggspatial` and internet access). Defaults to `FALSE`.
#' 
#' @param ... Further arguments passed to methods.
#'
#' @return A combined `patchwork` / `ggplot` object, invisibly.
#'
#' @examples
#' \dontrun{
#' cl <- classify_bike_infrastructure(get_cycling_network("Muenster, Germany"))
#' plot_cycling_safety_map(cl)
#' plot_cycling_safety_map(cl, show_stats = FALSE, basemap = TRUE)
#' }
#'
#' 
#' @export
plot_cycling_safety_map <- function(classification, show_stats = TRUE, basemap = FALSE, ...) {
  UseMethod("plot_cycling_safety_map")
}
#' 
#' @rdname plot_cycling_safety_map
#' @export
plot_cycling_safety_map.default <- function(classification, show_stats = TRUE, basemap = FALSE, ...) {
  stop(
    "` no applicable method for 'plot_cycling_safety_map' applied to an object of class '",
    paste(class(classification), collapse = "/"), "'.",
    call. = FALSE
  )
}
#' 
#' @export
plot_cycling_safety_map <- function(classification, show_stats = TRUE, basemap    = FALSE)  {
  
  # input validation (same as in the contructors)
  if (!is.logical(show_stats) || length(show_stats) != 1) {
    stop("`show_stats` must be TRUE or FALSE",
         call. = FALSE)
  }
  
  # optionally print summary statistics to console
  if (show_stats) {
    cat("\nInfrastructure summary for", classification$city, ":\n")
    print(knitr::kable(classification$summary, row.names = FALSE))
    cat("\n")
  }
  
  # a color for each infrastructure type
  safety_colours <- c(
    "dedicated track" = "forestgreen",
    "footway track"   = "steelblue",
    "painted lane"    = "goldenrod",
    "shared lane"     = "orange",
    "shared road"     = "tomato",
    "unknown"         = "grey70"
  )
  
  # left panel: spatial map (reuse plot() method)
  map_plot <- plot.cycling_classification(classification)
  
  # right panel: bar chart
  if (!show_stats) return(map_plot)
    
    # bar chart of total km per infrastructure type
  bar_plot <- ggplot2::ggplot(
    classification$summary,
    ggplot2::aes(
      x    = reorder(infra_type, total_length_km),
      y    = total_length_km,
      fill = infra_type
    )
  ) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = safety_colours) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Length by type (km)",
      x     = NULL,
      y     = "Total length (km)"
    ) +
    ggplot2::theme_minimal(base_size = 11)
 
  # combine side by side
  combined <- patchwork::wrap_plots(map_plot, bar_plot, widths = c(2, 1))
  print(combined)
  invisible(combined)
  }


#' Compare cycling infrastructure of two cities
#'
#' Creates a side by side safety map comparing the cycling infrastructure
#' of two cities.
#'
#' @param city1 A `cycling_classification` instance for the first city.
#' 
#' @param city2 A `cycling_classification` instance for the second city.
#' 
#' @param ... Further arguments passed to methods.
#'
#' @return A combined `patchwork` plot, invisibly.
#'
#' @examples
#' \dontrun{
#' munster_cl   <- classify_bike_infrastructure(get_cycling_network("Muenster, Germany"))
#' amsterdam_cl <- classify_bike_infrastructure(get_cycling_network("Amsterdam, Netherlands"))
#' compare_cities(munster_cl, amsterdam_cl)
#' }
#'
#' @export
compare_cities <- function(city1, city2, ...) {
  UseMethod("compare_cities")
}
#' 
#' 
#' @rdname compare_cities
#' @export
compare_cities.default <- function(city1, city2, ...) {
  stop(
    "` no applicable method for 'compare_cities' applied to an object of class '",
    paste(class(city1), collapse = "/"), "'.",
    call. = FALSE
  )
}
#' 
#' 
#' @export
compare_cities <- function(city1, city2, ...) {

  if (!inherits(city2, "cycling_classification")) {
    stop("`city2` must be a `cycling_classification` instance", call. = FALSE)
  }

  safety_colours <- c(
    "dedicated track" = "forestgreen",
    "footway track"   = "steelblue",
    "painted lane"    = "goldenrod",
    "shared lane"     = "orange",
    "shared road"     = "tomato",
    "unknown"         = "grey70"
  )

  make_map <- function(x) {
    ggplot2::ggplot() +
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
        title   = x$city,
        caption = "Source: OpenStreetMap contributors"
      ) +
      ggplot2::theme_minimal()
  }

  p1 <- make_map(city1)
  p2 <- make_map(city2)

  combined <- p1 + p2 +
    patchwork::plot_layout(ncol = 2, guides = "collect") +
    patchwork::plot_annotation(
      title    = "Cycling infrastructure comparison",
      subtitle = "Classified by safety level"
    )

  print(combined)
  invisible(combined)
}