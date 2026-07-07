# https://github.com/open-AIMS/synthos/tree


# Cyclone dominated Scenario
# Photo transect method

# dhw_weight = 0.1,
# cyc_weight = 0.8,
# other_weight = 0.1,

# hcc_growth = 0.3
# sc_growth =  0.3

#---------------------------------------
#Step-1 Create synthetic reef landscape
#----------------------------------------

library(gstat)
library(stringr)  
library(readr)

library(synthos)
library(ggplot2)
library(dplyr)
library(sf)
library(INLA)
library(patchwork)
library(inlabru)
library(purrr)
library(tidyr)
library(stars)
library(RColorBrewer)
library(lubridate)

config_sp <- list(
 seed = 1,
 crs = 4326,
 model = "Exp",
 psill = 1,
 range = 15,
 nugget = 0,
 alpha = 2,
 kappa = 1,
 variance = 1,
 patch_threshold = 1.75,
 reef_width = 0.01,
 years = 1:30,
 dhw_weight = 0.1,
 cyc_weight = 0.8,
 other_weight = 0.1,
 hcc_cover_range = c(0.1, 0.7),
 hcc_growth = 0.3,
 sc_cover_range = c(0.01, 0.1),
 sc_growth =  0.3
)
spatial_domain <- st_geometry(
 st_multipoint(
  x = rbind(
   c(0, -11),
   c(3,-11),
   c(6,-14),
   c(1,-15),
   c(2,-12),
   c(0,-11)
  )
 )
) |>
 st_set_crs(config_sp$crs) |>
 st_cast("POLYGON")

set.seed(config_sp$seed)
spatial_grid <- spatial_domain |>
 st_set_crs(NA) |>
 st_sample(size = 10000, type = "regular") |>
 st_set_crs(config_sp$crs)

spatial.grid.pts.df <- spatial_grid %>%
 st_coordinates() %>%
 as.data.frame() %>%
 dplyr::rename(Longitude = X, Latitude = Y) %>%
 arrange(Longitude, Latitude)

# This is used to calculate reef disturbances (Useful for Step-6)
simulated_field_sf <- generate_field(spatial_grid, config_sp)
simulated_patches_sf <- generate_patches(simulated_field_sf, config_sp)
reefs.sf <- generate_reefs(simulated_patches_sf, config_sp)


benthos_reefs_pts <- create_synthetic_reef_landscape(spatial_grid, config_sp)


#------------------------------------------
#Step-2 Generate large scale fixed design
#------------------------------------------
config2 <- list(n_locs = 49, n_sites = 3, seed = 123)
benthos_fixed_locs_sf <- sampling_design_large_scale_fixed(benthos_reefs_pts, config2)


#-----------------------------------------
#Step-3 Generate fine scale fixed design  
#-----------------------------------------
config3 <- list(
 years =  1:30,
 Number_of_transects_per_site = 5,
 Depths = 2,
 Number_of_frames_per_transect = 100,
 Points_per_frame = 5,
 ## Note, the following are on the link scale
 hcc_site_sigma = 0.5, # variability in Sites within Locations
 hcc_transect_sigma = 0.2, # variability in Transects within Sites
 hcc_sigma = 0.1, # random noise
 
 sc_site_sigma = 0.05, # variability in Sites within Locations
 sc_transect_sigma = 0.02, # variability in Transects within Sites
 sc_sigma = 0.01, # random noise
 
 ma_site_sigma = 0.5, # variability in Sites within Locations
 ma_transect_sigma = 0.2, # variability in Transects within Sites
 ma_sigma = 0.1, # random noise
 seed = 1
)

benthos_fixed_locs_obs <- sampling_design_fine_scale_fixed(benthos_fixed_locs_sf, config3)


#-------------------------------------------------------------------------------
#Step-4a Generate photo-transect like data and prepare for reefCloud
#-------------------------------------------------------------------------------
config4 <- list(
 Depths = 2,
 Depth_effect_multiplier = 2,
 Number_of_transects_per_site = 5,
 Number_of_frames_per_transect = 100,
 Points_per_frame = 5,
 seed = 1
)
benthos_fixed_locs_points <- sampling_design_fine_scale_points(benthos_fixed_locs_obs, config4)

# Process data to get hard coral cover at transect scale and 10m depth  
reefcloud_synthetic_fixed_benthos <- prepare_for_reefcloud(benthos_fixed_locs_points) 

