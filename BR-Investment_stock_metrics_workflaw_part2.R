file_path <- "C:/Users/leonb/OneDrive/Documents/Custom Office Templates/Wealthyhood_investment_metrics_completed alert.xlsx"

library(readxl)   # <-- required for read_excel()
library(dplyr)
library(ggplot2)

df <- read_excel(file_path, sheet = 1)


# Step 2: Create age groups and summarize repeat/churn
df_age <- df |>
  dplyr::mutate(
    Age_Group = dplyr::case_when(
      Age >= 18 & Age <= 25 ~ "18-25",
      Age >= 26 & Age <= 35 ~ "26-35",
      Age >= 36 & Age <= 45 ~ "36-45",
      Age >= 46 & Age <= 55 ~ "46-55",
      Age >= 56             ~ "56+",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(Age_Group)) |>
  dplyr::group_by(Age_Group) |>
  dplyr::summarise(
    Avg_Repeat_Rate = mean(Repeat_Purchase_Rate_pct, na.rm = TRUE),
    Avg_Churn_Rate  = mean(Churn_Rate_pct, na.rm = TRUE),
    Users = dplyr::n(),
    .groups = "drop"
  )

print(df_age)
message("Step 2 complete: Repeat and churn rates summarized by age group.")

# Step 3: Plot Repeat vs Churn by Age Group
df_plot <- df_age |>
  tidyr::pivot_longer(cols = c("Avg_Repeat_Rate", "Avg_Churn_Rate"),
                      names_to = "Metric",
                      values_to = "Value")

p <- ggplot(df_plot, aes(x = Age_Group, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  labs(
    title = "Repeat vs. Churn Rates by Age Group",
    x = "Age Group",
    y = "Rate (%)",
    fill = "Metric"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p)


# Step 2: Compute time between purchases for repeat investors
df_gaps <- df |>
  mutate(Purchase_Date = as.Date(Purchase_Date)) |>
  arrange(User_ID, Purchase_Date) |>
  group_by(User_ID) |>
  mutate(
    Days_Between = as.numeric(Purchase_Date - lag(Purchase_Date))
  ) |>
  filter(!is.na(Days_Between)) |>
  summarise(
    Avg_Days_Between = mean(Days_Between, na.rm = TRUE),
    Num_Purchases = n() + 1,
    .groups = "drop"
  ) |>
  filter(Num_Purchases > 1)  # Only repeat investors

print(head(df_gaps, 10))
message("Step 2 complete: Purchase gaps calculated.")

# Step : Plot histogram of average purchase gaps
p <- ggplot(df_gaps, aes(x = Avg_Days_Between)) +
  geom_histogram(
    bins = 30, 
    fill = "steelblue", 
    color = "white", 
    alpha = 0.8
  ) +
  labs(
    title = "Average Time Between Purchases (Repeat Investors)",
    x = "Avg Days Between Purchases",
    y = "Number of Users"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13)
  )

print(p)

# Save
ggsave("avg_time_between_purchases_histogram.png", p, width = 9, height = 5, dpi = 300)
message("Step complete: Chart saved as avg_time_between_purchases_histogram.png")

library(readxl)
library(dplyr)
library(ggplot2)

df <- read_excel(file_path, sheet = 1)

# Confirm columns exist
required_cols <- c("Asset_Name", "Purchase_Value", "Sell_Value")
missing_cols <- setdiff(required_cols, names(df))
if(length(missing_cols)) stop("Missing columns: ", paste(missing_cols, collapse = ", "))

message("Step 1 complete: Columns confirmed.")

# Step 2: Compute ROI per transaction
df_roi <- df |>
  mutate(
    ROI_pct = ((Sell_Value - Purchase_Value) / Purchase_Value) * 100
  ) |>
  filter(!is.na(ROI_pct) & is.finite(ROI_pct))

print(head(df_roi, 10))
message("Step 2 complete: ROI per transaction calculated.")


# Step 3: Compute average ROI by asset subcategory
df_asset_roi <- df_roi |>
  group_by(Asset_Name) |>
  summarise(
    Avg_ROI = mean(ROI_pct, na.rm = TRUE),
    Transactions = n(),
    .groups = "drop"
  ) |>
  arrange(desc(Avg_ROI))

print(df_asset_roi)
message("Step 3 complete: Average ROI by asset subcategory calculated.")


library(lubridate)

# STEP 2: Create weekday/weekend classification
df_daytype <- df |>
  mutate(
    Purchase_Date = as.Date(Purchase_Date),
    Weekday = wday(Purchase_Date, label = TRUE, abbr = TRUE),
    Day_Type = ifelse(weekdays(Purchase_Date) %in% c("Saturday", "Sunday"),
                      "Weekend", "Weekday")
  ) |>
  filter(!is.na(Purchase_Date))

print(head(df_daytype, 10))
message("Step 2 complete: Day type classification created.")

df_patterns <- df_daytype |>
  group_by(Day_Type) |>
  summarise(
    Total_Transactions = n(),
    Total_Investment = sum(Purchase_Value, na.rm = TRUE),
    Avg_Investment = mean(Purchase_Value, na.rm = TRUE),
    .groups = "drop"
  )

print(df_patterns)
message("Step 3 complete: Investment patterns summarized.")


# ---------- SAFE RUN: create df_daytype then compute df_patterns ----------
# 1) Load required packages
if(!"dplyr" %in% installed.packages()[, "Package"]) install.packages("dplyr")
if(!"ggplot2" %in% installed.packages()[, "Package"]) install.packages("ggplot2")
if(!"lubridate" %in% installed.packages()[, "Package"]) install.packages("lubridate")

library(dplyr)
library(ggplot2)
library(lubridate)

# 2) Ensure df exists
if(!exists("df")) stop("Data frame 'df' not found. Run the code that reads the Excel into df first.")

# 3) Create df_daytype (robust date parsing)
df_daytype <- df %>%
  mutate(
    # try to coerce Purchase_Date to Date safely:
    Purchase_Date = as.Date(Purchase_Date),
    # if that produced many NAs, try lubridate parsing (ISO/other formats)
    Purchase_Date = ifelse(is.na(Purchase_Date),
                           as.character(NA),   # placeholder to keep column type safe
                           as.character(Purchase_Date)
    )
  ) %>%
  # second pass: try lubridate parsing for non-NA character dates
  mutate(
    Purchase_Date = dplyr::if_else(
      is.na(as.Date(Purchase_Date, format = "%Y-%m-%d")),
      # try parsing with lubridate guess parser; keep NA if still NA
      as.character(suppressWarnings(lubridate::ymd(Purchase_Date))),
      Purchase_Date
    )
  ) %>%
  # finally coerce properly (some entries may still be NA)
  mutate(Purchase_Date = as.Date(Purchase_Date)) %>%
  # create weekday and Day_Type (weekend/weekday)
  mutate(
    Weekday = wday(Purchase_Date, label = TRUE, abbr = TRUE),
    Day_Type = ifelse(weekdays(Purchase_Date) %in% c("Saturday", "Sunday"), "Weekend", "Weekday")
  ) %>%
  filter(!is.na(Purchase_Date))   # remove rows with invalid dates

# 4) Quick checks
if(!exists("df_daytype")) stop("Failed to create df_daytype. Check Purchase_Date values.")
message("df_daytype rows: ", nrow(df_daytype))
print(head(df_daytype, 8))

# 5) Step 3: summarize patterns (Weekday vs Weekend)
df_patterns <- df_daytype %>%
  group_by(Day_Type) %>%
  summarise(
    Total_Transactions = n(),
    Total_Investment = sum(Purchase_Value, na.rm = TRUE),
    Avg_Investment = mean(Purchase_Value, na.rm = TRUE),
    .groups = "drop"
  )

print(df_patterns)
message("Step 3 complete: Investment patterns summarized.")
# -----------------------------------------------------------------------


library(readxl)
library(dplyr)
library(ggplot2)

df <- read_excel(file_path, sheet = 1)

# Check required columns
required_cols <- c("Purchase_Value", "Sell_Value")
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols)) stop("Missing columns: ", paste(missing_cols, collapse = ", "))

