# R/analyze_connectivity.R
# Function 5: analyze_connectivity()
# Analyses the connectivity of a cycling network using sfnetworks.
utils::globalVariables(c("connectivity"))

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
analyze_connectivity <- function(network, min_size = 10) {

  if (!inherits(network, "cycling_network")) {
    stop("`network` must be a `cycling_network` instance", call. = FALSE)
  }

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