HCC_sum <- reefcloud_synthetic_fixed_benthos %>%
 mutate(year = year(survey_start_date)) %>%
 group_by(image_name, survey_depth, year, point_machine_classification) %>%
 summarise(COUNT = n()) %>%
 ungroup(point_machine_classification) %>%
 mutate(TOTAL = sum(COUNT)) %>%
 left_join(reefcloud_synthetic_fixed_benthos  %>% 
            dplyr::select(image_name, survey_depth, site_name, survey_transect_number, site_latitude, site_longitude)) %>%
 ungroup() %>%
 group_by(survey_depth, point_machine_classification, site_name, survey_transect_number, year, site_latitude, site_longitude) %>%
 summarise(COUNT_transect = sum(COUNT)) %>%
 ungroup(point_machine_classification) %>%
 mutate(TOTAL_transect = sum(COUNT_transect)) %>%
 ungroup() %>%
 mutate(SITE_NO = str_c(word(site_name, 2), word(site_name, 3), sep = " "),
        REEF_NAME = str_replace(word(site_name, 1), "(Reef)(\\d+)", "\\1 \\2"),
 ) %>%
 filter(point_machine_classification == "HCC")%>%
 mutate(HCC = (COUNT_transect / TOTAL_transect) * 100) # new column for HCC


reef_name <- unique(HCC_sum$REEF_NAME)
depth_vals <- sort(unique(HCC_sum$survey_depth))

p_trend_depth_1 <- ggplot(HCC_sum %>% filter(survey_depth == depth_vals[1], REEF_NAME %in% reef_name), aes(
 x = year,
 y = HCC,
 group = interaction(as.factor(survey_transect_number), as.factor(SITE_NO), REEF_NAME),
 col = as.factor(SITE_NO)
)) +
 geom_line(linewidth = 0.8, alpha = 0.7) +
 # facet_wrap(~REEF_NAME, ncol = 7) +
 facet_wrap(~factor(REEF_NAME, levels = paste0("Reef ", 1:49)),ncol = 7)+
 scale_y_continuous(name = "Coral cover (%)") +
 # scale_x_continuous(name = "Year") +
 scale_x_continuous(name = "Year",
                    breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 2),
                    minor_breaks = NULL,
                    expand = expansion(mult = c(0.01, 0.02))) +
 theme_bw(base_size = 16) +
 theme(
  axis.text.x = element_text(size = 14, angle = 90, hjust = 1),
  axis.text.y = element_text(size = 14),
  axis.title = element_text(size = 14),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  strip.background = element_rect(fill = "white"),
  strip.text = element_text(size = 14, margin = margin(t = 2, b = 2)),
  legend.position = "top"
 )+
 labs(color = "", title = paste("Only Cyclone - Depth =", as.character(depth_vals[1])))

p_trend_depth_2 <- ggplot(HCC_sum %>% filter(survey_depth == depth_vals[2], REEF_NAME %in% reef_name), aes(
 x = year,
 y = HCC,
 group = interaction(as.factor(survey_transect_number), as.factor(SITE_NO), REEF_NAME),
 col = as.factor(SITE_NO)
)) +
 geom_line(linewidth = 0.8, alpha = 0.7) +
 facet_wrap(~factor(REEF_NAME, levels = paste0("Reef ", 1:49)),ncol = 7)+
 scale_y_continuous(name = "Coral cover (%)") +
 # scale_x_continuous(name = "Year") +
 scale_x_continuous(name = "Year",
                    breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 2),
                    minor_breaks = NULL,
                    expand = expansion(mult = c(0.01, 0.02))) +
 theme_bw(base_size = 16) +
 theme(
  axis.text.x = element_text(size = 14, angle = 90, hjust = 1),
  axis.text.y = element_text(size = 14),
  axis.title = element_text(size = 14),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  strip.background = element_rect(fill = "white"),
  strip.text = element_text(size = 14, margin = margin(t = 2, b = 2)),
  legend.position = "top"
 )+
 labs(color = "", title = paste0("Only Cyclone - Depth =", as.character(depth_vals[2])))

plot(p_trend_depth_1)
plot(p_trend_depth_2)


#-----------------------------------------
#Step-5 Calculating Mean Hard Coral Cover
#-----------------------------------------
#Compute average HCC across transects -> HCC_sum
mean_HCC <- HCC_sum %>%
 group_by(across(-c(HCC, survey_transect_number, COUNT_transect, TOTAL_transect))) %>% 
 summarise(mean_hcc = mean(HCC, na.rm = TRUE))


