dir <- "SHAP_heatmaps_E_figures/"

figures_dir_sp1 <-paste0(dir,"/E1/") 
figures_dir_sp2 <-paste0(dir,"/E2/") 
figures_dir_sp3 <-paste0(dir,"/E3/")

# Run # E1, E2 or E3, depending on which scenario you are plotting.

# E1
selected_reef = "Reef35"
selected_site = "S1"
relevant_year = 20
year_range <- 18:20

# E2
selected_reef = "Reef25"
selected_site = "S1"
relevant_year = 6
year_range <- 4:6

# E3 
selected_reef = "Reef44"
selected_site = "S2"
relevant_year = 26
year_range <- 24:26

plots_LD <- list()

type = "CYC" # To get the heatmaps for Bleaching and Other disturbances, change the type to "DHW" or "OT".


for (year_to_show in year_range) {
 
 filterd_dist <- all.pts.effects %>%
  filter(Dist == type, Year == year_to_show)
 
 test <- X_sf %>% filter(Reef == "Reef16") %>% filter(Site == "S3")
 
 # vmin <- ranges_by_dist %>% filter(Dist == type) %>% pull(vmin)
 # vmax <- ranges_by_dist %>% filter(Dist == type) %>% pull(vmax)
 
 vmin = 0
 vmax = 0.8
 
 plot_LD <- ggplot() +
  geom_tile(data = filterd_dist,
            aes(x = Longitude, y = Latitude, fill = Value*0.8)) + # change "Value*0.8" to "Value*0.1" when getting plots for DHW and OT.
  scale_fill_gradientn("weighted\ncyclone intensity", colors = rev(heat.colors(10)),  limits = c(vmin, vmax)) + # change the title accordingly
  # scale_fill_gradientn("", colors = rev(heat.colors(10)),  limits = c(vmin, vmax)) +
  geom_sf(data = reefs.sf$simulated_reefs_sf, fill = NA, color = "gray40") +
  geom_sf(data = X_sf, color = "grey30", size = 0.1, shape = 21) + 
  geom_sf(data = X_sf %>% filter(Reef == selected_reef) %>% filter(Site == selected_site),
          color = "blue",  fill = "blue", size = 3, shape = 22, stroke = 0.8)+
  # geom_sf_text(data = label_pts, aes(label = gsub("Reef", "", Reef)), size = 1.75, nudge_y = 0.1) + #removed reef number
  coord_sf(crs = 4326) +
  xlab("Longitude") + ylab("Latitude") +
  ggtitle(paste("Year", year_to_show, "")) +
  theme_bw(base_size = 12) +
  theme(
   text = element_text(family = "serif"),
   axis.title = element_text(size = 12),
   axis.text  = element_text(size = 12),
   plot.title = element_text(size = 12)
  )
 
 plots_LD[[length(plots_LD) + 1]] <- plot_LD
 
}

pages <- split(plots_LD, ceiling(seq_along(plots_LD) / 3))


for (i in seq_along(pages)) {
 grid <- wrap_plots(pages[[i]], ncol = 3) +         
  plot_layout(guides = "collect") &          
  theme(legend.position = "right")
 ggsave(file.path(figures_dir_sp3, sprintf(paste0(selected_reef, "_", selected_site, "_", type, ".png"), i)),
        grid, width = 11.7, height = 3, dpi = 300)  # Change figures_dir_sp1 to figures_dir_sp2 or figures_dir_sp3, when plotting for E2 and E3
}





























