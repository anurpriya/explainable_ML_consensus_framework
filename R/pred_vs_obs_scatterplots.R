library(readr)
library(ggplot2)
library(cowplot)

RF_Train <- read_csv("../data/RF_Predictions_training_I.csv")
RF_Test <- read_csv("../data/RF_Predictions_test_I.csv")

BRT_Train <- read_csv("../data/BRT_Predictions_training_I.csv")
BRT_Test <- read_csv("../data/BRT_Predictions_test_I.csv")

MLP_Train <- read_csv("../data/MLP_Predictions_training_I.csv")
MLP_Test <- read_csv("../data/MLP_Predictions_test_I.csv")

GAM_Train <- read_csv("../data/GAM_Predictions_training_I.csv")
GAM_Test <- read_csv("../data/GAM_Predictions_test_I.csv")


# Predicted vs observed MHCC plot for training data

Training_Data<- data.frame(
 Actual = RF_Train$Actual,
 GAM = GAM_Train$Predicted,
 RF = RF_Train$Predicted,
 BRT = BRT_Train$Predicted,
 MLP = MLP_Train$Predicted
)


train<-ggplot(data = Training_Data, aes(x = Actual)) +
 geom_point(aes(y = GAM, color = "GAM"), size = 5, alpha = 0.4)+
 geom_point(aes(y = RF, color = "RF"), size = 5, alpha = 0.4) +
 geom_point(aes(y = BRT, color = "BRT"), size = 5, alpha = 0.4) +
 geom_point(aes(y = MLP, color = "MLP"), size = 5, alpha = 0.4) +
 geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray", size = 1) +
 labs(title = "Training",
      x = "Observed MHCC (%)",
      y = "Predicted MHCC (%)") +
 scale_color_manual(name = "", values = c("GAM" = "#C77CFF", "RF" = "#00A9FF", "BRT" = "#7CAE00", "MLP" = "#F8766D"),
                    breaks = c("GAM", "RF", "BRT", "MLP")) +
 theme_minimal(base_family = "serif")+
 scale_x_continuous(breaks = seq(0, 100, by = 10)) + 
 scale_y_continuous(breaks = seq(0, 100, by = 10)) +
 theme(axis.title.x = element_text(size =23),
       axis.title.y = element_text(size =23),
       axis.text.y = element_text(size = 22),
       axis.text.x = element_text(size = 22),
       legend.title = element_text(size = 22),
       legend.text = element_text(size =22),
       plot.title = element_text(size=25,hjust = 0.5))+
 
 guides(color =guide_legend(override.aes = list(size =6)))

plot(train)


# Predicted vs observed MHCC plot for test data

Test_Data<- data.frame(
 Actual = RF_Test$Actual,
 GAM = GAM_Test$Predicted,
 RF = RF_Test$Predicted,
 BRT = BRT_Test$Predicted,
 MLP = MLP_Test$Predicted
)


test<-ggplot(data = Test_Data, aes(x = Actual)) +
 geom_point(aes(y = GAM, color = "GAM"), size = 5, alpha = 0.4)+
 geom_point(aes(y = RF, color = "RF"), size = 5, alpha = 0.4) +
 geom_point(aes(y = BRT, color = "BRT"), size = 5, alpha = 0.4) +
 geom_point(aes(y = MLP, color = "MLP"), size = 5, alpha = 0.4) +
 geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray", size = 1) +
 labs(title = "Test",
      x = "Observed MHCC (%)",
      y = "Predicted MHCC (%)") +
 scale_color_manual(name = "Method", values = c("GAM" = "#C77CFF", "RF" = "#00A9FF", "BRT" = "#7CAE00", "MLP" = "#F8766D"),
                    breaks = c("GAM", "RF", "BRT", "MLP")) +
 theme_minimal(base_family = "serif")+
 scale_x_continuous(breaks = seq(0, 100, by = 10)) + 
 scale_y_continuous(breaks = seq(0, 100, by = 10))+
 theme(axis.title.x = element_text(size =23),
       axis.title.y = element_text(size =23),
       axis.text.y = element_text(size = 22),
       axis.text.x = element_text(size = 22),
       legend.title = element_text(size = 22),
       legend.text = element_text(size =22),
       plot.title = element_text(size=25,hjust = 0.5))+
 
 guides(color =guide_legend(override.aes = list(size =6)))

plot(test)

# Display the two plots as a two-panel figure.

legend <- get_legend(train + theme(legend.position = "bottom"))

train <- train + theme(legend.position = "none")
test <- test + theme(legend.position = "none")

combined <- plot_grid(
 train, test,
 ncol = 2,
 align = "hv",
 labels = c("(a)", "(b)"),
 label_size = 24,
 label_fontface = "bold",
 label_fontfamily = "serif",
 label_x = 0,
 label_y = 1,
 hjust = 0,
 vjust = 1
)

combined_plot <- plot_grid(
 combined, legend,
 ncol = 1,
 rel_heights = c(1, 0.15)
)

print(combined_plot)


