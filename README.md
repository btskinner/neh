# State by state differences in per capita NEH funding, 1967 - 2020

This repository contains the code to replicate the analyses found at [](https://www.btskinner.io/neh/).

## To run

Clone this directory and either:

1. Use the `makefile`

``` shell
> cd neh
> make
```
2. Run R scripts one by one (need to be in `./scripts` as working directory):

1. `make_data.R`
2. `analyze.R`

Cleaned data will be placed in `./data/clean`. Figures will be placed in
`./figures`.

## Required packages

The following R packages are required:

- [crosswalkr](https://www.btskinner.io/crosswalkr/)
- [fredr](https://cran.r-project.org/web/packages/fredr/vignettes/fredr.html)
- [tidyverse](https://www.tidyverse.org)
- [zoo](https://zoo.r-forge.r-project.org)

You install the packages with the following prompt in R:

``` r
install.packages(c("crosswalkr","fredr","tidyverse","zoo"))
```

**NOTE:** You will need an API key to use the `fredr` packages. See instructions in the [`fredr` documentation](https://cran.r-project.org/web/packages/fredr/vignettes/fredr.html).

## Required data

The NEH grant files for each decade from the 1960s to 2020s are required. The
`make_data.R` script will download each file if they are not present in the
`./data/raw` subdirectory. If you would rather download them manually, they can be found at [](https://apps.neh.gov/open/data/). You need the following:

- `NEH_Grants1960s.csv`
- `NEH_Grants1970s.csv`
- `NEH_Grants1980s.csv`
- `NEH_Grants1990s.csv`
- `NEH_Grants2000s.csv`
- `NEH_Grants2010s.csv`
- `NEH_Grants2020s.csv`

Place them in the `./data/raw` subdirectory.
