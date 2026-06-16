# R/plot_cycling_safety_map.R
# Function 3: plot_cycling_safety_map()
# Combines a spatial safety map with a summary bar chart using patchwork.

utils::globalVariables(c("infra_type", "total_length_km"))
 
#' Plot a cycling safety map with summary statistics
#'
#' Creates a combined figure with a `ggplot2` safety map (left panel) coloured
#' by infrastructure type and a horizontal bar chart of total length per type
#' (right panel). Compared to the plain `plot()` method for
#' `cycling_classification`, this function always includes the statistics panel
#' and optionally prints the raw summary table to the console.
#'
#' @param classification A `cycling_classification` instance returned by `classify_bike_infrastructure()`.
#' @param show_stats Logical. If `TRUE` (default), prints summary statistics.
#' @param basemap Logical. If `TRUE`, adds a light basemap tile beneath the
#'   network (requires `ggspatial` and internet access). Defaults to `FALSE`.
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
#' @export
plot_cycling_safety_map <- function(classification, show_stats = TRUE, basemap    = FALSE)  {
  
  # input validation (same as in the contructors)
  if (!inherits(classification, "cycling_classification")) {
    stop("`classification` must be a `cycling_classification` object. ",
        "Use classify_bike_infrastructure() first.",
         call. = FALSE)
  }
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
  combined <- map_plot + bar_plot + patchwork::plot_layout(widths = c(2, 1))
  print(combined)
  invisible(combined)
  }