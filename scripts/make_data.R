################################################################################
##
## [PROJ] NEH
## [FILE] make_data.R
## [AUTH] Benjamin Skinner (GitHub: @btskinner)
## [INIT] 15 September 2023
##
################################################################################

## libraries
libs <- c("tidyverse", "fredr", "crosswalkr")
sapply(libs, require, character.only = TRUE)

## directories (works with makefile at root or within ./scripts subdir)
args <- commandArgs(trailingOnly = TRUE)
root <- ifelse(length(args) == 0, file.path(".."), args)
dat_dir <- file.path(root, "data")

## -----------------------------------------------------------------------------
## read in data
## -----------------------------------------------------------------------------

## -------------------------------------
## NEH
## -------------------------------------

## get vector of NEH file names
files <- list.files(file.path(dat_dir, "raw"), full.names = TRUE)

## column names from NEH_GrantsDictionary.pdf
coln <- c("appno",
          "apptype",
          "inst",
          "orgtype",
          "instcity",
          "instst",
          "instzip",
          "instcountry",
          "congdist",
          "lat",
          "lon",
          "councildate",
          "year",
          "projtitle",
          "program",
          "division",
          "approut",
          "apprmat",
          "awardout",
          "awardmat",
          "origamount",
          "grantstart",
          "grantend",
          "projdesc",
          "tosupport",
          "primarydisc",
          "suppcount",
          "suppamount",
          "supplement",
          "partcount",
          "partic",
          "disccount",
          "disc")

## read in/combine
df_grt <- map(files |> str_subset("Grants"),
              ~ read_csv(.x,
                         col_names = coln,
                         show_col_types = FALSE)) |>
  bind_rows()

## -------------------------------------
## state population (FRED)
## -------------------------------------

## make data names (state abbrevation + POP)
dat_names <- paste0(stcrosswalk |> pull(stabbr), "POP")

## walk through and download
## create year and state abbreviation
## append at end
## compute state-specific percentage of population
df_pop <- map(dat_names,
              ~ fredr(series_id = .x,
                      observation_start = as.Date("1966-01-01"),
                      observation_end = as.Date("2022-01-01")) |>
                mutate(year = year(date),
                       stabbr = str_sub(series_id, 1, 2)) |>
                select(stabbr, year, pop = value)) |>
  bind_rows() |>
  group_by(year) |>
  mutate(pop_pct = pop / sum(pop)) |>
  ungroup()

## -------------------------------------
## inflation adjustment (FRED)
## -------------------------------------

## download inflation adjustment
## create year from date and rescale data to real 2022 dollars
cpi <- fredr(series_id = "USACPIALLAINMEI",
             observation_start = as.Date("1965-01-01"),
             observation_end = as.Date("2022-01-01")) |>
  mutate(year = year(date),
         adj = value / value[year == 2022]) |>
  select(year, adj)

## -----------------------------------------------------------------------------
## join / munge data
## -----------------------------------------------------------------------------

## subset grants to those within US
## join cpi and make adjustments from nominal to real dollars
## select columns
df <- df_grt |>
  filter(instst %in% c(stcrosswalk |> pull(stabbr))) |>
  left_join(cpi, by = "year") |>
  mutate(appro_adj = approut * adj,
         award_adj = awardout * adj) |>
  select(stabbr = instst, year, approut, appro_adj, awardout, award_adj)

## get means and sums of award data by year
df_sum <- df |>
  group_by(year) |>
  summarise(across(approut:award_adj,
                   ~ mean(.x),
                   .names = "{.col}_ym"),
            across(approut:award_adj,
                   ~ sum(.x),
                   .names = "{.col}_ys"),
            .groups = "drop")

## join summary measures back to main data, summarised to state/year
## add state names using crosswalkr::stcrosswalk data frame
## drop 2023 since we're still in this year
df <- df |>
  group_by(stabbr, year) |>
  summarise(across(approut:award_adj,
                   ~ mean(.x),
                   .names = "{.col}_sm"),
            across(approut:award_adj,
                   ~ sum(.x),
                   .names = "{.col}_ss"),
            awards = n(),
            .groups = "drop") |>
  left_join(df_sum, by = "year") |>
  left_join(df_pop, by = c("stabbr", "year")) |>
  left_join(stcrosswalk |> select(stabbr, stname),
            by = "stabbr") |>
  select(stabbr, stname, year, awards, starts_with("appr"),
         starts_with("award"), pop, pop_pct) |>
  filter(year < 2022)

## -----------------------------------------------------------------------------
## save data
## -----------------------------------------------------------------------------

write_csv(df, file.path(dat_dir, "clean", "analysis.csv"))

## -----------------------------------------------------------------------------
## end script
################################################################################
