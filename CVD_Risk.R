library(shiny)
library(dplyr)
library(randomForest)
library(ggplot2)

# Load the dataset
combined_dataset <- readRDS("combined_dataset.rds")

# Load model
rf_model <- readRDS("rf_model.rds")

ui <- fluidPage(
  titlePanel("CVD Risk Predictor"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Please enter your details:"),
      numericInput("age", "Age (years):", value = 50, min = 20, max = 115, step = 1),
      numericInput("height", "Height (cm):", value = 170, min = 100, max = 250, step = 1),
      numericInput("waist", "Waist Circumference (cm):", value = 80, min = 30, max = 200, step = 1),
      h5("Calculated Waist-to-Height Ratio:"),
      verbatimTextOutput("waist_ht_ratio_display"),
      selectInput("gender", "Gender:",
                  choices = c("Male", "Female"), selected = "Male"),
      selectInput("ethnicity", "Ethnicity:",
                  choices = c("Mexican American", "Other Hispanic", "Non-Hispanic White",
                              "Non-Hispanic Black", "Non-Hispanic Asian", "Other Non-Hispanic"),
                  selected = "Non-Hispanic White"),
      numericInput("active", "Total Active Minutes per Week:", value = 150, min = 0, max = 2000, step = 10),
      numericInput("sedentary", "Total Sedentary Minutes per Day:", value = 480, min = 60, max = 1440, step = 30),
      selectInput("smoking", "Smoking Status:",
                  choices = c("Smoked 100+ cigarettes", "Never smoked 100+ cigarettes"),
                  selected = "Never smoked 100+ cigarettes"),
      selectInput("diabetes", "Diabetes Status:",
                  choices = c("Diabetes", "No Diabetes", "Borderline Diabetes"), 
                  selected = "No Diabetes"),
      
      actionButton("predict_btn", "Predict My CVD Risk"),
      h4("Prediction Result"),
      verbatimTextOutput("pred_result")
    ),
    
    mainPanel(
      h4("Explore Variables Related to CVD"),
      selectInput("var_to_plot", "Select Variable to Plot:",
                  choices = c(
                    "Age" = "RIDAGEYR",
                    "Waist-to-Height Ratio" = "waist_height_ratio",
                    "Total Active Minutes" = "total_active_minutes",
                    "Total Sedentary Minutes" = "total_sedentary_minutes",
                    "Gender" = "RIAGENDR",
                    "Ethnicity" = "RIDRETH3",
                    "Smoking Status" = "SMQ020",
                    "Diabetes Status" = "DIQ010"
                  )),
      plotOutput("var_plot"),
      div(
        h3("Learn More About Reducing Your Risk", style = "text-align: center; margin-top: 20px; font-size: 24px; font-weight: bold;")
      ),
      uiOutput("resources")
    )
  )
)

