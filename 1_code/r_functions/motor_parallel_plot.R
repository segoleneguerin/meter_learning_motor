# ------ PARALLEL PLOT
motor_parallel_plot <- function(nb_participant, path_z_scores, list_files){
  
  # ------ Packages loading
  library(GGally) # to plot parallel plots
  
  # ------ Data loading
  # Create an empty matrix to store the data
  data_file <- data.frame()
  
  # Read the data
  for (participant in nb_participant) {
    
    participant_file <-  read_csv(paste(path_z_scores, list_files[participant],
                                        sep = "/"),
                                  show_col_types = FALSE)
    
    data_file <- rbind(data_file, participant_file)
    
  }
  
  # ------ Prepare data
  # Keep only relevant data
  data_file <- data_file[ , c(1:4)]
    
  # Tidy data
  data_tidy <- data_file %>%
    gather(key = meter, value = z_scores, -participant, -session)
  
  data_tidy$meter <- as.factor(data_tidy$meter)
  data_tidy$participant <- as.factor(data_tidy$participant)
  data_tidy$session <- as.factor( data_tidy$session)
  
  # ------ Plot
  parallel_plot <-
    ggplot(data_tidy, aes(x = session, y = z_scores,
                          color = meter, shape = participant, 
                          group = interaction(meter, participant))) +
    geom_point(size = 3, alpha = 0.9) +
    geom_path(aes(color = meter), alpha = 0.7, linewidth = 1.5) +
    geom_segment(aes(x = 0.95, xend = 1.05, y = -0.32356, yend = -0.32358),
                 linewidth = 2, colour = "darkgrey", alpha = 0.5) +
    geom_segment(aes(x = 1.95, xend = 2.05, y = -0.32356, yend = -0.32358),
                 linewidth = 2, colour = "darkgrey", alpha = 0.5) +
    guides(shape = "none") +
    labs(x = "Session",
         y = "z scores",
         color = "Frequencies") +
    scale_x_discrete(labels = c("Pre training", "Post training")) +
    scale_color_discrete(labels = c("Meter related", 
                                    "Meter unrelated")) +
    geom_hline(aes(yintercept = 0), linetype = "dashed",
               color = "darkgray", alpha = 1) +
    apa7
  
  # ------ Output
  return(parallel_plot)
  
}