
-------------------------
-- Count all rows (10000)
-------------------------
select count(*)
from saas_funnel_dataset sfd
-- 10.657 rows




------------------------
-- Count all Unique User
------------------------
select count(distinct sfd.user_id) Unique_User
from saas_funnel_dataset sfd 
-- 2.882 User





-- Idetify Unique Value-----------------------------------------------------------------


---------------------
-- Unique Funnel Step
---------------------
select event_name, count(event_name)
from saas_funnel_dataset sfd 
group by event_name 
-- Typo		
-- sign_up




-----------------
-- Unique Country
-----------------
select country, count(*)
from saas_funnel_dataset sfd 
group by country
-- Typo		
-- ( )
-- Indnesia
-- USA



-------------
--Unique Plan
-------------
select plan_type, count(*)
from saas_funnel_dataset sfd 
group by plan_type 



---------------
--Unique Source
---------------
select source, count(*)
from saas_funnel_dataset sfd 
group by source



----------------
-- Unique Device
----------------
select device, count(*)
from saas_funnel_dataset sfd 
group by device
-- Typo	
-- Mobile
-- ( )




-- Fix typo ---------------------------------------------------------------------


----------------------------
-- perbaiki typo funnal step
----------------------------
With typo_funnel_step as (
select Case 
		When event_name = 'sign_up' Then 'signup' else sfd.event_name 
		END funnel_step_real
FROM saas_funnel_dataset sfd 
)
select funnel_step_real, count(*)
from typo_funnel_step 
group by funnel_step_real
order by count(*) desc




------------------------
-- perbaiki typo country
------------------------
with typo_country as (
select case 
		when country = 'Indnesia' then 'Indonesia' 
		when country = '' then 'Unknown' 
		when country = 'USA' then 'US' else sfd.country 
		end country_real
from saas_funnel_dataset sfd 
) 
select country_real, count(*)
from typo_country 
group by country_real 





-----------------------
-- perbaiki typo device
-----------------------
with typo_device as (
select case
		when device = 'Mobile' then 'mobile' 
		when device = '' then 'Unknown'
		else device 
end device_real
from saas_funnel_dataset sfd 	
)
select device_real, count(*)
from typo_device 
group by device_real



--------------
--Fix all Typo
--------------
With repair_typo as (
select user_id , session_id , event_time , 
		Case 
		When event_name = 'sign_up' Then 'signup' else event_name END funnel_step_real,
		case 
		when country = 'Indnesia' then 'Indonesia' when country = '' then 'Unknown' when country = 'USA' then 'US' else country end country_real,
		case
		when device = 'Mobile' then 'mobile' when device = '' then 'Unknown'else device end device_real,
		source, plan_type , revenue
FROM saas_funnel_dataset sfd
)
select *
from repair_typo 




---------------------------------------------------------------------------------


 
--------------------------------------------------------------
-- Check data who have same user_id, event_name and session_id
--------------------------------------------------------------
WITH repair_typo AS (
    SELECT 
        user_id, session_id, event_time,
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
        source, plan_type, revenue
    FROM saas_funnel_dataset sfd
)
select user_id, funnel_step_real , session_id, count(*) jumlah
from repair_typo 
group by user_id, funnel_step_real , session_id
having count(*) > 1
-- ada 1856 rows




------------------------------------------
-- Check Users who have more than 1 source
------------------------------------------
SELECT user_id, COUNT(DISTINCT source) as source_count
FROM saas_funnel_dataset sfd 
GROUP BY user_id
HAVING COUNT(DISTINCT source) > 1
-- 11 rows






-------------
-- Clean Data
------------- 
CREATE VIEW final_clean_data AS 
WITH repair_typo AS (
    SELECT 
        user_id, session_id, event_time,
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
        source, plan_type, revenue
    FROM saas_funnel_dataset sfd
),
remove_duplicate AS (    
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, session_id, funnel_step_real
            ORDER BY event_time
        ) AS rn
    FROM repair_typo 
),
clean_data AS (
    SELECT 
        user_id, session_id, event_time, funnel_step_real,
        country_real, device_real, source, plan_type, revenue
    FROM remove_duplicate
    WHERE rn = 1
),
first_touch_sources AS (
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
SELECT 
    c.user_id,
    session_id,
    c.funnel_step_real,
    MIN(c.event_time) AS new_time,
    country_real, 
    device_real,
    fts.first_touch_source AS new_source,
    plan_type, 
    revenue
FROM clean_data c
JOIN first_touch_sources fts 
    ON c.user_id = fts.user_id
GROUP BY 
    c.user_id, 
    session_id,
    c.funnel_step_real,
    new_source
-- 8.801 rows

    

    
    
    
----------------------
-- Total User per Step
----------------------
SELECT
    COUNT(DISTINCT user_id) AS total_user,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'signup' THEN user_id END) AS signup_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'email_verified' THEN user_id END) AS email_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_started' THEN user_id END) AS onboarding_start_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
    COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
FROM final_clean_data





----------------------
-- Total User Drop per Step 
----------------------
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
FROM conversion



    
    
    
    

-----------------
-- all conversion
-----------------
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
    ROUND(trial_users * 1.0 / total_user	, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
    
    
    
    
    




----------------------
--conversion by source
----------------------
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
    ROUND(trial_users * 1.0 / total_user	, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
order by complete_to_trial 








----------------------
--conversion by device
----------------------
-- identify worst performing source
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
    ROUND(trial_users * 1.0 / total_user	, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
order by complete_to_trial 




-----------------------
--conversion by country
-----------------------
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
    ROUND(trial_users * 1.0 / total_user	, 2) AS total_user_to_trial_all,
    ROUND(purchase_users * 1.0 / total_user, 2) AS total_user_to_purchase_all
FROM conversion
order by complete_to_trial 








---------------------
-- Revenue by Sources
---------------------
select new_source , sum(revenue)
from final_clean_data
group by new_source 









