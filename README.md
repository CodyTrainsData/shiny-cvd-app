# CVD Risk Predictor

## Description
The **CVD Risk Predictor** is an interactive Shiny app designed to help users better understand the key risk factors associated with cardiovascular disease (CVD). Using data derived from the National Health and Nutrition Examination Survey (NHANES), this app allows users to input personalized health metrics and explore visualizations of CVD risk based on various demographic and health-related variables.

---

## Key Features
1. **Personalized Risk Estimation:**
   - Users can input their age, height, waist circumference, gender, ethnicity, activity levels, smoking status, and diabetes status.
   - The app calculates a personalized CVD risk based on these inputs using a pre-trained Random Forest model.

2. **Dynamic Visualizations:**
   - Explore how key variables such as age, gender, ethnicity, activity levels, and smoking status relate to CVD.
   - Continuous variables (e.g., age, waist-to-height ratio) are displayed using overlaid density plots with a marker highlighting the user’s input.
   - Categorical variables (e.g., gender, ethnicity) are displayed using bar plots showing proportions of CVD risk.

3. **Educational Resources:**
   - A dedicated section provides links to trusted resources for users to learn more about managing their cardiovascular health.

---

## How to Use
1. **Enter Your Details:**
   - Provide your age, height, waist circumference, gender, ethnicity, activity levels, smoking status, and diabetes status in the input fields on the left sidebar.
   - The app will automatically calculate your waist-to-height ratio.

2. **View Your Risk:**
   - Click the **"Predict My CVD Risk"** button to view your personalized CVD risk.

3. **Explore Variables:**
   - Use the dropdown menu to select variables and explore their relationship with CVD through interactive plots.

4. **Learn More:**
   - Visit the **"Learn More About Reducing Your Risk"** section to access educational resources and actionable tips.

---

## Technologies Used
- **R Shiny:** For building the interactive app interface.
- **Random Forest Model:** To calculate personalized CVD risk based on NHANES data.
- **ggplot2:** For creating visually appealing plots.
- **NHANES Data:** A trusted dataset used to identify key demographic and health-related risk factors for CVD.

---

## Dataset Information
The app uses a combined dataset (`combined_dataset.rds`) derived from NHANES, which includes:
- Demographic data (age, gender, ethnicity).
- Health metrics (waist circumference, height, activity levels).
- Lifestyle factors (smoking status, diabetes status).
- CVD outcome (presence or absence of CVD).

---

## Installation
To run the app locally:

1. Clone this repository:
   ```bash
   git clone https://github.com/CodyTrainsData/shiny-cvd-app.git
   cd shiny-cvd-app

	2.	Open app.R in RStudio.
	3.	Ensure the required packages are installed:

install.packages(c("shiny", "dplyr", "randomForest", "ggplot2"))

	4.	Run the app:

shiny::runApp()


Disclaimer:

This app is a simple calculator designed for educational purposes. It is not intended to replace professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider for medical concerns.
