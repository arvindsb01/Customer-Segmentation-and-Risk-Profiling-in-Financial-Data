	SELECT *
	FROM card_data;

	SELECT *
	FROM errors;

	SELECT *
	FROM mcc;

	SELECT *
	FROM transaction_data;

	SELECT *
	FROM user_data;

	---Performing Exploratory Data Analysis---
	------------------------------------------

	--Card_data--
	-------------
	SELECT *
	FROM card_data
	WHERE card_id IS NULL 
	   OR user_id IS NULL 
	   OR card_brand IS NULL 
	   OR card_type IS NULL 
	   OR card_expiry IS NULL 
	   OR has_chip IS NULL 
	   OR num_cards_issued IS NULL 
	   OR credit_limit IS NULL 
	   OR acct_open_date IS NULL 
	   OR year_pin_last_changed IS NULL 
	   OR card_on_dark_web IS NULL;

	--errors--
	----------
	SELECT *
	FROM errors
	WHERE error_id IS NULL OR description IS NULL;

	 --mcc--
	----------
	SELECT *
	FROM mcc
	WHERE mcc_code IS NULL
	OR description IS NULL;
	
	--transaction_data--
	--------------------
	SELECT *
	FROM transaction_data
	WHERE transaction_id IS NULL 
    OR user_id IS NULL 
    OR card_id IS NULL 
    OR amount IS NULL 
    OR use_chip IS NULL 
    OR merchant_id IS NULL 
    OR merchant_city IS NULL 
    OR zip IS NULL 
    OR mcc_code IS NULL;

	--user_data--
	-------------
	SELECT *
	FROM user_data
	WHERE user_id IS NULL 
    OR current_age IS NULL 
    OR retirement_age IS NULL 
    OR birth_year IS NULL 
    OR birth_month IS NULL 
    OR gender IS NULL 
    OR address IS NULL 
    OR per_capita_income IS NULL 
    OR yearly_income IS NULL 
    OR total_debt IS NULL 
    OR credit_score IS NULL 
    OR num_credit_cards IS NULL;

	--Monthly Average Spending by gender--
	----------------------
	SELECT 
    TO_CHAR(DATE_TRUNC('month', t.transaction_date), 'YYYY-MM') AS transaction_month,
    u.gender,
	ROUND(AVG(t.amount), 2) AS avg_spent
	FROM 
		transaction_data t
	JOIN 
		user_data u
	ON 
		u.user_id = t.user_id
	WHERE 
		t.transaction_date >= '2019-02-01' -- Filters for transactions after January 2019
	GROUP BY 
		u.gender, transaction_month
	ORDER BY 
		transaction_month ASC;

	
	--Summary Statistics--
	----------------------
	SELECT 
    MAX(credit_limit) AS max_limit,
    MIN(credit_limit) AS min_limit,
    ROUND(AVG(credit_limit), 2) AS average_limit,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY credit_limit) AS median_limit, 
    COUNT(DISTINCT credit_limit) AS mode_limit
	FROM card_data;
	
	--Cards with chip by year--
-- Cards with chip by year --
	SELECT 
		c.has_chip, 
		COUNT(c.has_chip) AS count, 
		EXTRACT(YEAR FROM t.transaction_date) AS year
	FROM 
		card_data c
	JOIN 
		transaction_data t
	ON 
		t.card_id = c.card_id -- Correct join condition on card_id instead of user_id
	GROUP BY 
		c.has_chip, EXTRACT(YEAR FROM t.transaction_date)
	ORDER BY 
		year, c.has_chip;

	
	--Most used card--
	SELECT card_type, count(card_type) as count
	FROM card_data
	GROUP BY card_type;
	
	--Most Common Error in a transaction--
	SELECT e.description, COUNT(t.error_id) as count
	FROM transaction_data t
	JOIN errors e ON e.error_id = t.error_id
	GROUP by e.description
	ORDER BY count DESC 
	LIMIT 3;
	
	--credit_score by gender--
	SELECT gender, ROUND(AVG(yearly_income),0) as avg_income, ROUND(AVG(credit_score),0)
	FROM user_data
	GROUP BY gender;
	
	--Outlier Detection--
	---------------------
	WITH stats AS (
    SELECT 
        AVG(credit_limit) AS mean_credit_limit,
        STDDEV(credit_limit) AS stddev_credit_limit
    FROM card_data
		)
	SELECT *
	FROM (SELECT user_id,
        credit_limit,
        ROUND((credit_limit - stats.mean_credit_limit) / stats.stddev_credit_limit, 2) AS z_score,
        CASE
        WHEN ABS((credit_limit - stats.mean_credit_limit) / stats.stddev_credit_limit) <= 1 THEN 'Within 1 SD'
        WHEN ABS((credit_limit - stats.mean_credit_limit) / stats.stddev_credit_limit) <= 2 THEN 'Within 2 SD'
        WHEN ABS((credit_limit - stats.mean_credit_limit) / stats.stddev_credit_limit) <= 3 THEN 'Within 3 SD'
        ELSE 'Outlier'
        END AS sd_classification
    FROM card_data, stats
	) subquery
	WHERE sd_classification = 'Outlier';

	--Card usage history past 5 years--
	-----------------------------------
	SELECT DATE_TRUNC('month', transaction_date) AS transaction_month,
       COUNT(DISTINCT card_id) AS usage
	FROM transaction_data
	WHERE transaction_date >= '2019-01-01'
	GROUP BY transaction_month
	ORDER BY transaction_month;
