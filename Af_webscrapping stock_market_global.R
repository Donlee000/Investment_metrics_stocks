# --- Step 1: Load required packages ---
library(rvest)
library(dplyr)
library(readr)
library(stringr)

# --- Step 2: Define your local HTML file path ---
html_file <- "C:/Users/leonb/OneDrive/Documents/Stock Screener_ Search and Filter Stocks — TradingView.html"

# --- Step 3: Read the HTML content ---
page <- read_html(html_file)

# --- Step 4: Extract table rows ---
# Find all rows (each stock entry)
rows <- page %>% html_elements("tr")

# --- Step 5: Extract column headers (like Symbol, Price, Change %, etc.) ---
headers <- page %>%
  html_elements("thead tr th") %>%
  html_text(trim = TRUE)

# --- Step 6: Extract the table data cells ---
data <- rows %>%
  html_elements("td") %>%
  html_text(trim = TRUE)

# --- Step 7: Split data into a data frame ---
# Find how many columns are in each row
num_cols <- length(headers)
num_rows <- length(data) / num_cols

# Create data frame
df <- data.frame(matrix(data, ncol = num_cols, byrow = TRUE), stringsAsFactors = FALSE)

# Assign column names
colnames(df) <- headers

# --- Step 8: Clean the data ---
df <- df %>%
  mutate(across(everything(), ~str_replace_all(.x, "\\s+", " "))) %>% # remove excessive spaces
  mutate(across(where(is.character), trimws))                        # trim spaces

# --- Step 9: Preview data ---
print(head(df, 10))

# --- Step 10: Export to CSV ---
output_path <- "C:/Users/leonb/OneDrive/Documents/tradingview_screener_data.csv"
write_csv(df, output_path)

cat("✅ Data successfully extracted and saved to:\n", output_path, "\n")


# show current working directory
getwd()

# show the path you used
html_file

file.exists(html_file)
# more detail (size, mod time)
file.info(html_file)

html_file <- file.choose()
"C:/Users/leonb/OneDrive/Documents/Stock Screener_ Search and Filter Stocks — TradingView.html"

file.exists(html_file)

library(rvest)
page <- read_html(html_file)
length(html_elements(page, "tr"))

install.packages("rvest")

library(rvest)
length(html_elements(page, "tr"))

.rs.restartR()

library(rvest)
packageVersion("rvest")    # confirm you have >= "1.0.0"

library(rvest)
library(dplyr)
library(readr)
library(stringr)

# Define your HTML file path (forward slashes)
html_file <- "C:/Users/leonb/OneDrive/Documents/Stock Screener_ Search and Filter Stocks — TradingView.html"

# Check that the file exists
file.exists(html_file)

# Read the HTML page
page <- read_html(html_file)

# Test: count table rows
length(html_elements(page, "tr"))


# Extract headers
headers <- page %>%
  html_elements("thead tr th") %>%
  html_text(trim = TRUE)

# Extract all table rows (each stock)
rows <- page %>% html_elements("tbody tr")

# Extract cell values row by row
data <- lapply(rows, function(row) {
  row %>% html_elements("td") %>% html_text(trim = TRUE)
})

# Convert to data frame
df <- data.frame(do.call(rbind, data), stringsAsFactors = FALSE)

# If header count matches column count, assign them
if (length(headers) == ncol(df)) {
  colnames(df) <- headers
}

# Clean spaces
df <- df %>% mutate(across(everything(), ~str_squish(.)))

# Preview first few rows
print(head(df, 10))

# Save to CSV
output_path <- "C:/Users/leonb/OneDrive/Documents/tradingview_screener_data.csv"
write_csv(df, output_path)

cat("✅ Data successfully extracted and saved to:\n", output_path, "\n")