message("Step 1 complete: Columns confirmed.")


# Step 2: Categorize investment sizes and outcomes

df_size <- df |>
  mutate(
    ROI_pct = ((Sell_Value - Purchase_Value) / Purchase_Value) * 100,
    
    # Investment size category
    Investment_Size = case_when(
      Purchase_Value < 2000 ~ "Small",
      Purchase_Value >= 2000 & Purchase_Value <= 7500 ~ "Medium",
      Purchase_Value > 7500 ~ "Large",
      TRUE ~ NA_character_
    ),
    
    # Outcome category
    Outcome = case_when(
      ROI_pct < 0 ~ "Loss",
      ROI_pct >= 0 & ROI_pct < 5 ~ "Break-even",
      ROI_pct >= 5 ~ "Profit",
      TRUE ~ "Unknown"
    )
  ) |>
  filter(!is.na(Investment_Size))

print(head(df_size, 10))
message("Step 2 complete: Investment sizes and outcomes classified.")

# Step 3: Summarize distribution
df_distribution <- df_size |>
  group_by(Investment_Size, Outcome) |>
  summarise(
    Count = n(),
    Avg_ROI = mean(ROI_pct, na.rm = TRUE),
    .groups = "drop"
  )

print(df_distribution)
message("Step 3 complete: Distribution summarized.")