--------------------------------------------------------------------------------------	
		---Customer Segmentation---
--------------------------------------------------------------------------------------
	--RFM Segmentation(Recency, Frequency, Monetary)
	------------------------------------------------	
	WITH rfm AS (
    SELECT 
        user_id, 
        MAX(transaction_date) AS last_transaction,
        COUNT(user_id) AS transaction_count, 
        SUM(amount) AS total_spent
    FROM transaction_data
    GROUP BY user_id
)
SELECT 
    r.user_id, 
    u.gender, 
    u.yearly_income AS income, 
    u.current_age AS age,
    NTILE(4) OVER(PARTITION BY u.gender ORDER BY r.last_transaction DESC) AS recency_score,
    NTILE(4) OVER(PARTITION BY u.gender ORDER BY r.transaction_count DESC) AS frequency_score,
    NTILE(4) OVER(PARTITION BY u.gender ORDER BY r.total_spent DESC) AS monetary_score
FROM 
    rfm r
JOIN 
    user_data u ON r.user_id = u.user_id
ORDER BY 
    u.gender, r.user_id;

	
	--Demographic Segmentation--
	----------------------------
		WITH segmentation AS (
		SELECT
			CASE
				WHEN current_age < 30 THEN 'Young'
				WHEN current_age BETWEEN 30 AND 50 THEN 'Middle-Aged'
				ELSE 'Senior'
			END AS age_group,
			CASE
				WHEN yearly_income < 50000 THEN 'Low Income'
				WHEN yearly_income BETWEEN 50000 AND 100000 THEN 'Middle Income'
				ELSE 'High Income'
			END AS income_group,
			COUNT(user_id) AS user_count
		FROM user_data
		GROUP BY 
			CASE
				WHEN current_age < 30 THEN 'Young'
				WHEN current_age BETWEEN 30 AND 50 THEN 'Middle-Aged'
				ELSE 'Senior'
			END,
			CASE
				WHEN yearly_income < 50000 THEN 'Low Income'
				WHEN yearly_income BETWEEN 50000 AND 100000 THEN 'Middle Income'
				ELSE 'High Income'
			END
	)
	SELECT age_group, income_group, user_count
	FROM segmentation
	ORDER BY user_count DESC;
	
	--Behavioural Segmentation current year--
	----------------------------
				WITH segmentation AS (
				SELECT
					user_id,
					CASE
						WHEN current_age < 30 THEN 'Young'
						WHEN current_age BETWEEN 30 AND 50 THEN 'Middle-Aged'
						ELSE 'Senior'
					END AS age_group,
					CASE
						WHEN yearly_income < 50000 THEN 'Low Income'
						WHEN yearly_income BETWEEN 50000 AND 100000 THEN 'Middle Income'
						ELSE 'High Income'
					END AS income_group
				FROM user_data
			)
			SELECT 
				s.age_group,
				s.income_group,
				COUNT(t.transaction_id) AS transaction_count
			FROM transaction_data t
			JOIN segmentation s ON t.user_id = s.user_id
			WHERE EXTRACT(YEAR FROM t.transaction_date) = 2024
			GROUP BY s.age_group, s.income_group
			HAVING COUNT(t.transaction_id) > 100 AND SUM(t.amount) > 10000
			ORDER BY transaction_count DESC
			LIMIT 5;
	
	--Customer Lifetime Value (CLV) Segmentation--
	----------------------------------------------
			WITH clv AS (
			SELECT 
				user_id,
				SUM(amount) AS total_spent,
				COUNT(transaction_id) AS transaction_count
			FROM transaction_data
			GROUP BY user_id
		)
		SELECT 
			COUNT(user_id) AS count,
			CASE
				WHEN total_spent > 500000 THEN 'High CLV'
				WHEN total_spent BETWEEN 100000 AND 500000 THEN 'Medium CLV'
				ELSE 'Low CLV'
			END AS clv_segment
		FROM clv
		GROUP BY 
			CASE
				WHEN total_spent > 500000 THEN 'High CLV'
				WHEN total_spent BETWEEN 100000 AND 500000 THEN 'Medium CLV'
				ELSE 'Low CLV'
			END;


	
	---Transaction Behaviour Analysis---

	--Transaction Count and Value by Day of Week--
	----------------------------------------------
	SELECT 
    TO_CHAR(transaction_date, 'Day') AS day_of_week,
    COUNT(transaction_id) AS total_transactions,
    SUM(amount) AS total_transaction_value
	FROM transaction_data
	WHERE EXTRACT(YEAR FROM transaction_date) = 2024
	GROUP BY day_of_week, TO_CHAR(transaction_date, 'D')  -- Added numeric day of the week
	ORDER BY TO_CHAR(transaction_date, 'D');  -- Sort by numeric day of the week


	--Seasonality Analysis--
	------------------------

	SELECT 
    TO_CHAR(TO_DATE(EXTRACT(MONTH FROM transaction_date)::TEXT, 'MM'), 'Month') AS month_name,
    SUM(amount) AS total_spent
	FROM transaction_data
	WHERE EXTRACT(YEAR FROM transaction_date) >= 2019
	GROUP BY EXTRACT(MONTH FROM transaction_date)
	ORDER BY EXTRACT(MONTH FROM transaction_date);


	
	--Transaction Frequency vs. Spending--
	--------------------------------------
	SELECT 
    t.user_id,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_spent,
    ROUND(AVG(t.amount), 2) AS avg_transaction_value,
    u.gender,
    u.yearly_income,
    c.credit_limit
