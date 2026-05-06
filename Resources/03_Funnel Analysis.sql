
/* =========================================================
   FINAL DATA CLEANING PIPELINE
   ========================================================= */

/* Create a cleaned dataset as a view */
CREATE VIEW final_clean_data AS
WITH repair_typo AS (
    /* Apply all typo fixes */
    SELECT 
        user_id,
        session_id,
        event_time,
        CASE 
            WHEN event_name = 'sign_up' THEN 'signup' 
            ELSE event_name 
        END AS funnel_step_real,
        CASE 
            WHEN country = 'Indnesia' THEN 'Indonesia'
            WHEN country = '' THEN 'Unknown'
            WHEN country = 'USA' THEN 'US'
            ELSE sfd.country  
        END AS country_real,
        CASE
            WHEN device = 'Mobile' THEN 'mobile'
            WHEN device = '' THEN 'Unknown'
            ELSE device 
        END AS device_real,
        source,
        plan_type,
        revenue
    FROM saas_funnel_dataset sfd
),
remove_duplicate AS (
    /* Remove duplicate events using row_number */
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, session_id, funnel_step_real
            ORDER BY event_time
        ) AS rn
    FROM repair_typo
),
clean_data AS (
    /* Keep only the first occurrence of each event */
    SELECT 
        user_id,
        session_id,
        event_time,
        funnel_step_real,
        country_real,
        device_real,
        source,
        plan_type,
        revenue
    FROM remove_duplicate
    WHERE rn = 1
),
first_touch_sources AS (
    /* Identify first-touch source per user */
    SELECT 
        user_id,
        source AS first_touch_source
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY event_time
            ) AS rn
        FROM clean_data
    )
    WHERE rn = 1
)
/* Final aggregation */
SELECT 
    c.user_id,
    c.session_id,
    c.funnel_step_real,
    MIN(c.event_time) AS new_time,
    c.country_real,
    c.device_real,
    fts.first_touch_source AS new_source,
    c.plan_type,
    c.revenue
FROM clean_data c
JOIN first_touch_sources fts
    ON c.user_id = fts.user_id
GROUP BY 
    c.user_id,
    c.session_id,
    c.funnel_step_real,
    new_source
-- Final result: 8,801 rows
    
    
    
    
    
    

    
/* =========================================================
   FUNNEL CONVERSION ANALYSIS
   ========================================================= */

/* Count total users at each funnel step */
SELECT
    COUNT(DISTINCT user_id) AS total_user,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
FROM final_clean_data;



/* =========================================================
   DROP-OFF ANALYSIS
   ========================================================= */

/* Calculate user drop between each funnel stage */
WITH conversion AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
)
SELECT
    total_user - signup_users AS drop_total_user_to_signup,
    signup_users - email_users AS drop_signup_to_email,
    email_users - onboarding_start_users AS drop_email_to_onboard_start,
    onboarding_start_users - onboarding_complete_users AS drop_onboard_start_to_complete,
    onboarding_complete_users - trial_users AS drop_complete_to_trial,
    trial_users - purchase_users AS drop_trial_to_purchase
FROM conversion;



/* =========================================================
   STEP-BY-STEP AND TOTAL CONVERSION RATES
   ========================================================= */