server <- function(input, output, session) {
  
  # Calculate waist-to-height ratio
  waist_ht_ratio <- reactive({
    input$waist / input$height
  })
  
  output$waist_ht_ratio_display <- renderText({
    round(waist_ht_ratio(), 2)
  })
  
  # Reactive expression for user's input data
  user_data <- reactive({
    data.frame(
      RIDAGEYR = input$age,
      RIAGENDR = factor(input$gender, levels = levels(combined_dataset$RIAGENDR)),
      RIDRETH3 = factor(input$ethnicity, levels = levels(combined_dataset$RIDRETH3)),
      waist_height_ratio = waist_ht_ratio(),
      total_active_minutes = input$active,
      total_sedentary_minutes = input$sedentary,
      SMQ020 = factor(input$smoking, levels = levels(combined_dataset$SMQ020)),
      DIQ010 = factor(input$diabetes, levels = levels(combined_dataset$DIQ010))
    )
  })
  
  # Predict and display result
  output$pred_result <- renderText({
    req(input$predict_btn)
    risk <- predict(rf_model, user_data(), type = "prob")[, 2]
    paste0("Your predicted risk of CVD is approximately ", round(risk * 100, 1), "%. ",
           "This is a statistical estimate based on the information you provided.")
  })
  
  # Function to plot selected variable vs. CVD in the training dataset
  output$var_plot <- renderPlot({
    var <- input$var_to_plot
    plot_data <- na.omit(combined_dataset)
    
    # Readable labels
    label_mapping <- c(
      "RIDAGEYR" = "Age",
      "waist_height_ratio" = "Waist-to-Height Ratio",
      "total_active_minutes" = "Total Active Minutes",
      "total_sedentary_minutes" = "Total Sedentary Minutes",
      "RIAGENDR" = "Gender",
      "RIDRETH3" = "Ethnicity",
      "SMQ020" = "Smoking Status",
      "DIQ010" = "Diabetes Status"
    )
    
    if (var %in% c("RIAGENDR", "RIDRETH3", "SMQ020", "DIQ010")) {
      # Categorical variables: Bar plot
      plot_data <- plot_data %>%
        group_by(.data[[var]]) %>%
        summarize(CVD_Proportion = mean(any_cvd == "CVD Present", na.rm = TRUE)) %>%
        mutate(Label = paste0(round(CVD_Proportion * 100, 1), "%"))  
      
      ggplot(plot_data, aes(x = reorder(.data[[var]], -CVD_Proportion), y = CVD_Proportion, fill = CVD_Proportion)) +
        geom_col(show.legend = FALSE, width = 0.7) +  
        geom_text(aes(label = Label), position = position_stack(vjust = 0.5), size = 4, color = "white") + 
        scale_fill_gradient(low = "steelblue", high = "darkblue") +  
        coord_flip() +  
        scale_y_continuous(labels = scales::percent_format()) +  
        labs(
          title = paste("CVD Proportion by", label_mapping[[var]]),
          x = label_mapping[[var]],
          y = "Proportion with CVD"
        ) +
        theme_minimal(base_size = 14) +  
        theme(
          plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),  
          axis.title.x = element_text(face = "bold"),  
          axis.title.y = element_text(face = "bold"),  
          panel.grid.major.y = element_blank(),  
          panel.grid.major.x = element_line(color = "gray90", linetype = "dotted")  
        )
    }
      
    else {
      # Continuous variables: Overlaid density plot
      user_value <- as.numeric(user_data()[[var]])
      
      ggplot(plot_data, aes(x = .data[[var]], fill = factor(any_cvd))) +
        geom_density(alpha = 0.6, color = NA) +  
        geom_vline(xintercept = user_value, color = "black", linetype = "dashed", size = 1) +  
        annotate("text", x = user_value, y = 0.05, label = paste("You: ", round(user_value, 2)),
                 hjust = -0.1, vjust = -0.5, color = "black", size = 4, fontface = "italic") +  
        scale_fill_manual(
          values = c("blue", "red"),
          labels = c("No CVD", "CVD Present")  
        ) +
        labs(
          title = paste("Density of", label_mapping[[var]], ": CVD Present vs No CVD"),
          x = label_mapping[[var]],
          y = "Density",
          fill = "CVD Status"
        ) +
        theme_minimal(base_size = 14) +  
        theme(
          plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),  
          axis.title.x = element_text(face = "bold"), 
          axis.title.y = element_text(face = "bold"),  
          legend.title = element_text(size = 14, face = "bold"),  
          legend.text = element_text(size = 12),  
          panel.grid.major = element_line(color = "gray90", linetype = "dotted"),  
          panel.grid.minor = element_blank(),  
          axis.text = element_text(size = 12)  
        )
    }
  })
  
  # Resources and Disclaimer
  output$resources <- renderUI({
    tagList(
      # Disclaimer Section
      h4("Disclaimer"),
      ("This app is a simple calculator designed to help users better understand the main risk factors associated with cardiovascular disease (CVD)."),
      ("It is not intended to replace professional medical advice, diagnosis, or treatment. If you are concerned about your health or your CVD risk, consult a qualified medical professional."),
      ("For a deeper understanding of your risk and steps to manage it, we strongly encourage you to explore the resources below and discuss your results with your doctor."),
      
      # Educational Resources
      h4("Learn More About Managing CVD Risk"),
      tags$ul(
        tags$li(a("American Heart Association: Understanding Your Risk",
                  href = "https://www.heart.org/en/health-topics/reduce-your-risk", target = "_blank")),
        tags$li(a("Centers for Disease Control and Prevention (CDC): Heart Disease Prevention",
                  href = "https://www.cdc.gov/heart-disease/prevention/index.html", target = "_blank")),
        tags$li(a("World Health Organization (WHO): Cardiovascular Diseases (CVDs)",
                  href = "https://www.who.int/news-room/fact-sheets/detail/cardiovascular-diseases-(cvds)", target = "_blank")),
        tags$li(a("Mayo Clinic: Lifestyle Changes to Lower CVD Risk",
                  href = "https://www.mayoclinic.org/diseases-conditions/heart-disease/in-depth/heart-healthy-lifestyle/art-20047702", target = "_blank")),
        tags$li(a("Harvard T.H. Chan School of Public Health: Preventing Heart Disease",
                  href = "https://www.hsph.harvard.edu/nutritionsource/disease-prevention/cardiovascular-disease/", target = "_blank"))
      ),
      
      # Call to action
      h4("Take Action Today"),
      p("Small changes in lifestyle can significantly reduce your CVD risk and extend your life expectancy. Consider:"),
      tags$ul(
        tags$li("Slowly increasing physical activity (e.g., walking, running, or cycling)."),
        tags$li("Reducing smoking, drinking, and sedentary behavior when you can."),
        tags$li("Managing chronic conditions with professional help.")
      ),
      p("Taking proactive steps now can improve your long-term health and quality of life.")
    )
  })
}

shinyApp(ui = ui, server = server)
