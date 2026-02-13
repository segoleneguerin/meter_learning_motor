# ------ PARAMETERS FOR PLOTS
# ------ Function definition
"%||%" <- function(a, b) {
  if (!is.null(a))
    a
  else
    b
}

geom_flat_violin <-
  function(mapping = NULL,
           data = NULL,
           stat = "ydensity",
           position = "dodge",
           trim = TRUE,
           scale = "area",
           show.legend = NA,
           inherit.aes = TRUE,
           ...) {
    ggplot2::layer(
      data = data,
      mapping = mapping,
      stat = stat,
      geom = GeomFlatViolin,
      position = position,
      show.legend = show.legend,
      inherit.aes = inherit.aes,
      params = list(trim = trim,
                    scale = scale,
                    ...)
    )
  }

GeomFlatViolin <-
  ggproto(
    "GeomFlatViolin",
    Geom,
    setup_data = function(data, params) {
      data$width <- data$width %||%
        params$width %||% (resolution(data$x, FALSE) * 0.9)
      
      # ymin, ymax, xmin, and xmax define the bounding rectangle for each group
      data %>%
        dplyr::group_by(.data = ., group) %>%
        dplyr::mutate(
          .data = .,
          ymin = min(y),
          ymax = max(y),
          xmin = x,
          xmax = x + width / 2
        )
    },
    
    draw_group = function(data, panel_scales, coord)
    {
      # Find the points for the line to go all the way around
      data <- base::transform(data,
                              xminv = x,
                              xmaxv = x + violinwidth * (xmax - x))
      
      # Make sure it's sorted properly to draw the outline
      newdata <-
        base::rbind(
          dplyr::arrange(.data = base::transform(data, x = xminv), y),
          dplyr::arrange(.data = base::transform(data, x = xmaxv), -y)
        )
      
      # Close the polygon: set first and last point the same
      # Needed for coord_polar and such
      newdata <- rbind(newdata, newdata[1,])
      
      ggplot2:::ggname("geom_flat_violin",
                       GeomPolygon$draw_panel(newdata, panel_scales, coord))
    },
    
    draw_key = draw_key_polygon,
    
    default_aes = ggplot2::aes(
      weight = 1,
      colour = "white",
      fill = "grey70",
      linewidth = 0.5,
      alpha = 0.4,
      linetype = "blank"
    ),
    
    required_aes = c("x", "y")
  )

# ------ Theme definition
apa7 <- 
  theme(panel.grid = element_blank(), # to delete the grid
        panel.background = element_rect(fill = "#FFFFFF"), # to add white background to panel
        plot.background = element_rect(fill = "#FFFFFF"), # to add white background to plot
        axis.text.y = element_text(color = "black"),
        axis.text.x = element_text(color = "black"), # to have black text
        axis.line = element_line(color ="black",
                                 linewidth = 0.231), # to add a black line
        axis.ticks = element_line(color ="black",
                                  linewidth = 0.231), # to add black ticks
        axis.title.y = element_text(face = "bold", # to have bold title
                                    margin = margin(t = 0, r = 15, b = 0, l = 0)), # to increase space between title and text label
        axis.title.x = element_text(face = "bold",
                                    margin = margin(t = 15, r = 0, b = 0, l = 0)),
        plot.subtitle = element_text(hjust = 0.5), # to have centered subtitle
        legend.position = "top", # to modify legend position
        rect = element_blank() # to delete background color
  ) 

# To change police size
theme_set(
  theme_classic(base_size = 20)
)