#--------------------------------------------------------
#Step-6 Time Series for Mean Hard Coral Cover - Depth Wise
#--------------------------------------------------------
plot_data_hcc <- mean_HCC %>%
 transmute(
  reef_name = str_replace(word(site_name, 1), "(Reef)(\\d+)", "\\1 \\2"),
  site = str_trim(str_extract(site_name, "Site\\s*\\d+")), # pull "Site 1/2/3" out of "Reef118 Site 3"
  year = as.integer(year),
  depth = as.factor(survey_depth),
  mean_hcc
 ) %>%
 arrange(reef_name, site, year)


# Plot - Time series of mean hard coral cover - Depth =3
plot_ts_mean_hcc_depth_1 <- ggplot(filter(plot_data_hcc, depth == depth_vals[1]), aes(x = year, y = mean_hcc, color = site)) +
 geom_line(aes(group = site), linewidth = 0.9, alpha = 0.7) +   # 1 line per site
 # facet_wrap(~ reef_name) +
 facet_wrap(~factor(reef_name, levels = paste0("Reef ", 1:49)),ncol = 7)+
 scale_x_continuous(
  breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 2),
  minor_breaks = NULL,
  expand = expansion(mult = c(0.01, 0.02))) +
 labs(
  title = paste("Only Cyclone - Depth =", as.character(depth_vals[1])),
  x = "Year", y = "Mean hard coral cover (%)", color = "") +
 theme_bw(base_size = 16) +
 # theme(plot.title = element_text(hjust = 0.5))+ 
 theme(
  axis.text.x = element_text(size = 14, angle = 90, hjust = 1),
  axis.text.y = element_text(size = 14),
  legend.position = "top")

# Plot - Time series of mean hard coral cover - Depth =10
plot_ts_mean_hcc_depth_2 <- ggplot(filter(plot_data_hcc, depth == depth_vals[2]), aes(x = year, y = mean_hcc, color = site)) +
 geom_line(aes(group = site), linewidth = 0.9, alpha = 0.7) +   # 1 line per site
 # facet_wrap(~ reef_name) +
 facet_wrap(~factor(reef_name, levels = paste0("Reef ", 1:49)),ncol = 7)+
 scale_x_continuous(
  breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 2),
  minor_breaks = NULL,
  expand = expansion(mult = c(0.01, 0.02))) +
 labs(
  title = paste("Only Cyclone - Depth =", as.character(depth_vals[2])),
  x = "Year", y = "Mean hard coral cover (%)", color = "") +
 theme_bw(base_size = 16) +
 # theme(plot.title = element_text(hjust = 0.5))+ 
 theme(
  axis.text.x = element_text(size = 14, angle = 90, hjust = 1),
  axis.text.y = element_text(size = 14),
  legend.position = "top")

plot(plot_ts_mean_hcc_depth_1)
plot(plot_ts_mean_hcc_depth_2)


#----------------------------------------------
#Step-7 Attach disturbances to dataset / Generate DHW, CYC, OTHER Disturbances and 
#Used https://github.com/open-AIMS/synthos/blob/main/R/broad_scale_reef_patterns.R#L565 
#----------------------------------------------
spde <- create_spde(spatial_grid, config_sp)

dhw <- disturbance_dhw(spatial_grid, spde, config_sp)
cyc <- disturbance_cyc(spatial_grid, spde, config_sp)
other <- disturbance_other(spatial_grid, spde, config_sp)

reefs <- pointify_polygons(reefs.sf$simulated_reefs_sf)

reefs_cyc <- calculate_reef_disturbances(
 spatial_grid,
 spde,
 cyc$cyc_effects,
 reefs$data_reefs_df,
 reefs$data_reefs_sf,
 reefs.sf$simulated_reefs_poly_sf, config_sp
)

reefs_dhw <- calculate_reef_disturbances(
 spatial_grid,
 spde,
 dhw$dhw_effects,
 reefs$data_reefs_df,
 reefs$data_reefs_sf,
 reefs.sf$simulated_reefs_poly_sf, config_sp
)

reefs_other <- calculate_reef_disturbances(
 spatial_grid,
 spde,
 other$other_effects,
 reefs$data_reefs_df,
 reefs$data_reefs_sf,
 reefs.sf$simulated_reefs_poly_sf, config_sp
)

data_reefs_disturb_cyc <- reefs_cyc$data_reefs_disturb
data_reefs_disturb_dhw <- reefs_dhw$data_reefs_disturb
data_reefs_disturb_other <- reefs_other$data_reefs_disturb


#----------------------------------------------------------------------------------
#Step-8 merge cyc,dhw,other disturbances to mean_hcc dataset
#----------------------------------------------------------------------------------