/* Calculate both step conversion and overall funnel conversion */
WITH conversion AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
)
SELECT
    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup,
    ROUND(email_users * 1.0 / signup_users, 2) AS signup_to_email,
    ROUND(onboarding_start_users * 1.0 / email_users, 2) AS email_to_onboard_start,
    ROUND(onboarding_complete_users * 1.0 / onboarding_start_users, 2) AS onboard_start_to_complete,
    ROUND(trial_users * 1.0 / onboarding_complete_users, 2) AS complete_to_trial,
    ROUND(purchase_users * 1.0 / trial_users, 2) AS trial_to_purchase,

    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup_all,
    ROUND(email_users * 1.0 / total_user, 2) AS total_user_to_email_all,
    ROUND(onboarding_start_users * 1.0 / total_user, 2) AS total_user_to_onboard_start_all,
    ROUND(onboarding_complete_users * 1.0 / total_user, 2) AS total_user_to_complete_all,
    ROUND(trial_users * 1.0 / total_user, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion;



/* =========================================================
   CONVERSION BY SOURCE
   ========================================================= */

/* Analyze funnel performance segmented by acquisition source */
WITH conversion AS (
    SELECT
        new_source AS source,
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
    GROUP BY new_source
)
SELECT
    *,
    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup,
    ROUND(email_users * 1.0 / signup_users, 2) AS signup_to_email,
    ROUND(onboarding_start_users * 1.0 / email_users, 2) AS email_to_onboard_start,
    ROUND(onboarding_complete_users * 1.0 / onboarding_start_users, 2) AS onboard_start_to_complete,
    ROUND(trial_users * 1.0 / onboarding_complete_users, 2) AS complete_to_trial,
    ROUND(purchase_users * 1.0 / trial_users, 2) AS trial_to_purchase,

    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup_all,
    ROUND(email_users * 1.0 / total_user, 2) AS total_user_to_email_all,
    ROUND(onboarding_start_users * 1.0 / total_user, 2) AS total_user_to_onboard_start_all,
    ROUND(onboarding_complete_users * 1.0 / total_user, 2) AS total_user_to_complete_all,
    ROUND(trial_users * 1.0 / total_user, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
ORDER BY complete_to_trial;



/* =========================================================
   CONVERSION BY DEVICE
   ========================================================= */

/* Analyze funnel performance by device type */
WITH conversion AS (
    SELECT
        device_real,
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
    GROUP BY device_real
)
SELECT
    *,
    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup,
    ROUND(email_users * 1.0 / signup_users, 2) AS signup_to_email,
    ROUND(onboarding_start_users * 1.0 / email_users, 2) AS email_to_onboard_start,
    ROUND(onboarding_complete_users * 1.0 / onboarding_start_users, 2) AS onboard_start_to_complete,
    ROUND(trial_users * 1.0 / onboarding_complete_users, 2) AS complete_to_trial,
    ROUND(purchase_users * 1.0 / trial_users, 2) AS trial_to_purchase,

    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup_all,
    ROUND(email_users * 1.0 / total_user, 2) AS total_user_to_email_all,
    ROUND(onboarding_start_users * 1.0 / total_user, 2) AS total_user_to_onboard_start_all,
    ROUND(onboarding_complete_users * 1.0 / total_user, 2) AS total_user_to_complete_all,
    ROUND(trial_users * 1.0 / total_user, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
ORDER BY complete_to_trial;



/* =========================================================
   CONVERSION BY COUNTRY
   ========================================================= */

/* Analyze funnel performance across different countries */
WITH conversion AS (
    SELECT
        country_real,
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
    GROUP BY country_real
)
SELECT
    *,
    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup,
    ROUND(email_users * 1.0 / signup_users, 2) AS signup_to_email,
    ROUND(onboarding_start_users * 1.0 / email_users, 2) AS email_to_onboard_start,
    ROUND(onboarding_complete_users * 1.0 / onboarding_start_users, 2) AS onboard_start_to_complete,
    ROUND(trial_users * 1.0 / onboarding_complete_users, 2) AS complete_to_trial,
    ROUND(purchase_users * 1.0 / trial_users, 2) AS trial_to_purchase,

    ROUND(signup_users * 1.0 / total_user, 2) AS total_user_to_signup_all,
    ROUND(email_users * 1.0 / total_user, 2) AS total_user_to_email_all,
    ROUND(onboarding_start_users * 1.0 / total_user, 2) AS total_user_to_onboard_start_all,
    ROUND(onboarding_complete_users * 1.0 / total_user, 2) AS total_user_to_complete_all,
    ROUND(trial_users * 1.0 / total_user, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
ORDER BY complete_to_trial;



/* =========================================================
   REVENUE ANALYSIS
   ========================================================= */

/* Calculate total revenue contribution by acquisition source */
SELECT 
    new_source,
    SUM(revenue) AS total_revenue
FROM final_clean_data
GROUP BY new_source;