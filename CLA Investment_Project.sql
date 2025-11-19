SELECT TOP (1000) [User_ID]
      ,[Age]
      ,[TransactionID]
      ,[Asset_Type]
      ,[Asset_Name]
      ,[Purchase_Value]
      ,[Sell_Value]
      ,[Purchase_Date]
      ,[Sell_Date]
      ,[Retention_Days]
      ,[Retention_Months]
      ,[Repeat_Purchase_Rate_pct]
      ,[Churn_Rate_pct]
  FROM [Footyballer].[dbo].[Investment_metrics]

  --- Age groups investing in asset classes
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

--- Investment retention trends (holding period)

SELECT 
    Asset_Type,
    AVG(Retention_Days) AS Avg_Holding_Days,
    MIN(Retention_Days) AS Min_Holding_Days,
    MAX(Retention_Days) AS Max_Holding_Days
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Retention_Days IS NOT NULL
GROUP BY Asset_Type
ORDER BY Avg_Holding_Days DESC;

--- Purchase frequency & volume (new vs repeat investors)
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

--- Insights for targeting & retention
SELECT 
    Asset_Type,
    AVG(Repeat_Purchase_Rate_pct) AS Avg_Repeat_Purchase_Rate,
    AVG(Churn_Rate_pct) AS Avg_Churn_Rate,
    COUNT(DISTINCT User_ID) AS Unique_Users
FROM [Footyballer].[dbo].[Investment_metrics]
GROUP BY Asset_Type
ORDER BY Avg_Repeat_Purchase_Rate DESC;

-- Show top 5 users and breakdown of assets they trade

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

-- ROI % and Autopilot Vault qualification
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

-- Top 5 Asset Types by Total Investment Value

SELECT TOP 5
    Asset_Type,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Invested,
    AVG(Purchase_Value) AS Avg_Investment_Per_Transaction
FROM [Footyballer].[dbo].[Investment_metrics]
GROUP BY Asset_Type
ORDER BY Total_Invested DESC;

-- Monthly Investment Trends (by Year/Month)
SELECT 
    YEAR(Purchase_Date) AS Year,
    MONTH(Purchase_Date) AS Month,
    COUNT(*) AS Total_Transactions,
    SUM(Purchase_Value) AS Total_Invested
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Purchase_Date IS NOT NULL
GROUP BY YEAR(Purchase_Date), MONTH(Purchase_Date)
ORDER BY Year, Month;

-- Retention Distribution by Asset Type
SELECT 
    Asset_Type,
    AVG(Retention_Days) AS Avg_Retention_Days,
    MAX(Retention_Days) AS Max_Retention_Days,
    MIN(Retention_Days) AS Min_Retention_Days
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Retention_Days IS NOT NULL
GROUP BY Asset_Type
ORDER BY Avg_Retention_Days DESC;


-- User Profitability Ranking (Top 10 by ROI)
SELECT TOP 10
    User_ID,
    SUM(Sell_Value - Purchase_Value) * 100.0 / NULLIF(SUM(Purchase_Value), 0) AS ROI_Percent,
    SUM(Purchase_Value) AS Total_Invested,
    SUM(Sell_Value) AS Total_Returned
FROM [Footyballer].[dbo].[Investment_metrics]
WHERE Sell_Value IS NOT NULL
GROUP BY User_ID
ORDER BY ROI_Percent DESC;

-- Repeat vs. Churn Analysis by Age Group
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

-- Average time between purchases for repeat investors