# Merge three disturbance datasets by Longitude, Latitude, and Year
data_reefs_disturb_all <- data_reefs_disturb_cyc |>
 rename(cyc_dis = Value) |>
 inner_join(data_reefs_disturb_dhw |> rename(dhw_dis = Value),
            by = c("Longitude","Latitude","Year")) |>
 inner_join(data_reefs_disturb_other |> rename(other_dis = Value),
            by = c("Longitude","Latitude","Year"))

# add disturbances to "reefcloud_synthetic_fixed_benthos_HCC" data set
mean_HCC_with_disturbs <- mean_HCC %>%
 left_join(
  data_reefs_disturb_all,
  by = c("site_longitude" = "Longitude",
         "site_latitude"  = "Latitude",
         "year"           = "Year")
 )

# write_csv(mean_HCC_with_disturbs, "only_cyc.csv")



#-----------------------------------------
# Additional plots - time series of disturbances
#-----------------------------------------
# plot_data_dist <- mean_HCC_with_disturbs %>%
#  transmute(
#   reef_name = str_replace(word(site_name, 1), "(Reef)(\\d+)", "\\1 \\2"),
#   site = str_trim(str_extract(site_name, "Site\\s*\\d+")),
#   year = as.integer(year),
#   cyc_dis, dhw_dis, other_dis
#  ) %>%
#  arrange(reef_name, site, year)
# 
# #cyc
# plot_ts_cyc <- ggplot(plot_data_dist, aes(x = year, y = cyc_dis, color = site)) +
#  geom_line(aes(group = site), linewidth = 0.9, alpha = 0.7) +
#  # facet_wrap(~ reef_name) +
#  facet_wrap(~factor(reef_name, levels = paste0("Reef ", 1:49)),ncol = 7)+
#  scale_x_continuous(breaks = scales::pretty_breaks()) +
#  labs(x = "Year", y = "Relative intensity of cyclone", color = "") +
#  theme_bw(base_size = 18) +
#  theme(legend.position = "top")
# 
# #dhw
# plot_ts_dhw <- ggplot(plot_data_dist, aes(x = year, y = dhw_dis, color = site)) +
#  geom_line(aes(group = site), linewidth = 0.9, alpha = 0.7) +
#  facet_wrap(~factor(reef_name, levels = paste0("Reef ", 1:49)),ncol = 7)+
#  scale_x_continuous(breaks = scales::pretty_breaks()) +
#  labs(x = "Year", y = "Relative intensity of bleaching", color = "") +
#  theme_bw(base_size = 18)+
#  theme(legend.position = "top")
# 
# #other
# plot_ts_other <- ggplot(plot_data_dist, aes(x = year, y = other_dis, color = site)) +
#  geom_line(aes(group = site), linewidth = 0.9, alpha = 0.7) +
#  facet_wrap(~factor(reef_name, levels = paste0("Reef ", 1:49)),ncol = 7)+
#  scale_x_continuous(breaks = scales::pretty_breaks()) +
#  labs(x = "Year", y = "Relative intensity of other disturbance", color = "") +
#  theme_bw(base_size = 18)+
#  theme(legend.position = "top")
# 
# plot(plot_ts_cyc)
# plot(plot_ts_dhw)
# plot(plot_ts_other)


#-----------------------------------------
# Additional plots - spatial domain
#-----------------------------------------
g_domain <-  ggplot() +
 # geom_sf(data = spatial_domain, fill = "#00FFC2", alpha = .2, color = "black", size = 1.5) + 
 geom_sf(data = spatial_domain, fill = "transparent", alpha = .2, color = "black", size = 1.5) + 
 geom_sf(data = reefs.sf$simulated_reefs_sf) +
 theme_bw() +
 xlab("Longitude") + ylab("Latitude") +
 theme_minimal(base_size = 12) +
 theme(
  axis.title = element_text(size = 13),
  axis.text = element_text(size = 11)
 )

## ---- SyntheticData_Spatial.mesh
mesh <- synthos:::create_spde_mesh(spatial_grid,config_sp)

g_mesh <- ggplot() +
 gg(mesh) +
 # geom_sf(data = spatial_domain, fill = "#00FFC2", alpha = .2, color = "black", size = 1.5) +
 geom_sf(data = spatial_domain, fill = "transparent", alpha = .2, color = "black", size = 1.5) + 
 coord_sf(crs = 4326, expand = FALSE) +
 scale_x_continuous(name = "Longitude") +
 scale_y_continuous(name = "Latitude") +
 theme_minimal(base_size = 12) +
 theme(
  axis.title = element_text(size = 13),
  axis.text = element_text(size = 11)
 )

g_fig1 <- g_domain + g_mesh + plot_annotation(tag_levels = 'a',  tag_suffix = ')') 
plot(g_fig1)


