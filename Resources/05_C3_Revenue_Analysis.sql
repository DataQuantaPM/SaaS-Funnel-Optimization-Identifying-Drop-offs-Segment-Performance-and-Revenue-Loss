/* =========================================================
   REVENUE ANALYSIS
   ========================================================= */

/* Calculate total revenue contribution by acquisition source */
SELECT 
    new_source,
    SUM(revenue) AS total_revenue
FROM final_clean_data
GROUP BY new_source







/* =========================================================
   ARPU (AVERAGE REVENUE PER USER)
   ========================================================= */

/* Calculate ARPU based on purchase events only */
CREATE VIEW ARPU AS

SELECT 
    SUM(revenue) AS total_revenue,
    COUNT(user_id) AS total_user,
    (SUM(revenue) * 1.0) / COUNT(user_id) AS arpu
FROM final_clean_data
WHERE funnel_step_real = 'purchase'

-- ARPU: 49.25








/* =========================================================
   EXPECTED CONVERSION ANALYSIS
   ========================================================= */

/* Estimate expected onboarding-to-trial conversion */
CREATE VIEW expected_trial_conversion AS

WITH completed_to_trial AS (
    /* Count onboarding completed and trial users per source */
    SELECT 
        new_source,
        COUNT(DISTINCT CASE 
            WHEN funnel_step_real = 'trial_started' 
            THEN user_id 
        END) AS trial_started,
        COUNT(DISTINCT CASE 
            WHEN funnel_step_real = 'onboarding_completed' 
            THEN user_id 
        END) AS onboarding_completed
    FROM final_clean_data
    GROUP BY new_source
),
funnel_conversion AS (
    /* Exclude ads source to calculate benchmark conversion */
    SELECT 
        new_source AS source,
        ROUND(trial_started * 1.0 / onboarding_completed, 2) AS conversion
    FROM completed_to_trial
    GROUP BY new_source
    HAVING new_source != 'ads'
)
/* Apply risk adjustment to expected conversion */
SELECT 
    MIN(conversion) - 0.02 AS expected_conversion
FROM funnel_conversion
-- Conversion range: 37% - 41%
-- Risk adjustment:
-- Use the minimum benchmark conversion and reduce by 2%
-- 37% - 2% = 35% expected conversion








/* =========================================================
   LOST TRIAL USER ANALYSIS
   ========================================================= */

/* Estimate how many potential trial users were lost from ads */
CREATE VIEW loss_trial_users AS

WITH actual_trial_users AS (
    /* Actual ads users who started trial */
    SELECT 
        COUNT(DISTINCT user_id) AS actual_trial_user
    FROM final_clean_data
    WHERE funnel_step_real = 'trial_started'
        AND new_source = 'ads'
    -- Actual ads trial users: 106
),
expected_trial_users AS (
    /* Estimate expected trial users using benchmark conversion */
    SELECT 
        COUNT(DISTINCT user_id) AS actual_onboarding_completed,
        ROUND(COUNT(DISTINCT user_id) * expected_conversion,0) AS expected_trial_user
    FROM final_clean_data
    JOIN expected_trial_conversion
    WHERE funnel_step_real = 'onboarding_completed'
        AND new_source = 'ads'
    -- Expected ads trial users: 159
)
/* Calculate estimated lost users */
SELECT 
    expected_trial_user,
    actual_trial_user,
    expected_trial_user - actual_trial_user AS loss_users
FROM actual_trial_users
JOIN expected_trial_users
-- Estimated lost trial users: 53
-- Actual ads trial users: 106
-- Expected ads trial users: 159








/* =========================================================
   LOST REVENUE ANALYSIS
   ========================================================= */

/* Estimate revenue lost due to missing trial conversions */
CREATE VIEW loss_revenue AS

WITH conv_trial_to_purchase AS (
    /* Calculate ads trial-to-purchase conversion rate */
    SELECT 
        ROUND(
            COUNT(DISTINCT CASE 
                WHEN funnel_step_real = 'purchase' 
                THEN user_id 
            END) * 1.0
            /
            COUNT(DISTINCT CASE 
                WHEN funnel_step_real = 'trial_started' 
                THEN user_id 
            END),
            3) AS trial_to_purchase
    FROM final_clean_data
    WHERE new_source = 'ads'
    -- Trial to purchase conversion: 10.4%
),
user_purchase_lost AS (
    /* Estimate how many purchase users were lost */
    SELECT 
        ROUND(loss_users * trial_to_purchase, 1) AS purchase_user_lost
    FROM conv_trial_to_purchase
    JOIN loss_trial_users
    -- Estimated lost purchase users: 5-6 users
)
/* Calculate estimated revenue loss */
SELECT 
    ROUND(purchase_user_lost * arpu, 0) AS loss_revenue
FROM user_purchase_lost
JOIN arpu
-- Estimated revenue loss: ~$271
-- Trial to purchase conversion: 10.4%
-- Estimated lost purchase users: 5-6 users








/* =========================================================
   EXPECTED REVENUE IMPACT
   ========================================================= */

/* Calculate expected revenue and potential revenue increase */
SELECT 
    total_revenue + loss_revenue AS expected_revenue,
    ROUND(loss_revenue / total_revenue,3) AS revenue_increase
FROM arpu
JOIN loss_revenue
-- Expected revenue: $2,241
-- Revenue increase potential: 13.8%