FROM transaction_data t
JOIN user_data u ON t.user_id = u.user_id
JOIN card_data c ON t.user_id = c.user_id
GROUP BY t.user_id, u.gender, u.yearly_income, c.credit_limit
HAVING COUNT(t.transaction_id) > 5
LIMIT 100;


	
	--Customer Retention Analysis--
	-------------------------------
	
		WITH retention AS (
		SELECT 
			user_id,
			COUNT(transaction_id) AS transaction_count,
			MAX(transaction_date) AS last_purchase_date
		FROM transaction_data
		GROUP BY user_id
	)
	SELECT 
		user_id,
		transaction_count,
		CASE
			WHEN last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'Recent'
			ELSE 'Not Recent'
		END AS retention_status
	FROM retention
	ORDER BY transaction_count DESC
	LIMIT 100;

	
	--High-Value Transaction Identification--
	-----------------------------------------
	SELECT 
    user_id,
    transaction_id,
    amount
	FROM transaction_data
	WHERE amount > 500;
	
	--Merchant Analysis: Revenue Contribution--
	-------------------------------------------
	
	SELECT 
    merchant_id,
    COUNT(transaction_id) AS transaction_count,
    SUM(amount) AS total_revenue,
    ROUND(AVG(amount),2) AS avg_transaction_value
	FROM transaction_data
	GROUP BY merchant_id
	ORDER BY total_revenue DESC
	LIMIT 10;
	
	-- User Credit Limit Utilization --
	-----------------------------------
			SELECT 
				utilization_category,
				gender,
				COUNT(DISTINCT user_id) AS user_count
			FROM (
				SELECT 
					t.user_id,
					c.credit_limit,
					SUM(t.amount) AS total_spent,
					ROUND((SUM(t.amount) / c.credit_limit) * 100, 2) AS utilization_percentage,
					CASE
						WHEN (SUM(t.amount) / c.credit_limit) * 100 > 70 THEN 'More than 70%'
						WHEN (SUM(t.amount) / c.credit_limit) * 100 BETWEEN 40 AND 70 THEN '40-70%'
						ELSE 'Less than 40%'
					END AS utilization_category,
					u.gender -- Add gender to the subquery
				FROM transaction_data t
				JOIN card_data c ON t.card_id = c.card_id
				JOIN user_data u ON t.user_id = u.user_id  -- Join with user_data to get gender
				WHERE c.credit_limit > 1000
				GROUP BY t.user_id, c.credit_limit, u.gender
			) AS subquery
			GROUP BY utilization_category, gender
			ORDER BY utilization_category, user_count DESC;


	
	---Risk Detections---
 	---------------------
	
	--Credit Score-Based Risk Profiling--
	SELECT 
		risk_category,
		COUNT(DISTINCT user_id) AS user_count,
		SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
		SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
		ROUND(AVG(yearly_income),2) AS avg_yearly_income,
		ROUND(AVG(current_age),0) AS avg_current_age
	FROM (
		SELECT 
        u.user_id,
        u.gender,
        u.yearly_income,
        u.current_age,
        CASE
            WHEN u.credit_score < 300 AND (SUM(CASE WHEN c.credit_limit > 0 THEN t.amount / c.credit_limit ELSE 0 END)) * 100 > 70 THEN 'Very High Risk'
            WHEN u.credit_score < 300 THEN 'High Risk'
            WHEN u.credit_score BETWEEN 300 AND 600 AND (SUM(CASE WHEN c.credit_limit > 0 THEN t.amount / c.credit_limit ELSE 0 END)) * 100 > 70 THEN 'Moderate-High Risk'
            WHEN u.credit_score BETWEEN 300 AND 600 THEN 'Moderate Risk'
            WHEN u.credit_score BETWEEN 601 AND 750 AND (SUM(CASE WHEN c.credit_limit > 0 THEN t.amount / c.credit_limit ELSE 0 END)) * 100 > 70 THEN 'Moderate-High Risk'
            WHEN u.credit_score BETWEEN 601 AND 750 THEN 'Moderate Risk'
            WHEN u.credit_score > 750 AND u.yearly_income < 50000 THEN 'Moderate-Low Risk'
            ELSE 'Low Risk'
        END AS risk_category
    FROM user_data u
    LEFT JOIN transaction_data t ON u.user_id = t.user_id
    LEFT JOIN card_data c ON t.card_id = c.card_id
    GROUP BY u.user_id, u.credit_score, u.yearly_income, u.current_age, c.credit_limit, u.gender
	) AS risk_data
	GROUP BY risk_category
	ORDER BY user_count DESC;



	--High-Risk Transaction Detection (Large Transactions)--
	--------------------------------------------------------
	
	SELECT 
    user_id,
    transaction_id,
    amount
	FROM transaction_data
	WHERE amount > 5000;
	
	--Income Group vs. Spending Behavior--
	--------------------------------------
	
	WITH user_segments AS (
   	 SELECT 
        user_id,
        CASE
            WHEN yearly_income < 50000 THEN 'Low Income'
            WHEN yearly_income BETWEEN 50000 AND 100000 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_group
    	FROM user_data
		)
		SELECT 
			s.income_group,
			COUNT(t.transaction_id) AS transaction_count,
			SUM(t.amount) AS total_spent,
			ROUND(AVG(t.amount),2) AS avg_spent_per_transaction
		FROM transaction_data t
		JOIN user_segments s ON t.user_id = s.user_id
		GROUP BY s.income_group
		ORDER BY total_spent DESC;


	
	--Fraud Detection Based on Abnormal Spending Patterns--
	-------------------------------------------------------
	SELECT 
    user_id,
    COUNT(transaction_id) AS transaction_count,
    AVG(amount) AS avg_transaction_value
	FROM transaction_data
	GROUP BY user_id
	HAVING COUNT(transaction_id) > 10 AND AVG(amount) > 1000;
	
	---Fraud Analysis---	
	--------------------
	
	--Duplicate Transactions--
	--------------------------
	
	SELECT 
    transaction_id, 
    card_id, 
    COUNT(*) AS duplicate_count
	FROM transaction_data
	GROUP BY card_id, transaction_id
	HAVING COUNT(*) > 1;