#-----------------------------------------
# Additional plots - Heat maps
#-----------------------------------------
#DHW 
dhw.pts.effects.df <- dhw$dhw_pts_effects_df %>%
 mutate(Dist = "DHW")

#CYC
cyc.pts.effects <- cyc$cyc_pts_effects%>%
 mutate(Dist = "CYC")

#OT
other.pts.effects <- other$other_pts_effects%>%
 mutate(Dist = "OT")

#All
all.pts.effects <- bind_rows(dhw.pts.effects.df, cyc.pts.effects, other.pts.effects) %>%
 arrange(Dist) %>%
 mutate(Dist_plot = case_when(Dist == "DHW" ~ "Coral bleaching",
                              Dist == "CYC" ~ "Cyclone",
                              Dist == "OT" ~ "Other"))


# Plots 
effects_by_dist <- all.pts.effects %>%
 group_split(Dist)  

dist_levels <- all.pts.effects %>% distinct(Dist_plot) %>% pull(Dist_plot)

plots_by_dist <- map2(
 effects_by_dist,
 dist_levels,
 ~ ggplot(.x, aes(y = Latitude, x = Longitude)) +
  geom_tile(aes(fill = Value)) +
  facet_wrap(~Year, ncol = 5) +
  scale_fill_gradientn("", colors = rev(heat.colors(10))) +
  coord_sf(crs = 4326) +
  ggtitle(.y) +
  theme_bw(base_size = 12) +
  theme(
   axis.title = element_blank(),
   legend.position = "top", 
   legend.justification = c(0.5, 1),
   legend.direction = "horizontal",
   axis.text = element_blank()
  )
)

plot(plots_by_dist[[1]])
plot(plots_by_dist[[2]])
plot(plots_by_dist[[3]])


#-----------------------------------------
# Additional plots - Synthetic Baselines
#-----------------------------------------
baseline.sample.hcc <- mesh$loc[,1:2] %>%
 as.data.frame() %>%
 dplyr::select(Longitude = V1, Latitude = V2) %>%
 mutate(clong = as.vector(scale(Longitude, scale = FALSE)),
        clat = as.vector(scale(Latitude, scale = FALSE)),
        Y = clong + sin(clat) + 
         1.5*clong + clat) %>%
 mutate(Y = scales::rescale(Y, to = c(-2, 0.8)))

baseline.effects.hcc <- baseline.sample.hcc %>%
 dplyr::select(Y) %>%
 as.matrix
baseline.pts.sample.hcc <- inla.mesh.project(mesh,
                                             loc=as.matrix(spatial.grid.pts.df [,1:2]),
                                             baseline.effects.hcc)
baseline.pts.effects.hcc = baseline.pts.sample.hcc %>% 
 cbind() %>% 
 as.matrix() %>% 
 as.data.frame() %>%
 cbind(spatial.grid.pts.df ) %>% 
 pivot_longer(cols = c(-Longitude,-Latitude),
              names_to = c('Year'),
              names_pattern = 'sample:(.*)',
              values_to = 'Value') %>%
 mutate(Year = as.numeric(Year))

p_baseline <- ggplot(baseline.pts.effects.hcc, aes(y = Latitude, x = Longitude)) +
 geom_tile(aes(fill = 100 * plogis(Value))) +
 scale_fill_distiller("Cover (%)", palette = "YlGnBu", direction = 1) +
 coord_sf(crs = 4326) +
 theme_bw(base_size = 12) +
 theme(
  axis.title = element_blank(),
  legend.position = "top",  
  legend.justification = c(0.5, 1),
  legend.direction = "horizontal"
 )


plot(p_baseline)


#-----------------------------------------
# Additional plots - monitoring location
#----------------------------------------
X_sf <- benthos_fixed_locs_obs %>%
 st_as_sf(coords = c("Longitude", "Latitude"),
          crs = st_crs(4326))

label_pts <- X_sf %>%
 group_by(Reef) %>%
 summarise(.groups = "drop") %>%
 st_point_on_surface()

p_reef <- ggplot() + 
 geom_sf(data = reefs.sf$simulated_reefs_sf, fill = "gray95") + 
 geom_sf(data = X_sf, col = "red", size = 1.2) +
 geom_sf_text(
  data = label_pts,
  aes(label = Reef),
  size = 3.5,
  nudge_y = 0.15   # shift labels to top
 ) +
 xlab("Longitude") + ylab("Latitude")  +
 coord_sf(crs = 4326) +
 theme_bw(base_size = 12) +
 theme(
  axis.title = element_text(size = 13),
  axis.text = element_text(size = 11)
 )

plot(p_reef)


