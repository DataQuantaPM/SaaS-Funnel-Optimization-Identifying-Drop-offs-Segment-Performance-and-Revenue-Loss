/* =========================================================
   BASIC DATA OVERVIEW
   ========================================================= */

/* Count total number of rows in the dataset */
SELECT COUNT(*)
FROM saas_funnel_dataset sfd;
-- Expected: 10,657 rows


/* Count total unique users */
SELECT COUNT(DISTINCT sfd.user_id) AS unique_user
FROM saas_funnel_dataset sfd;
-- Expected: 2,882 users



/* =========================================================
   DATA EXPLORATION (UNIQUE VALUES)
   ========================================================= */

/* Check unique funnel steps and identify potential typos */
SELECT event_name, COUNT(event_name)
FROM saas_funnel_dataset sfd
GROUP BY event_name;
-- Found typo: 'sign_up'


/* Check unique countries and detect inconsistencies */
SELECT country, COUNT(*)
FROM saas_funnel_dataset sfd
GROUP BY country;
-- Found issues: '', 'Indnesia', 'USA'


/* Check unique subscription plans */
SELECT plan_type, COUNT(*)
FROM saas_funnel_dataset sfd
GROUP BY plan_type;


/* Check traffic sources */
SELECT source, COUNT(*)
FROM saas_funnel_dataset sfd
GROUP BY source;


/* Check device types and detect inconsistencies */
SELECT device, COUNT(*)
FROM saas_funnel_dataset sfd
GROUP BY device;
-- Found issues: 'Mobile', ''



/* =========================================================
   FIXING DATA QUALITY ISSUES (TYPO HANDLING)
   ========================================================= */


/* Standardize funnel step naming */
WITH typo_funnel_step AS (
    SELECT 
        CASE 
            WHEN event_name = 'sign_up' THEN 'signup'
            ELSE sfd.event_name 
        END AS funnel_step_real
    FROM saas_funnel_dataset sfd
)
SELECT funnel_step_real, COUNT(*)
FROM typo_funnel_step
GROUP BY funnel_step_real
ORDER BY COUNT(*) DESC;




/* Standardize country naming */
WITH typo_country AS (
    SELECT 
        CASE 
            WHEN country = 'Indnesia' THEN 'Indonesia'
            WHEN country = '' THEN 'Unknown'
            WHEN country = 'USA' THEN 'US'
            ELSE sfd.country 
        END AS country_real
    FROM saas_funnel_dataset sfd
)
SELECT country_real, COUNT(*)
FROM typo_country
GROUP BY country_real;




/* Standardize device naming */
WITH typo_device AS (
    SELECT 
        CASE
            WHEN device = 'Mobile' THEN 'mobile'
            WHEN device = '' THEN 'Unknown'
            ELSE device 
        END AS device_real
    FROM saas_funnel_dataset sfd
)
SELECT device_real, COUNT(*)
FROM typo_device
GROUP BY device_real;



/* =========================================================
   APPLY ALL TYPO FIXES INTO ONE TRANSFORMATION
   ========================================================= */

/* Combine all cleaning rules into a single CTE */
WITH repair_typo AS (
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
            ELSE country 
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
)
SELECT *
FROM repair_typo;





/* =========================================================
   DATA QUALITY CHECKS
   ========================================================= */

/* Check duplicate events per user-session-funnel step */
WITH repair_typo AS (
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
)
SELECT 
    user_id,
    funnel_step_real,
    session_id,
    COUNT(*) AS jumlah
FROM repair_typo
GROUP BY user_id, funnel_step_real, session_id
HAVING COUNT(*) > 1;
-- Found: 1,856 duplicate rows


/* Check users with multiple acquisition sources */
SELECT 
    user_id,
    COUNT(DISTINCT source) AS source_count
FROM saas_funnel_dataset sfd
GROUP BY user_id
HAVING COUNT(DISTINCT source) > 1;
-- Found: 11 users





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
