## Investment_metrics_stocks

### Project Overview
This project analyzes Wealthyhood’s user investment activities and financial performance data. It explores key patterns across asset classes, user age groups, retention rates, repeat purchases, and ROI performance.

---
<img width="1536" height="1024" alt="ChatGPT Image Oct 12, 2025, 08_50_41 PM" src="https://github.com/user-attachments/assets/5dc06428-152f-412f-a797-f72c5b1151ff" />


### Data Source
Investment metrics, was derived from Wealthyhood’s internal analytics data and contains anonymized information on user investment activities. It includes details such as user age, asset types (stocks, ETFs, crypto, forex, etc.), transaction amounts, purchase and sell dates, holding durations, repeat purchase rates, churn rates, and ROI percentages.

- Excel - Data Cleanning [Download here](https://github.com/user-attachments/files/22989892/Wealthyhood_investment_metrics_completed.xlsx) 
- SQL Server - Data Analysis [Download here](https://1drv.ms/u/c/29f0e449ed577bcc/EQH8XLbkTghGqqVVzJRO8ngBkxJEQyl08qA6EV-m9it1-g?e=vUjspX)
- Power BI - Creating Reports [Download here]()

### Data Cleaning & Preparation
The raw dataset from Wealthyhood contained user investment metrics in varying formats. To ensure consistency and reliability for analysis, the following steps were performed:

1.Standardized column names – Unified field names (e.g., “Purchase_Value” and “Sell_Value”) for consistency across all records.
2.Handled missing values – Reviewed and treated null entries in key columns such as User_ID, Age, and transaction details.
3.Date formatting – Converted Purchase_Date and Sell_Date into SQL-friendly formats (YYYY-MM-DD) for accurate retention calculations.
4.Data type correction – Ensured numeric fields like Purchase_Value, Sell_Value, and ROI_pct were correctly cast as decimals.
5.Derived metrics – Created calculated columns including Retention_Days, Retention_Months, and ROI_pct to support deeper investment analysis.

### Data Analysis

My analysis code/features i worked with:

1. Age groups investing in asset classes
```sql

  SELECT 
    CASE 
        WHEN Age < 20 THEN 'Below 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS Age_Group,
    Asset_Type,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Invested,
    SUM(ISNULL(Sell_Value,0)) AS Total_Returned
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Age IS NOT NULL
GROUP BY 
    CASE 
        WHEN Age < 20 THEN 'Below 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END,
    Asset_Type
ORDER BY Age_Group, Total_Invested DESC;
```

2. Investment retention trends (holding period)
```sql

SELECT

    Asset_Type,
    AVG(Retention_Days) AS Avg_Holding_Days,
    MIN(Retention_Days) AS Min_Holding_Days,
    MAX(Retention_Days) AS Max_Holding_Days
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Retention_Days IS NOT NULL
GROUP BY Asset_Type
ORDER BY Avg_Holding_Days DESC;
```

3. Purchase frequency & volume (new vs repeat investors)
```sql

SELECT 
    User_ID,
    COUNT(TransactionID) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Purchase_Value,
    CASE 
        WHEN COUNT(TransactionID) = 1 THEN 'New Investor'
        ELSE 'Repeat Investor'
    END AS Investor_Type
FROM [Footyballer].[dbo].[Investment_metrics]
GROUP BY User_ID
ORDER BY Total_Transactions DESC;
```

4. Insights for targeting & retention
```sql

SELECT 
    Asset_Type,
    AVG(Repeat_Purchase_Rate_pct) AS Avg_Repeat_Purchase_Rate,
    AVG(Churn_Rate_pct) AS Avg_Churn_Rate,
    COUNT(DISTINCT User_ID) AS Unique_Users
FROM [Footyballer].[dbo].[Investment_metrics]
GROUP BY Asset_Type
ORDER BY Avg_Repeat_Purchase_Rate DESC;
```

5. Show top 5 users and breakdown of assets they trade
```sql

SELECT TOP (5) WITH TIES
    User_ID,
    Age,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Purchase_Value
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE User_ID IS NOT NULL
  AND LTRIM(RTRIM(User_ID)) <> ''
GROUP BY User_ID, Age
ORDER BY COUNT(*) DESC, SUM(Purchase_Value) DESC;
```

6. ROI % and Autopilot Vault qualification
```sql

SELECT 
    User_ID,
    Asset_Type,
    SUM(Sell_Value - Purchase_Value) * 100.0 / NULLIF(SUM(Purchase_Value),0) AS ROI_Percent,
    CASE 
        WHEN SUM(Sell_Value - Purchase_Value) * 100.0 / NULLIF(SUM(Purchase_Value),0) > 30 
        THEN 'Qualified' 
        ELSE 'Not Qualified' 
    END AS AutopilotVault_Status
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Sell_Value IS NOT NULL
GROUP BY User_ID, Asset_Type
ORDER BY ROI_Percent DESC;
```

7. Top 5 Asset Types by Total Investment Value
```sql

SELECT TOP 5
    Asset_Type,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Invested,
    AVG(Purchase_Value) AS Avg_Investment_Per_Transaction
FROM [Footyballer].[dbo].[Investment_metrics]
GROUP BY Asset_Type
ORDER BY Total_Invested DESC;
```

8. Monthly Investment Trends (by Year/Month)
```sql

SELECT 
    YEAR(Purchase_Date) AS Year,
    MONTH(Purchase_Date) AS Month,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Invested
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Purchase_Date IS NOT NULL
GROUP BY YEAR(Purchase_Date), MONTH(Purchase_Date)
ORDER BY Year, Month;
```
9. Retention Distribution by Asset Type
```sql

SELECT 
    Asset_Type,
    AVG(Retention_Days) AS Avg_Retention_Days,
    MAX(Retention_Days) AS Max_Retention_Days,
    MIN(Retention_Days) AS Min_Retention_Days
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Retention_Days IS NOT NULL
GROUP BY Asset_Type
ORDER BY Avg_Retention_Days DESC;
```

10. User Profitability Ranking (Top 10 by ROI)
```sql

SELECT TOP 10
    User_ID,
    SUM(Sell_Value - Purchase_Value) * 100.0 / NULLIF(SUM(Purchase_Value), 0) AS ROI_Percent,
    SUM(Purchase_Value) AS Total_Invested,
    SUM(Sell_Value) AS Total_Returned
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Sell_Value IS NOT NULL
GROUP BY User_ID
ORDER BY ROI_Percent DESC;
```

11. Repeat vs. Churn Analysis by Age Group
```sql

SELECT 
    CASE 
        WHEN Age < 20 THEN 'Below 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS Age_Group,
    AVG(Repeat_Purchase_Rate_pct) AS Avg_Repeat_Purchase_Rate,
    AVG(Churn_Rate_pct) AS Avg_Churn_Rate,
    COUNT(DISTINCT User_ID) AS Users_In_Group
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Age IS NOT NULL
GROUP BY 
    CASE 
        WHEN Age < 20 THEN 'Below 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END
ORDER BY Avg_Repeat_Purchase_Rate DESC;
```

### Results/Findings
<img width="1536" height="1024" alt="Investment reporting Image" src="https://github.com/user-attachments/assets/348828ba-c2b9-44a3-a483-8ad495b466e4" />

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


