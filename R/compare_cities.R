# R/compare_cities.R
# Function 4: compare_cities()
# Compares the cycling infrastructure of two cities side by side.

#' Compare cycling infrastructure of two cities
#'
#' Creates a side by side safety map comparing the cycling infrastructure
#' of two cities.
#'
#' @param city1 A `cycling_classification` instance for the first city.
#' @param city2 A `cycling_classification` instance for the second city.
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
compare_cities <- function(city1, city2) {

  if (!inherits(city1, "cycling_classification")) {
    stop("`city1` must be a `cycling_classification` instance", call. = FALSE)
  }
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