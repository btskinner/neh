################################################################################
##
## [PROJ] NEH
## [FILE] analyze.R
## [AUTH] Benjamin Skinner (GitHub: @btskinner)
## [INIT] 15 September 2023
##
################################################################################

## libraries
libs <- c("tidyverse", "zoo")
sapply(libs, require, character.only = TRUE)

## directories (works with makefile at root or within ./scripts subdir)
args <- commandArgs(trailingOnly = TRUE)
root <- ifelse(length(args) == 0, file.path(".."), args)
dat_dir <- file.path(root, "data")
fig_dir <- file.path(root, "figures")

## macros for figure consistency
plot_169_w <- 7.5
plot_169_h <- plot_169_w * 9/16

## macro tibble: state names; abbreviations
sts <- stcrosswalk |> filter(stabbr != "DC") |> select(stabbr, stname)

## -----------------------------------------------------------------------------
## read in data
## -----------------------------------------------------------------------------

df <- read_csv(file.path(dat_dir, "clean", "analysis.csv"),
               show_col_types = FALSE)

## -----------------------------------------------------------------------------
## compute awards per person and per capita amounts, by state/year
## -----------------------------------------------------------------------------

## computing 3 year rolling averages to account for regular spiky cycles since
## 2000s; dropping DC b/c extreme outlier
df <- df |>
  filter(stabbr != "DC") |>
  arrange(stabbr, year) |>
  group_by(stabbr) |>
  mutate(amount_3yr = rollmean(appro_adj_ss, k = 3, fill = NA),
         awards_3yr = rollmean(awards, k = 3, fill = NA)) |>
  ungroup() |>
  filter(!is.na(amount_3yr))

## compute:
## (1) awards per state population
## (2) amount per 1000 persons (for scaling)
## (3) round amount to dollar/cents
df_pc <- df |>
  mutate(pc_awards = pop / awards_3yr,        # persons for each award
         pc_amount = amount_3yr / pop,        # $ spent per 1000 persons
         pc_amount = round(pc_amount, 2)) |>  # round to $0.00
  select(stabbr, stname, year, starts_with("pc"), pop)

## compute national mean from states for comparison in figure
df_pc_m <- df_pc |>
  group_by(year) |>
  summarise(pc_awards_y = mean(pc_awards),
            pc_amount_y = round(mean(pc_amount), 2))

## save key value for line plot (this just saves
avg20 <- df_pc_m |> filter(year == 2020) |> pull(pc_amount_y)

## -----------------------------------------------------------------------------
## line plot
## -----------------------------------------------------------------------------

## create a figure for each state that shows the national per capita amount
## spent over time (black line) with all state line averages plotted in lower
## opacity so that state of interest stands out (color line); include actual
## value and state name at point of 2020 value on righthand side of figure
## NOTES:
## (1) All states but one, transparent; then main state, full opacity
## (2) Lines for each year, but labels only every 5 for clarity
## (3) Allow for text outside plot using clip = "off"
## (4) Format to include dollar sign and comma
## (5) Text for national line
## (6) Text for state with adjustments for states that overlap national; use
##     computed value above to save on busy-ness in code
## (7) Turn off legend since too busy and don't need it for what I'm doing
## (8) Give extra space on RHS for text and adjust x-axis labels for better
##     aesthetics

g <- map(sts |> pull(stname),
         ~ ggplot(df_pc_m, aes(x = year, y = pc_amount_y)) +
           geom_line(linewidth = 0.5) +
           ## (1)
           geom_line(data = df_pc |> filter(stname != .x),
                     aes(y = pc_amount, colour = stabbr), alpha = 0.15) +
           geom_line(data = df_pc |> filter(stname == .x),
                     aes(y = pc_amount, colour = stabbr), alpha = 1,
                     linewidth = 0.5) +
           ## (2)
           scale_x_continuous(breaks = seq(1970, 2020, 5),
                              minor_breaks = 1967:2020,
                              expand = c(0, Inf)) +
           ## (3)
           coord_cartesian(xlim = c(1967, 2020),
                           clip = "off") +
           ## (4)
           scale_y_continuous(labels = scales::dollar_format()) +
           ## (5)
           geom_text(data = df_pc_m |> filter(year == 2020),
                     aes(x = Inf, y = pc_amount_y,
                         label = paste0("National\n $", round(pc_amount_y))),
                     hjust = -0.1, size = 2) +
           ## (6)
           geom_text(data = df_pc |> filter(stname == .x & year == 2020),
                     aes(x = Inf,
                         y = case_when(
                           pc_amount - avg20 > 0 &
                             abs(pc_amount - avg20) < 200 ~ pc_amount + 150,
                           pc_amount - avg20 < 0 &
                             abs(pc_amount - avg20) < 200 ~ pc_amount - 150,
                           TRUE ~ pc_amount),
                         label = paste0(stname, "\n $",
                                        formatC(round(pc_amount),
                                                format = "d",
                                                big.mark = ","))),
                     hjust = -0.1, size = 2) +
           ## (7)
           guides(colour = "none") +
           labs(x = "Award year",
                y = "Award amount per 1,000 residents (2020$)",
                title = paste0(.x),
                caption = paste("Data:",
                                "National Endowment for the Humanities,",
                                "FRED")) +
           theme_bw(base_size = 8) +
           ## (8)
           theme(plot.margin = unit(c(1,3.5,1,1), "lines"),
                 axis.text.x = element_text(hjust = 0.875))) |>
  set_names(sts |> pull(stabbr))

## save figures
walk2(g,
      names(g),
      ~ ggsave(file.path(fig_dir, paste0(.y, ".pdf")),
               .x,
               width = plot_169_w,
               height = plot_169_h,
               units = "in",
               dpi = "retina"))

## -----------------------------------------------------------------------------
## end script
################################################################################
