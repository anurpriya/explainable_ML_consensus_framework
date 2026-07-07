# NOTE - First run synthetic_data_generation.R

library(ggpubr)
library(scico)

paper_theme <- theme_minimal(base_size = 14) +
 theme(
  # global font
  text = element_text(family = "serif"),
  
  # axes
  axis.title = element_text(size = 28),
  axis.text  = element_text(size = 26),
  
  # plot title
  plot.title = element_text(size = 28, face = "bold"),
  
  # legend layout
  legend.position = "top",
  legend.direction = "horizontal",
  legend.title = element_text(size = 20),
  legend.text  = element_text(size = 20),
  
  # legend appearance
  legend.background = element_blank(),
  legend.key = element_blank(),
  
  # grid
  panel.grid.minor = element_blank(),
  
  plot.tag = element_text(size = 28, face = "bold"),
  plot.tag.position = c(0.02, 1.1)  # x, y (0-1)
 )

#---------------------------------------
# Spatial domain
#----------------------------------------
g_domain <-  ggplot() +
 geom_sf(data = spatial_domain, fill = "#00FFC2", alpha = .2, color = "black", size = 1.5) +
 # geom_sf(data = spatial_domain, fill = "transparent", alpha = .2, color = "black", size = 1.5) + 
 geom_sf(data = reefs.sf$simulated_reefs_sf) +
 theme_bw() +
 xlab("Longitude") + ylab("Latitude") +  paper_theme

## ---- SyntheticData_Spatial.mesh
mesh <- synthos:::create_spde_mesh(spatial_grid,config_sp)

g_mesh <- ggplot() +
 gg(mesh) +
 geom_sf(data = spatial_domain, fill = "#00FFC2", alpha = .2, color = "black", size = 1.5) +
 # geom_sf(data = spatial_domain, fill = "transparent", alpha = .2, color = "black", size = 1.5) + 
 coord_sf(crs = 4326, expand = FALSE) +
 scale_x_continuous(name = "Longitude") +
 scale_y_continuous(name = "Latitude")  +  paper_theme

g_fig1 <- g_domain + g_mesh + plot_annotation(tag_levels = 'a',  tag_suffix = ')', tag_prefix  ='(') 
plot(g_fig1)

#---------------------------------------
# Synthetic Baselines
#----------------------------------------
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
 scale_fill_distiller("Cover (%)", palette = "YlGnBu", direction = 1,breaks = c(30, 40, 50)) +
 coord_sf(crs = 4326) +
 labs(x = "Longitude", y = "Latitude")+
 theme_bw(base_size = 12) +
 theme_bw(base_size = 12) +
 theme(
  text = element_text(family = "serif"),
  axis.title = element_text(size = 22),
  axis.text  = element_text(size = 20),
  plot.title = element_text(size = 22, face = "bold"),
  legend.position = "top",
  legend.direction = "horizontal",
  legend.title = element_text(size = 20),
  legend.text  = element_text(size = 16))
plot(p_baseline)


#---------------------------------------
# Monitoring locations 
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
 geom_sf(data = X_sf, col = "red", size = 2) +
 # geom_sf_text(
 #  data = label_pts,
 #  aes(label = Reef),
 #  size = 3.5,
 #  nudge_y = 0.15   # shift labels to top
 # ) +
 xlab("Longitude") + ylab("Latitude")  +
 coord_sf(crs = 4326) +
 theme_bw(base_size = 12) +
 theme(
  text = element_text(family = "serif"),
  axis.title = element_text(size = 22),
  axis.text  = element_text(size = 20),
  plot.title = element_text(size = 22, face = "bold"),
  legend.position = "top",
  legend.direction = "horizontal",
  legend.title = element_text(size = 20),
  legend.text  = element_text(size = 20))

plot(p_reef)


#---------------------------------------
# Heat maps
#----------------------------------------
vmin = 0
vmax = 1

plots_by_dist <- map2(
 effects_by_dist,
 dist_levels,
 ~ ggplot(.x, aes(y = Latitude, x = Longitude)) +
  geom_tile(aes(fill = Value)) +
  facet_wrap(~Year, ncol = 5) +
  scale_fill_gradientn("Other intensity", colors = rev(heat.colors(10)),limits = c(vmin, vmax),breaks = seq(0, 1, by = 0.4)) +
  coord_sf(crs = 4326) +
  labs(x = "Longitude", y = "Latitude")+
  # theme_pubr() +
  theme_bw(base_size = 12) +
  theme(
  text = element_text(family = "serif"),
  axis.title = element_text(size = 18),
  axis.text  = element_text(size = 13),
  # plot.title = element_text(size = 16, face = "bold"),
  legend.position = "top",
  legend.title.position = "top",
  legend.justification = c(0.5, 1),
  legend.direction = "horizontal",
  legend.title = element_text(size = 16),
  # legend.text  = element_text(size = 14),
  legend.text = element_text(size = 13, angle = 45, hjust = 1),
  # legend.text = element_text(angle = 45, hjust = 1),
  strip.background = element_rect(fill = 'white'),
  strip.text = element_text(size = 14)
  # axis.text.x = element_text(angle = 90, vjust = 0.5)
  )
)

plot1<-plot(plots_by_dist[[1]])
plot2<-plot(plots_by_dist[[2]])
plot3<-plot(plots_by_dist[[3]])


#---------------------------------------
# Weighted heat maps
#----------------------------------------
vmin = 0
vmax = 0.8

plots_by_dist <- map2(
 effects_by_dist,
 dist_levels,
 ~ ggplot(.x, aes(y = Latitude, x = Longitude)) +
  geom_tile(aes(fill = Value*0.1)) +
  facet_wrap(~Year, ncol = 5) +
  scale_fill_gradientn("Weighted\nother intensity", colors = rev(heat.colors(10)),limits = c(vmin, vmax),breaks = seq(0, 0.8, by = 0.2)) +
  coord_sf(crs = 4326) +
  labs(x = "Longitude", y = "Latitude")+
  # theme_pubr() +
  theme_bw(base_size = 12) +
  theme(
   text = element_text(family = "serif"),
   axis.title = element_text(size = 18),
   axis.text  = element_text(size = 13),
   # plot.title = element_text(size = 16, face = "bold"),
   legend.position = "top",
   legend.title.position = "top",
   legend.justification = c(0.5, 1),
   legend.direction = "horizontal",
   legend.title = element_text(size = 16),
   # legend.text  = element_text(size = 14),
   legend.text = element_text(size = 13, angle = 45, hjust = 1),
   # legend.text = element_text(angle = 45, hjust = 1),
   strip.background = element_rect(fill = 'white'),
   strip.text = element_text(size = 14)
   # axis.text.x = element_text(angle = 90, vjust = 0.5)
  )
)

plot1<-plot(plots_by_dist[[1]])
plot2<-plot(plots_by_dist[[2]])
plot3<-plot(plots_by_dist[[3]])
