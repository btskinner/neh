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

## state names; abbreviations
sts <- stcrosswalk |> filter(stabbr != "DC") |> select(stabbr, stname)

## -----------------------------------------------------------------------------
## read in data
## -----------------------------------------------------------------------------

df <- read_csv(file.path(dat_dir, "clean", "analysis.csv"),
               show_col_types = FALSE)

## -----------------------------------------------------------------------------
## compute awards per person and per capita amounts, by state/year
## -----------------------------------------------------------------------------

df <- df |>
  filter(stabbr != "DC") |>
  arrange(stabbr, year) |>
  group_by(stabbr) |>
  mutate(amount_3yr = rollmean(appro_adj_ss, k = 3, fill = NA),
         awards_3yr = rollmean(awards, k = 3, fill = NA)) |>
  ungroup() |>
  filter(!is.na(amount_3yr))

df_pc <- df |>
  mutate(pc_awards = pop / awards_3yr,        # persons for each award
         pc_amount = amount_3yr / pop,        # $ spent per person
         pc_amount = round(pc_amount, 2)) |>  # round to $0.00
  select(stabbr, stname, year, starts_with("pc"), pop)

## compute mean
df_pc_m <- df_pc |>
  group_by(year) |>
  summarise(pc_awards_y = mean(pc_awards),
            pc_amount_y = round(mean(pc_amount), 2))

## save key value for line plot
avg20 <- df_pc_m |> filter(year == 2020) |> pull(pc_amount_y)

## -----------------------------------------------------------------------------
## line plot
## -----------------------------------------------------------------------------

g <- map(sts |> pull(stname),
         ~ ggplot(df_pc_m, aes(x = year, y = pc_amount_y)) +
           geom_line(linewidth = 0.5) +
           geom_line(data = df_pc |> filter(stabbr != "DC" & stname != .x),
                     aes(y = pc_amount, colour = stabbr), alpha = 0.15) +
           geom_line(data = df_pc |> filter(stabbr != "DC" & stname == .x),
                     aes(y = pc_amount, colour = stabbr), alpha = 1,
                     linewidth = 0.5) +
           scale_x_continuous(breaks = 1967:2020,
                              expand = c(0, Inf),
                              labels = function(x) str_sub(x, 3, 4)) +
           scale_y_continuous(labels = scales::dollar_format()) +
           coord_cartesian(xlim = c(1967, 2020),
                           clip = "off") +
           geom_text(data = df_pc_m |> filter(year == 2020),
                     aes(x = Inf, y = pc_amount_y,
                         label = paste0("National\n $", round(pc_amount_y))),
                     hjust = -0.1, size = 2) +
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
           guides(colour = "none") +
           labs(x = "Year",
                y = "Award amount per 1,000 residents\n(2020$)") +
           theme_bw(base_size = 8) +
           theme(plot.margin = unit(c(1,3.5,1,1), "lines"),
                 panel.grid.minor.x = element_blank())) |>
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