;WITH purchases AS (
  SELECT
    User_ID,
    Purchase_Date,
    ROW_NUMBER() OVER (PARTITION BY User_ID ORDER BY Purchase_Date) AS rn
  FROM dbo.Investment_metrics
  WHERE Purchase_Date IS NOT NULL
),
pairs AS (
  SELECT
    cur.User_ID,
    cur.Purchase_Date AS cur_dt,
    prev.Purchase_Date AS prev_dt,
    DATEDIFF(day, prev.Purchase_Date, cur.Purchase_Date) AS days_since_prev
  FROM purchases cur
  INNER JOIN purchases prev
    ON cur.User_ID = prev.User_ID AND cur.rn = prev.rn + 1
  WHERE prev.Purchase_Date IS NOT NULL
),
per_user_avg AS (
  SELECT
    User_ID,
    AVG(CAST(days_since_prev AS FLOAT)) AS avg_days_between,
    COUNT(*) AS intervals
  FROM pairs
  GROUP BY User_ID
  HAVING COUNT(*) >= 1
)
-- overall summary
SELECT 
  'overall' AS metric,
  COUNT(*) AS repeat_user_count,
  ROUND(AVG(avg_days_between),2) AS overall_avg_days_between
FROM per_user_avg;

-- Asset_Name with highest average ROI (and weighted ROI)

DECLARE @MinTxForAssetName INT = 10;

SELECT TOP(50)
  Asset_Name,
  COUNT(*) AS tx_count,
  ROUND(AVG(CASE WHEN Purchase_Value > 0 THEN (Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0) END),4) AS avg_roi_pct,
  ROUND(
      CASE WHEN SUM(Purchase_Value) = 0 THEN NULL
           ELSE SUM(((Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0)) * Purchase_Value) / SUM(Purchase_Value)
      END, 4
  ) AS weighted_roi_pct
FROM dbo.Investment_metrics
WHERE Purchase_Value IS NOT NULL AND Purchase_Value > 0 AND Sell_Value IS NOT NULL
GROUP BY Asset_Name
HAVING COUNT(*) >= @MinTxForAssetName
ORDER BY weighted_roi_pct DESC;

-- Do investment patterns differ on weekdays vs weekends?

-- Weekday vs Weekend

SELECT
  CASE WHEN DATEPART(weekday, Purchase_Date) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS Period,
  COUNT(*) AS transactions,
  SUM(Purchase_Value) AS total_invested,
  ROUND(AVG(Purchase_Value),2) AS avg_ticket_size
FROM dbo.Investment_metrics
WHERE Purchase_Date IS NOT NULL
GROUP BY CASE WHEN DATEPART(weekday, Purchase_Date) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END
ORDER BY total_invested DESC;

-- Day-of-week breakdown (Mon..Sun)
SELECT
  DATEPART(weekday, Purchase_Date) AS weekday_num,
  DATENAME(weekday, Purchase_Date) AS weekday_name,
  COUNT(*) AS transactions,
  SUM(Purchase_Value) AS total_invested,
  ROUND(AVG(Purchase_Value),2) AS avg_ticket_size
FROM dbo.Investment_metrics
WHERE Purchase_Date IS NOT NULL
GROUP BY DATEPART(weekday, Purchase_Date), DATENAME(weekday, Purchase_Date)
ORDER BY weekday_num;

-- Distribution of investment sizes (buckets) and outcomes (avg ROI)

SELECT
  size_bucket,
  COUNT(*) AS tx_count,
  SUM(Purchase_Value) AS total_invested,
  ROUND(AVG(CASE WHEN Purchase_Value > 0 THEN (Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0) END),4) AS avg_roi_pct
