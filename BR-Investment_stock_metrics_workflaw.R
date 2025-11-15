# Install (if needed) and load packages
needed <- c("readxl","dplyr","tidyr","ggplot2","forcats","scales","pheatmap","tibble")
to_install <- needed[!(needed %in% installed.packages()[, "Package"])]
if(length(to_install)) install.packages(to_install)

# load
lapply(needed, library, character.only = TRUE)
message("Step 0 complete: packages loaded.")

# point to file and inspect
file_path <- "C:/Users/leonb/OneDrive/Documents/Custom Office Templates/Wealthyhood_investment_metrics_completed alert.xlsx"
# show working directory for context
message("getwd(): ", getwd())

# List sheets and show first 6 rows of the first sheet
sheets <- excel_sheets(file_path)
message("Sheets found: ", paste(sheets, collapse = " | "))
df_preview <- readxl::read_excel(file_path, sheet = sheets[1], n_max = 10)
print(names(df_preview))
print(head(df_preview, 6))
message("Step 1 complete: file preview shown. If nothing printed, check the file_path.")

# Choose column names (edit these if needed based on Step 1 output)
# If auto-detect fails, replace the strings below with the exact column names printed in Step 1.
age_col_manual  <- NA   # e.g. "Age_Group" or "Age"
asset_col_manual <- NA  # e.g. "Asset_Class" or "Asset"

# helper to auto-find plausible columns
find_col <- function(df, candidates){
  nm <- names(df)
  for (cand in candidates){
    matches <- nm[tolower(gsub("[^A-Za-z0-9]","",nm)) == tolower(gsub("[^A-Za-z0-9]","",cand))]
    if(length(matches)) return(matches[1])
  }
  for (cand in candidates){
    i <- grep(tolower(gsub("[^A-Za-z0-9]","",cand)), tolower(gsub("[^A-Za-z0-9]","",nm)))
    if(length(i)) return(nm[i[1]])
  }
  return(NA_character_)
}

df_sample <- readxl::read_excel(file_path, sheet = sheets[1], n_max = 200)
age_candidates <- c("Age_Group","Age group","AgeGroup","Age_Band","AgeRange","Age")
asset_candidates <- c("Asset_Class","Asset Class","AssetClass","Asset","Investment_Class","Category")

age_col_auto  <- find_col(df_sample, age_candidates)
asset_col_auto <- find_col(df_sample, asset_candidates)

age_col <- if(!is.na(age_col_manual)) age_col_manual else age_col_auto
asset_col <- if(!is.na(asset_col_manual)) asset_col_manual else asset_col_auto

message("Chosen age column: ", age_col)
message("Chosen asset column: ", asset_col)

if(is.na(age_col) || is.na(asset_col)) {
  stop("Please set age_col_manual and/or asset_col_manual to the correct column names (seen in Step 1).")
}
message("Step 2 complete: columns selected.")

# Step 3: read and clean the two columns
df <- readxl::read_excel(file_path, sheet = sheets[1], col_types = "text") %>%
  dplyr::select(all_of(c(age_col, asset_col))) %>%
  dplyr::rename(Age = all_of(age_col), Asset = all_of(asset_col)) %>%
  dplyr::mutate(Age = as.character(trimws(Age)), Asset = as.character(trimws(Asset))) %>%
  dplyr::filter(!is.na(Age) & Age != "" & !is.na(Asset) & Asset != "")

message("Rows after cleaning: ", nrow(df))
print(head(df, 10))
message("Step 3 complete.")

# create Age_Group if Age is numeric, otherwise treat Age as group labels
if (all(grepl("^[0-9]+$", df$Age))) {
  df <- df %>%
    dplyr::mutate(Age = as.numeric(Age)) %>%
    dplyr::mutate(Age_Group = cut(Age, breaks = c(-Inf, 24, 34, 44, 54, 64, Inf),
                                  labels = c("<=24","25-34","35-44","45-54","55-64","65+")))
  message("Converted numeric Age to Age_Group.")
} else {
  df <- df %>% dplyr::mutate(Age_Group = Age)
  message("Using existing Age values as Age_Group labels.")
}

