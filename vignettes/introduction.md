# Examples

## Case Study of Münster

In order to prove that the package actually works and as a way to prove
its relevance, here is a little piece of code that executes everything
learnt:

    library(cyclinginfra)

    # load the pre-downloaded cycling network of Muenster
    data(munster)
    print(munster)

    ## cycling_network object
    ##   City         : Muenster, Germany 
    ##   Download date: 2026-05-25 
    ##   Network lines: 4715 segments
    ##   CRS          : EPSG:4326

    plot(munster)

<img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-1.png" alt="" width="100%" />

    # classify the infrastructure
    munster_classified <- classify_bike_infrastructure(munster)
    print(munster_classified)

    ## cycling_classification object
    ##   City         : Muenster, Germany 
    ##   Download date: 2026-05-25 
    ##   Segments     : 4715 
    ## 
    ## Infrastructure summary (km per type):
    ## 
    ## 
    ## |infra_type      | total_length_km|
    ## |:---------------|---------------:|
    ## |footway track   |          357.57|
    ## |shared road     |          135.98|
    ## |dedicated track |           30.34|
    ## |painted lane    |            1.82|

    # create the safety map
    plot_cycling_safety_map(munster_classified)

    ## 
    ## Infrastructure summary for Muenster, Germany :
    ## 
    ## 
    ## |infra_type      | total_length_km|
    ## |:---------------|---------------:|
    ## |footway track   |          357.57|
    ## |shared road     |          135.98|
    ## |dedicated track |           30.34|
    ## |painted lane    |            1.82|

<img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-2.png" alt="" width="100%" /><img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-3.png" alt="" width="100%" />

## Comparison in between 2 cities

    # compare Münster and Amsterdam
    munster_classified <- classify_bike_infrastructure(munster)

    data(amsterdam)
    amsterdam_classified <- classify_bike_infrastructure(amsterdam)

    plot_cycling_safety_map(munster_classified)

    ## 
    ## Infrastructure summary for Muenster, Germany :
    ## 
    ## 
    ## |infra_type      | total_length_km|
    ## |:---------------|---------------:|
    ## |footway track   |          357.57|
    ## |shared road     |          135.98|
    ## |dedicated track |           30.34|
    ## |painted lane    |            1.82|

<img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-amsterdam-1.png" alt="" width="100%" /><img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-amsterdam-2.png" alt="" width="100%" />

    plot_cycling_safety_map(amsterdam_classified)

    ## 
    ## Infrastructure summary for Amsterdam, Netherlands :
    ## 
    ## 
    ## |infra_type      | total_length_km|
    ## |:---------------|---------------:|
    ## |dedicated track |          555.03|
    ## |shared road     |           97.47|
    ## |painted lane    |           20.54|
    ## |footway track   |            9.03|
    ## |shared lane     |            1.83|

<img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-amsterdam-3.png" alt="" width="100%" /><img src="/Users/belencretu/Desktop/university/course_R/assigment2/cyclinginfra/vignettes/introduction_files/figure-markdown_strict/safety-map-amsterdam-4.png" alt="" width="100%" />