FROM (
  SELECT *,
    CASE 
      WHEN Purchase_Value <= 100 THEN '<=100'
      WHEN Purchase_Value <= 500 THEN '101-500'
      WHEN Purchase_Value <= 1000 THEN '501-1k'
      WHEN Purchase_Value <= 5000 THEN '1k-5k'
      WHEN Purchase_Value <= 10000 THEN '5k-10k'
      ELSE '>10k'
    END AS size_bucket
  FROM dbo.Investment_metrics
  WHERE Purchase_Value IS NOT NULL
) t
GROUP BY size_bucket
ORDER BY 
 CASE size_bucket WHEN '<=100' THEN 1 WHEN '101-500' THEN 2 WHEN '501-1k' THEN 3 WHEN '1k-5k' THEN 4 WHEN '5k-10k' THEN 5 ELSE 6 END;

 -- Correlation between Retention_Months and ROI (Pearson r)

 ;WITH t AS (
  SELECT
    CAST(Retention_Months AS FLOAT) AS x,
    CASE WHEN Purchase_Value > 0 AND Sell_Value IS NOT NULL THEN ((Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0)) ELSE NULL END AS y
  FROM dbo.Investment_metrics
  WHERE Retention_Months IS NOT NULL
)
SELECT
  COUNT(*) AS n_obs,
  ROUND(
    ( (SUM(x*y) - SUM(x)*SUM(y)/COUNT(*))
      /
      (SQRT(SUM(x*x) - SUM(x)*SUM(x)/COUNT(*)) * SQRT(SUM(y*y) - SUM(y)*SUM(y)/COUNT(*)))
    ), 6) AS pearson_r
FROM t
WHERE x IS NOT NULL AND y IS NOT NULL;


-- Q17: Cohort retention table (0..6 months) - corrected version
-- Make sure to run the entire block at once in SSMS.

