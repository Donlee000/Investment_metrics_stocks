## Investment_metrics_stocks

### Project Overview
This project analyzes Wealthyhood’s user investment activities and financial performance data. It explores key patterns across asset classes, user age groups, retention rates, repeat purchases, and ROI performance.

---
<img width="1536" height="1024" alt="ChatGPT Image Oct 12, 2025, 08_50_41 PM" src="https://github.com/user-attachments/assets/5dc06428-152f-412f-a797-f72c5b1151ff" />


### Data Cleaning & Preparation
The raw dataset from Wealthyhood contained user investment metrics in varying formats. To ensure consistency and reliability for analysis, the following steps were performed:

1.Standardized column names – Unified field names (e.g., “Purchase_Value” and “Sell_Value”) for consistency across all records.
2.Handled missing values – Reviewed and treated null entries in key columns such as User_ID, Age, and transaction details.
3.Date formatting – Converted Purchase_Date and Sell_Date into SQL-friendly formats (YYYY-MM-DD) for accurate retention calculations.
4.Data type correction – Ensured numeric fields like Purchase_Value, Sell_Value, and ROI_pct were correctly cast as decimals.
5.Derived metrics – Created calculated columns including Retention_Days, Retention_Months, and ROI_pct to support deeper investment analysis.


### Results/Findings

The analysis results are summarized as follows:

Age Group Investment Trends – Users aged 25–34 were the most active investors, particularly in stocks and ETFs, while younger users (<25) showed higher interest in crypto assets. Older groups (40+) tended to invest smaller amounts but demonstrated more consistent returns.

Top Performing Asset Classes – Stocks and ETFs accounted for the majority of total investment value, with stocks showing the highest average ROI. Crypto investments had high volatility and shorter holding periods.

Investment Retention (Holding Periods) – The average holding period across all users was 3–5 months, with ETFs and bonds retained the longest. Short-term investors tended to sell within 30–60 days, particularly in high-risk asset types.

Purchase Frequency & Investor Behavior – A subset of users (roughly the top 10%) accounted for a large share of total transactions. Repeat purchase rates were higher among ETF and stock investors, while crypto investors showed higher churn.

ROI & Autopilot Vault Qualification – Approximately 27–30% of users achieved an ROI above 30%, meeting the threshold for Autopilot Vault qualification. These users primarily invested in diversified portfolios with consistent reinvestment patterns.

Retention & Marketing Insights – Younger investors displayed high engagement but low retention, indicating potential for improved long-term investment education. Middle-aged users showed steady growth and loyalty, making them key targets for Wealthyhood’s retention and premium service strategies.

### Recommendations

Targeted Marketing by Age Group – Focus marketing and product recommendations toward the 25–34 age segment, the most active investors, while designing tailored onboarding experiences and education campaigns for younger (<25) users to improve retention.

Diversification Incentives – Encourage users to build balanced portfolios by introducing small incentives (e.g., reduced fees or bonus points) for investing across multiple asset classes such as ETFs and bonds, which show higher retention.

Enhanced Retention Strategies – Develop engagement tools such as personalized dashboards showing ROI growth and holding period milestones to motivate users to stay invested longer.

Autopilot Vault Promotion – Highlight success stories and automate qualification tracking for users achieving ROI above 30%, motivating broader adoption of the Autopilot Vault feature.

Data-Driven Product Optimization – Continue to monitor investment patterns through automated SQL reporting and dashboards, enabling the Wealthyhood team to make evidence-based adjustments to marketing, product features, and customer segmentation


😃😸🪗🧮💻😃😸🪗🧮💻