# Put Age_Group as factor in sensible order if those labels are present
common_order <- c("<=24","25-34","35-44","45-54","55-64","65+")
existing_order <- intersect(common_order, unique(df$Age_Group))
if(length(existing_order)) df$Age_Group <- factor(df$Age_Group, levels = c(existing_order, setdiff(unique(df$Age_Group), existing_order)))

message("Unique age groups: ", paste(unique(df$Age_Group), collapse = " | "))
message("Step 4 complete.")

# Step 5: counts table and wide matrix
tab_counts <- df %>%
  dplyr::group_by(Age_Group, Asset) %>%
  dplyr::summarise(Count = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(Age_Group, dplyr::desc(Count))

print(head(tab_counts, 30))

matrix_counts <- tab_counts %>%
  tidyr::pivot_wider(names_from = Asset, values_from = Count, values_fill = 0) %>%
  tibble::column_to_rownames("Age_Group")

# Step 2: Clean and prepare holding period data
holding_col <- "Retention_Days"  # <-- change if your column has a different name

df_holding <- df %>%
  dplyr::select(all_of(holding_col)) %>%
  dplyr::rename(Holding_Period = all_of(holding_col)) %>%
  dplyr::mutate(Holding_Period = as.numeric(Holding_Period)) %>%
  dplyr::filter(!is.na(Holding_Period) & Holding_Period > 0)

summary(df_holding$Holding_Period)
message("Step 2 complete: holding period column ready.")

# Step 3: Plot histogram of holding period
p <- ggplot(df_holding, aes(x = Holding_Period)) +
  geom_histogram(binwidth = 30, fill = "steelblue", color = "white") +
  labs(
    title = "Investment Retention Trends (Holding Period)",
    x = "Holding Period (Days)",
    y = "Number of Investors"
  ) +
  theme_minimal()

print(p)
ggsave("investment_retention_trends_histogram.png", p, width = 9, height = 5, dpi = 300)
message("Saved: investment_retention_trends_histogram.png")

# Always load these first
library(dplyr)
library(readxl)
library(ggplot2)

# Step 2: Prepare data for frequency & volume analysis
investor_col <- "Investor_ID"        # e.g. "Client_ID" or "User_ID"
purchase_col <- "Purchase_Value"     # e.g. "Purchase_Amount"
type_col <- "Investor_Type"          # e.g. "Client_Type" or "Investor Status"

df_purch <- df %>%
  dplyr::select(all_of(c(investor_col, purchase_col, type_col))) %>%
  dplyr::rename(
    Investor = all_of(investor_col),
    Purchase_Value = all_of(purchase_col),
    Type = all_of(type_col)
  ) %>%
  dplyr::mutate(
    Purchase_Value = as.numeric(Purchase_Value),
    Type = as.factor(trimws(Type))
  ) %>%
  dplyr::filter(!is.na(Investor) & !is.na(Purchase_Value) & !is.na(Type))

message("Step 2 complete: data prepared.")

# Step 3: Calculate purchase frequency and volume
df_summary <- df_purch %>%
  dplyr::group_by(Investor, Type) %>%
  dplyr::summarise(
    Purchase_Count = n(),
    Total_Purchase = sum(Purchase_Value, na.rm = TRUE),
    .groups = "drop"
  )

print(head(df_summary))
message("Step 3 complete: summarized frequency and volume per investor.")

# show objects in the environment
ls()

# quick existence checks
exists("df")        # should be TRUE if you loaded the dataset (Step 1)
exists("df_purch")  # should be TRUE if Step 2 ran ok
exists("df_summary")# this should become TRUE after Step 3

# Step 2: Prepare data for frequency & volume analysis

investor_col <- "Investor_ID"        # edit if different
purchase_col <- "Purchase_Value"     # edit if different
type_col     <- "Investor_Type"      # edit if different

df_purch <- df |>
  dplyr::select(all_of(c(investor_col, purchase_col, type_col))) |>
  dplyr::rename(
    Investor = all_of(investor_col),
    Purchase_Value = all_of(purchase_col),
    Type = all_of(type_col)
  ) |>
  dplyr::mutate(
    Purchase_Value = as.numeric(Purchase_Value),
    Type = as.factor(trimws(Type))
  ) |>
  dplyr::filter(!is.na(Investor) & !is.na(Purchase_Value) & !is.na(Type))

message("Step 2 complete — df_purch created. Rows: ", nrow(df_purch))
print(head(df_purch, 10))


# What is df?
print("---- df diagnostics ----")
print(paste("exists(df):", exists("df")))
print(paste("typeof(df):", typeof(df)))
print(paste("class(df):", paste(class(df), collapse = ", ")))
# If df is small, show it (safe to run)
try({ print(head(df, 6)) }, silent = FALSE)


# 1) Re-load the Excel file into df (this will overwrite the function named df)
file_path <- "C:/Users/leonb/OneDrive/Documents/Custom Office Templates/Wealthyhood_investment_metrics_completed alert.xlsx"
sheet <- 1

# make sure readxl is loaded
if(!"readxl" %in% installed.packages()[, "Package"]) install.packages("readxl")
library(readxl)

# read the sheet into df (note the parentheses!)
df <- read_excel(file_path, sheet = sheet)

# quick checks
message("Reloaded df: rows = ", nrow(df), ", cols = ", ncol(df))
print(head(df, 6))
print(paste("typeof(df):", typeof(df)))
print(paste("class(df):", paste(class(df), collapse = ", ")))


# 1) Inspect columns in df
print("---- column names ----")
print(names(df))
print("---- first 6 rows ----")
print(utils::head(df, 6))

# 1) Column configuration (edit only if your column names are different)
investor_col  <- "User_ID"         # from your df
purchase_col  <- "Purchase_Value"  # from your df
# If you actually have an explicit investor type column (e.g. "Investor_Type"), set it here.
# Otherwise leave as NA to derive type from purchase counts.
type_col      <- NA                # e.g. "Investor_Type" or set to NA to derive


# 2) Create df_purch (safe selection + cleaning)
library(dplyr)

# verify the chosen columns exist (fail early with informative message)
missing_cols <- setdiff(c(investor_col, purchase_col), names(df))
if(length(missing_cols)){
  stop("These required columns are missing from df: ", paste(missing_cols, collapse = ", "),
       "\nCheck names(df) and adjust investor_col/purchase_col accordingly.")
}

if(!is.na(type_col) && !(type_col %in% names(df))){
  stop("You set type_col to '", type_col, "' but that column is not in df. Set type_col <- NA or the correct name.")
}

# select & clean
if(is.na(type_col)){
  df_purch <- df |>
    dplyr::select(all_of(c(investor_col, purchase_col))) |>
    dplyr::rename(
      Investor = all_of(investor_col),
      Purchase_Value = all_of(purchase_col)
    ) |>
    dplyr::mutate(
      Purchase_Value = as.numeric(Purchase_Value),
      Investor = as.character(Investor)
    ) |>
    dplyr::filter(!is.na(Investor) & !is.na(Purchase_Value))
} else {
  df_purch <- df |>
    dplyr::select(all_of(c(investor_col, purchase_col, type_col))) |>
    dplyr::rename(
      Investor = all_of(investor_col),
      Purchase_Value = all_of(purchase_col),
      Type = all_of(type_col)
    ) |>
    dplyr::mutate(
      Purchase_Value = as.numeric(Purchase_Value),
      Investor = as.character(Investor),
      Type = as.factor(trimws(as.character(Type)))
    ) |>
    dplyr::filter(!is.na(Investor) & !is.na(Purchase_Value) & !is.na(Type))
}

message("df_purch created — rows: ", nrow(df_purch))
print(head(df_purch, 10))

# 3) Summarize and plot: Purchase_Count, Total_Purchase. Derive Type if missing.
library(ggplot2)

# create summary
df_summary <- df_purch |>
  dplyr::group_by(Investor) |>
  dplyr::summarise(
    Purchase_Count = dplyr::n(),
    Total_Purchase = sum(Purchase_Value, na.rm = TRUE),
    .groups = "drop"
  )

# if df_purch had a Type column originally, join it (take first observed type per investor)
if("Type" %in% names(df_purch)){
  df_types <- df_purch |>
    dplyr::group_by(Investor) |>
    dplyr::summarise(Type = dplyr::first(Type), .groups = "drop")
  df_summary <- dplyr::left_join(df_summary, df_types, by = "Investor")
} else {
  # derive: Purchase_Count ==1 => "New", else "Repeat"
  df_summary <- df_summary |>
    dplyr::mutate(Type = ifelse(Purchase_Count <= 1, "New", "Repeat")) |>
    dplyr::mutate(Type = factor(Type, levels = c("New", "Repeat")))
}

message("df_summary rows: ", nrow(df_summary))
print(head(df_summary, 10))

# scatter plot
p <- ggplot(df_summary, aes(x = Purchase_Count, y = Total_Purchase, color = Type)) +
  geom_jitter(width = 0.2, height = 0, size = 2, alpha = 0.7) +
  scale_x_continuous(breaks = pretty(df_summary$Purchase_Count, n = 10)) +
  labs(
    title = "Purchase Frequency vs Volume (New vs Repeat Investors)",
    x = "Number of Purchases (Frequency)",
    y = "Total Purchase Volume",
    color = "Investor Type"
  ) +
  theme_minimal()

print(p)
ggsave("purchase_frequency_vs_volume_scatter.png", p, width = 9, height = 5, dpi = 300)
message("Saved: purchase_frequency_vs_volume_scatter.png")

print(p)

# Step 1: Load packages
library(dplyr)
library(ggplot2)
library(pheatmap)

# Confirm data frame exists
if(!exists("df")) stop("Data frame 'df' not found. Run Step 1 from previous questions to load your Excel first.")

# Key columns for this question
age_col <- "Age"
repeat_col <- "Repeat_Purchase_Rate_pct"
churn_col <- "Churn_Rate_pct"

# Check if columns exist
missing_cols <- setdiff(c(age_col, repeat_col, churn_col), names(df))
if(length(missing_cols)) stop("These columns are missing in your data: ", paste(missing_cols, collapse = ", "))

message(" Step 1 complete: Columns confirmed and packages loaded.")

# Step 2: Clean and group by age
df_target <- df |>
  dplyr::mutate(
    Age_Group = dplyr::case_when(
      Age <= 24 ~ "<=24",
      Age >= 25 & Age <= 34 ~ "25-34",
      Age >= 35 & Age <= 44 ~ "35-44",
      Age >= 45 & Age <= 54 ~ "45-54",
      Age >= 55 & Age <= 64 ~ "55-64",
      Age >= 65 ~ "65+",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(Age_Group)) |>
  dplyr::group_by(Age_Group) |>
  dplyr::summarise(
    Avg_Repeat_Rate = mean(!!sym(repeat_col), na.rm = TRUE),
    Avg_Churn_Rate  = mean(!!sym(churn_col), na.rm = TRUE),
    .groups = "drop"
  )

print(df_target)
message(" Step 2 complete: Age groups and average rates computed.")

# Step 3: Prepare data matrix for heatmap
df_matrix <- df_target |>
  dplyr::arrange(Age_Group) |>
  as.data.frame()

# Rename rownames
rownames(df_matrix) <- df_matrix$Age_Group
df_matrix <- df_matrix[, c("Avg_Repeat_Rate", "Avg_Churn_Rate")]

# Convert to matrix for pheatmap
mat <- as.matrix(df_matrix)

# Create heatmap
pheatmap(
  mat,
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  number_format = "%.1f",
  main = "Targeting & Retention Insights by Age Group",
  color = colorRampPalette(c("skyblue", "yellow", "tomato"))(50)
)

# Save heatmap as image
pheatmap(
  mat,
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  number_format = "%.1f",
  main = "Targeting & Retention Insights by Age Group",
  filename = "targeting_retention_heatmap.png",
  width = 8, height = 5
)

message(" Step 3 complete: Heatmap saved as targeting_retention_heatmap.png")

# Step 1: Load packages
library(dplyr)
library(ggplot2)

# Confirm df exists
if(!exists("df")) stop("Data frame 'df' not found. Please run previous steps to load the Excel file first.")

# Key columns for this question
user_col  <- "User_ID"
asset_col <- "Asset_Type"

# Check for existence
missing_cols <- setdiff(c(user_col, asset_col), names(df))
if(length(missing_cols)) stop("Missing columns: ", paste(missing_cols, collapse = ", "))

message("Step 1 complete: Columns confirmed and packages loaded.")

# Step 2: Summarize user activity and get top 5
df_user_activity <- df |>
  dplyr::group_by(!!sym(user_col), !!sym(asset_col)) |>
  dplyr::summarise(Transaction_Count = n(), .groups = "drop")

# Identify top 5 most active users overall
top_users <- df_user_activity |>
  dplyr::group_by(!!sym(user_col)) |>
  dplyr::summarise(Total_Transactions = sum(Transaction_Count), .groups = "drop") |>
  dplyr::arrange(desc(Total_Transactions)) |>
  dplyr::slice_head(n = 5)

# Filter only top 5 users
df_top5 <- df_user_activity |>
  dplyr::filter(!!sym(user_col) %in% top_users[[user_col]])

print(top_users)
message(" Step 2 complete: Top 5 users identified.")

# Step 3: Stacked bar chart (Top 5 users by asset type)
p <- ggplot(df_top5, aes(x = !!sym(user_col), y = Transaction_Count, fill = !!sym(asset_col))) +
  geom_bar(stat = "identity") +
  labs(
    title = "Top 5 Users and Breakdown of Assets They Trade",
    x = "User ID",
    y = "Number of Transactions",
    fill = "Asset Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p)

# Save to file
ggsave("top5_users_asset_breakdown.png", p, width = 9, height = 5, dpi = 300)
message(" Step 3 complete: Chart saved as top5_users_asset_breakdown.png")

print(p)

# Step 1: Setup
library(dplyr)
library(ggplot2)

# Confirm df exists
if(!exists("df")) stop("Data frame 'df' not found. Please load it first (from Question 1).")

# Key columns needed
purchase_col <- "Purchase_Value"
sell_col     <- "Sell_Value"
user_col     <- "User_ID"

# Confirm columns exist
missing_cols <- setdiff(c(purchase_col, sell_col, user_col), names(df))
if(length(missing_cols)) stop("Missing columns in dataset: ", paste(missing_cols, collapse = ", "))

message(" Step 1 complete: Columns confirmed and packages loaded.")

# Step 2: Calculate ROI per transaction
df_roi <- df |>
  dplyr::mutate(
    ROI_pct = ((!!sym(sell_col) - !!sym(purchase_col)) / !!sym(purchase_col)) * 100
  ) |>
  dplyr::filter(!is.na(ROI_pct) & is.finite(ROI_pct))

message("Step 2 complete: ROI % calculated for all valid transactions.")
print(head(df_roi[, c(user_col, purchase_col, sell_col, "ROI_pct")], 10))

# Step 3: Summarize ROI and classify Autopilot Vault qualification
df_user_roi <- df_roi |>
  dplyr::group_by(!!sym(user_col)) |>
  dplyr::summarise(
    Avg_ROI = mean(ROI_pct, na.rm = TRUE),
    Transactions = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    Vault_Qualification = ifelse(Avg_ROI >= 5, "Qualified", "Not Qualified")
  )

print(head(df_user_roi, 10))
message(" Step 3 complete: ROI summarized and Vault qualification assigned.")

# Step 4: Boxplot visualization
p <- ggplot(df_user_roi, aes(x = Vault_Qualification, y = Avg_ROI, fill = Vault_Qualification)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red") +
  labs(
    title = "ROI % Distribution by Autopilot Vault Qualification",
    x = "Vault Qualification",
    y = "Average ROI (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "none"
  )

print(p)

# Save chart
ggsave("roi_autopilot_vault_boxplot.png", p, width = 8, height = 5, dpi = 300)
message("Step 4 complete: Boxplot saved as roi_autopilot_vault_boxplot.png")
print(p)

# Step 2: Summarize total investment per asset type
df_assets <- df |>
  dplyr::group_by(!!sym(asset_col)) |>
  dplyr::summarise(
    Total_Investment = sum(!!sym(purchase_col), na.rm = TRUE),
    Transactions = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::arrange(desc(Total_Investment))

# Extract top 5
df_top5_assets <- df_assets |>
  dplyr::slice_head(n = 5)

print(df_top5_assets)
message("Step 2 complete: Top 5 asset types identified.")


# Step 3: Visualize top 5 asset types by total investment
p <- ggplot(df_top5_assets, aes(x = reorder(!!sym(asset_col), Total_Investment), 
                                y = Total_Investment, 
                                fill = !!sym(asset_col))) +
  geom_bar(stat = "identity", width = 0.7) +
  coord_flip() +
  labs(
    title = "Top 5 Asset Types by Total Investment Value",
    x = "Asset Type",
    y = "Total Investment Value",
    fill = "Asset Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.text = element_text(size = 10)
  )

print(p)

# Save the chart
ggsave("top5_asset_types_investment.png", p, width = 8, height = 5, dpi = 300)
message("Step 3 complete: Chart saved as top5_asset_types_investment.png")

# Display image using R's graphics window
library(png)
library(grid)

getwd()

# Save the plot correctly into your working directory
ggsave(
  filename = file.path(getwd(), "monthly_investment_trends.png"),
  plot = p,
  width = 10,
  height = 5,
  dpi = 300
)

message("PNG saved correctly at: ", file.path(getwd(), "monthly_investment_trends.png"))

browseURL(file.path(getwd(), "monthly_investment_trends.png"))


# Step 1: Load packages
library(dplyr)
library(ggplot2)

# Confirm df exists
if(!exists("df")) stop("Data frame 'df' not found.")

# Key columns
asset_col <- "Asset_Type"
retention_col <- "Retention_Days"   # You may switch to "Retention_Months"

# Check columns exist
missing_cols <- setdiff(c(asset_col, retention_col), names(df))
if(length(missing_cols)) stop("Missing columns: ", paste(missing_cols, collapse = ", "))

message("Step 1 complete: Columns confirmed and packages loaded.")

# Step 2: Prepare retention distribution dataset
df_retention <- df |>
  dplyr::select(all_of(c(asset_col, retention_col))) |>
  dplyr::filter(!is.na(!!sym(asset_col)) & !is.na(!!sym(retention_col)))

print(head(df_retention, 10))
message("Step 2 complete: Retention dataset prepared.")

# Step 3: Plot retention distribution by asset type
p <- ggplot(df_retention, aes(x = !!sym(asset_col), y = !!sym(retention_col), fill = !!sym(asset_col))) +
  geom_boxplot(alpha = 0.7, outlier.color = "red") +
  labs(
    title = "Retention Distribution by Asset Type",
    x = "Asset Type",
    y = "Retention (Days)",
    fill = "Asset Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )

print(p)

# Save image
ggsave("retention_distribution_by_asset.png", p, width = 10, height = 5, dpi = 300)
message("Step 3 complete: Chart saved as retention_distribution_by_asset.png")

# Step 2: Compute ROI per transaction
df_roi <- df |>
  dplyr::mutate(
    ROI_pct = ((!!sym(sell_col) - !!sym(purchase_col)) / !!sym(purchase_col)) * 100
  ) |>
  dplyr::filter(!is.na(ROI_pct) & is.finite(ROI_pct))

message("Step 2 complete: ROI % calculated.")
print(head(df_roi[, c(user_col, "ROI_pct")], 10))

# Step 3: Average ROI per user + ranking
df_user_profit <- df_roi |>
  dplyr::group_by(!!sym(user_col)) |>
  dplyr::summarise(
    Avg_ROI = mean(ROI_pct, na.rm = TRUE),
    Transactions = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::arrange(desc(Avg_ROI)) |>
  dplyr::slice_head(n = 10)

print(df_user_profit)
message("Step 3 complete: Top 10 profitable users identified.")