;WITH first_purchase AS (
    -- for each user find their first purchase date and cohort month (1st day of that month)
    SELECT
      User_ID,
      MIN(Purchase_Date) AS first_purchase_date,
      DATEFROMPARTS(YEAR(MIN(Purchase_Date)), MONTH(MIN(Purchase_Date)), 1) AS cohort_month
    FROM dbo.Investment_metrics
    WHERE Purchase_Date IS NOT NULL
    GROUP BY User_ID
),
activity AS (
    -- map every purchase to the user's cohort and compute month offset from cohort
    SELECT
      i.User_ID,
      fp.cohort_month,
      DATEFROMPARTS(YEAR(i.Purchase_Date), MONTH(i.Purchase_Date), 1) AS activity_month,
      DATEDIFF(month, fp.first_purchase_date, i.Purchase_Date) AS month_offset
    FROM dbo.Investment_metrics i
    INNER JOIN first_purchase fp
      ON i.User_ID = fp.User_ID
    WHERE i.Purchase_Date IS NOT NULL
),
cohort_sizes AS (
    -- cohort size = number of distinct users in each cohort
    SELECT
      cohort_month,
      COUNT(DISTINCT User_ID) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
cohort_activity AS (
    -- active users per cohort per month_offset (restrict 0..6 here)
    SELECT
      cohort_month,
      month_offset,
      COUNT(DISTINCT User_ID) AS active_users
    FROM activity
    WHERE month_offset BETWEEN 0 AND 6
    GROUP BY cohort_month, month_offset
)
-- final: join sizes to activity and compute retention %
SELECT
  ca.cohort_month,
  ca.month_offset,
  cs.cohort_size,
  ca.active_users,
  ROUND(100.0 * ca.active_users / NULLIF(cs.cohort_size, 0), 2) AS retention_pct
FROM cohort_activity ca
JOIN cohort_sizes cs
  ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.month_offset;

-- Q18 (fixed): VIP candidates = top 10% by lifetime investment AND weighted ROI >= 5%
-- No external variables required; runs as a single batch.

;WITH user_stats AS (
  SELECT
    User_ID,
    SUM(COALESCE(Purchase_Value,0)) AS lifetime_investment,
    -- sum of (roi_percent * purchase_amt) where roi_percent = (Sell - Purchase) / Purchase * 100
    SUM(
      CASE 
        WHEN Purchase_Value > 0 AND Sell_Value IS NOT NULL 
        THEN ((Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0)) * Purchase_Value
        ELSE 0
      END
    ) AS roi_times_amt,
    SUM(CASE WHEN Purchase_Value IS NOT NULL THEN Purchase_Value ELSE 0 END) AS total_amt
  FROM dbo.Investment_metrics
  GROUP BY User_ID
),
user_rois AS (
  SELECT
    User_ID,
    lifetime_investment,
    CASE WHEN total_amt > 0 THEN roi_times_amt / total_amt ELSE NULL END AS weighted_roi_pct
  FROM user_stats
),
user_ranked AS (
  -- NTILE(100) gives percentile buckets; ordering DESC places highest lifetime_investment into lowest NTILE numbers (1..100).
  SELECT
    ur.*,
    NTILE(100) OVER (ORDER BY lifetime_investment DESC) AS pct_tile -- 1 = top 1%, 10 = top 10% roughly
  FROM user_rois ur
)
SELECT
  User_ID,
  lifetime_investment,
  ROUND(weighted_roi_pct,4) AS weighted_roi_pct,
  pct_tile
FROM user_ranked
WHERE pct_tile <= 10           -- top 10%
  AND weighted_roi_pct IS NOT NULL
  AND weighted_roi_pct >= 5.0  -- VIP ROI threshold (change inline if you want another cutoff)
ORDER BY lifetime_investment DESC;

-- Q20 (final robust): Time-to-first-profit (days)

SET NOCOUNT ON;

-- drop temp if present
IF OBJECT_ID('tempdb..#joined_profit') IS NOT NULL
  DROP TABLE #joined_profit;

-- create temp table with per-user first purchase and first profit dates + days difference
SELECT
  u.User_ID,
  u.first_purchase_date,
  p.first_profit_date,
  DATEDIFF(day, u.first_purchase_date, p.first_profit_date) AS days_to_first_profit
INTO #joined_profit
FROM
  (
    -- first purchase per user
    SELECT User_ID, MIN(Purchase_Date) AS first_purchase_date
    FROM dbo.Investment_metrics
    WHERE Purchase_Date IS NOT NULL
    GROUP BY User_ID
  ) AS u
LEFT JOIN
  (
    -- first sell date where that trade had positive ROI
    SELECT User_ID, MIN(Sell_Date) AS first_profit_date
    FROM
      (
        SELECT
          User_ID,
          Sell_Date,
          CASE 
            WHEN Purchase_Value > 0 AND Sell_Value IS NOT NULL
            THEN ((Sell_Value - Purchase_Value) * 100.0 / NULLIF(Purchase_Value,0))
            ELSE NULL
          END AS ROI_pct
        FROM dbo.Investment_metrics
      ) AS trade_rois
    WHERE ROI_pct > 0 AND Sell_Date IS NOT NULL
    GROUP BY User_ID
  ) AS p
  ON u.User_ID = p.User_ID
WHERE u.first_purchase_date IS NOT NULL
;  -- end of INTO #joined_profit

-- 1) Per-user listing
SELECT User_ID, first_purchase_date, first_profit_date, days_to_first_profit
FROM #joined_profit
ORDER BY days_to_first_profit ASC;

-- 2) Summary aggregates (only for users who have a non-null days_to_first_profit)
SELECT
  COUNT(*) AS users_with_first_buy,
  SUM(CASE WHEN days_to_first_profit IS NOT NULL THEN 1 ELSE 0 END) AS users_with_first_profit,
  MIN(days_to_first_profit) AS min_days_to_first_profit,
  ROUND(AVG(CAST(days_to_first_profit AS FLOAT)),2) AS avg_days_to_first_profit,
  MAX(days_to_first_profit) AS max_days_to_first_profit
FROM #joined_profit
WHERE days_to_first_profit IS NOT NULL;

-- 3) Median (robust fallback using row numbers)
;WITH numbered AS (
  SELECT
    days_to_first_profit,
    ROW_NUMBER() OVER (ORDER BY days_to_first_profit) AS rn,
    COUNT(*) OVER () AS total_n
  FROM #joined_profit
  WHERE days_to_first_profit IS NOT NULL
)
SELECT
  AVG(CAST(days_to_first_profit AS FLOAT)) AS median_days_to_first_profit
FROM numbered
WHERE rn IN ((total_n+1)/2, (total_n+2)/2);

-- cleanup (optional)
-- DROP TABLE #joined_profit;

SET NOCOUNT OFF;


