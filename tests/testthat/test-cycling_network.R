test_that("new_cycling_network validates inputs", {
  expect_error(new_cycling_network("", sf_lines = NULL))
  expect_error(new_cycling_network(123, sf_lines = NULL))
})

test_that("new_cycling_network returns correct class", {
  lines <- sf::st_sf(
    osm_tag  = "highway=cycleway",
    geometry = sf::st_sfc(sf::st_linestring(rbind(c(7.62, 51.96), c(7.63, 51.96))), crs = 4326)
  )
  net <- new_cycling_network("Test City", lines)
  expect_s3_class(net, "cycling_network")
})