# Step 4: Plot distribution of investment sizes vs outcomes
p <- ggplot(df_distribution, aes(x = Investment_Size, y = Count, fill = Outcome)) +
  geom_bar(stat = "identity", width = 0.7) +
  labs(
    title = "Distribution of Investment Sizes and Outcomes",
    x = "Investment Size Category",
    y = "Number of Investments",
    fill = "Outcome"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13)
  )

print(p)

# Save chart
ggsave("investment_size_outcome_distribution.png", p, width = 9, height = 5, dpi = 300)
message("Step 4 complete: Chart saved as investment_size_outcome_distribution.png")


library(readxl)
library(dplyr)
library(ggplot2)

df <- read_excel(file_path, sheet = 1)

# Columns needed
required_cols <- c("Retention_Months", "Purchase_Value", "Sell_Value")
missing_cols <- setdiff(required_cols, names(df))
if(length(missing_cols)) stop("Missing required columns: ", paste(missing_cols, collapse = ", "))

message("Step 1 complete: Columns confirmed.")


# Step 2: Prepare dataset with retention and ROI
df_ret_roi <- df |>
  mutate(
    ROI_pct = ((Sell_Value - Purchase_Value) / Purchase_Value) * 100
  ) |>
  filter(
    !is.na(Retention_Months),
    !is.na(ROI_pct),
    is.finite(ROI_pct)
  )

print(head(df_ret_roi, 10))
message("Step 2 complete: ROI % and retention months cleaned.")


# Step 4: Scatter plot of Retention vs ROI
p <- ggplot(df_ret_roi, aes(x = Retention_Months, y = ROI_pct)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 1) +
  labs(
    title = "Correlation Between Retention Duration and ROI",
    x = "Retention (Months)",
    y = "ROI (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13)
  )

print(p)

# Save
ggsave("retention_vs_roi_correlation.png", p, width = 9, height = 5, dpi = 300)
message("Step 4 complete: Chart saved as retention_vs_roi_correlation.png")


library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)

df <- read_excel(file_path, sheet = 1)

# Ensure Purchase_Date exists
if(!"Purchase_Date" %in% names(df)) stop("Purchase_Date column missing")

df <- df |> mutate(Purchase_Date = as.Date(Purchase_Date))
message("Step 1 complete: Dataset loaded and Purchase_Date processed.")

df_signup <- df |>
  group_by(User_ID) |>
  summarise(Signup_Month = floor_date(min(Purchase_Date), "month")) 

head(df_signup)
message("Step 2 complete: Signup month (first purchase month) created.")

df_signup <- df |>
  group_by(User_ID) |>
  summarise(Signup_Month = floor_date(min(Purchase_Date), "month")) 

head(df_signup)
message("Step 2 complete: Signup month (first purchase month) created.")

df_with_signup <- df |>
  left_join(df_signup, by = "User_ID") |>
  mutate(
    Txn_Month = floor_date(Purchase_Date, "month"),
    Months_Since_Signup = interval(Signup_Month, Txn_Month) %/% months(1)
  )

head(df_with_signup)
message("Step 3 complete: Months since signup calculated.")


# Count unique users active per cohort month
df_cohort <- df_with_signup |>
  filter(Months_Since_Signup <= 6) |>
  group_by(Signup_Month, Months_Since_Signup) |>
  summarise(Active_Users = n_distinct(User_ID), .groups = "drop")

# Size of each user cohort
df_cohort_size <- df_signup |>
  group_by(Signup_Month) |>
  summarise(Cohort_Size = n())

# Merge
df_retention <- df_cohort |>
  left_join(df_cohort_size, by = "Signup_Month") |>
  mutate(Retention_Rate = Active_Users / Cohort_Size)

print(df_retention)
message("Step 4 complete: Cohort retention table created.")

p <- ggplot(df_retention, aes(x = Months_Since_Signup,
                              y = format(Signup_Month, "%Y-%m"),
                              fill = Retention_Rate)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "#e6f2ff", high = "#003d99") +
  labs(
    title = "Cohort Retention Over 6 Months",
    x = "Months Since Signup",
    y = "Signup Cohort (Month)",
    fill = "Retention Rate"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

print(p)

ggsave("cohort_retention_6months.png", p, width = 9, height = 6, dpi = 300)
message("Saved heatmap: cohort_retention_6months.png")

library(readxl)
library(dplyr)

df <- read_excel(file_path, sheet = 1)

message("Step 1 complete: Dataset loaded.")

df_vip <- df |>
  group_by(User_ID) |>
  summarise(
    Lifetime_Investment = sum(Purchase_Value, na.rm = TRUE),
    Lifetime_Return = sum(Sell_Value, na.rm = TRUE),
    Lifetime_ROI_pct = ((Lifetime_Return - Lifetime_Investment) / Lifetime_Investment) * 100
  ) |>
  ungroup()

head(df_vip)
message("Step 2 complete: Lifetime investment & ROI computed.")


