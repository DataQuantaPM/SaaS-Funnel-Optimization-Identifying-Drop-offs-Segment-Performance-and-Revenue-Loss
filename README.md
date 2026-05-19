# SaaS Funnel Optimization Identifying Drop-offs Segment Performance and Revenue Loss

<br>

<img src="Images/Slide Presentation/Slide 3.png" width="1100">

<br>

## 📌 Background problem
In SaaS businesses, converting users through each stage of the funnel is important for driving revenue. 

However, many users drop off at key stages, which can reduce overall conversion and lead to lost revenue.

This project analyzes where users drop off in the funnel and explores whether different acquisition sources, especially paid channels, affect conversion performance and marketing efficiency.

<br>

## 📌 Objective

The objective of this project is to analyze user behavior across the SaaS funnel and identify key drop-off points that may affect conversion.

This project also aims to compare conversion performance across different acquisition sources to understand whether certain channels, especially paid ads, contribute to lower efficiency.

Finally, the analysis seeks to estimate the potential business impact of these drop-offs and highlight opportunities to improve conversion and revenue.

<br>

## 📌 Dataset overview

This dataset represents user activity in a SaaS platform, tracking user progression across key funnel stages from signup to purchase.

Each row represents a user event, meaning a single user can appear multiple times across different funnel steps and sessions.

<br>

The dataset includes the following key fields:

| Column        | Description                                               |
| ------------- | --------------------------------                          |
| user_id       | unique identifier for each user                           |
| session_id    | identifier for each user session                          |
| event_time    | timestamp of the event                                    |
| event_name    | funnel step (signup, onboarding, trial, purchase)         |
| source        | user acquisition channel (organic, ads, referral, social) |
| country       | user location                                             |
| device        | device type (mobile, desktop, tablet)                     |
| plan_type     | subscription type (free, basic, pro)                      |
| revenue       | revenue generated from purchase events                    |

<br>

The dataset contains typical data quality issues, such as missing values, inconsistent labeling, and duplicate records.

_Data cleaning steps including deduplication and null handling —_ [ See Full SQL Code ](https://github.com/DataQuantaPM/SaaS-Funnel-Optimization-Identifying-Drop-offs-Segment-Performance-and-Revenue-Loss/blob/main/Resources/01_C1_Data_Overview_n_Cleaning.sql)

<br>

**Key Analysis: Funnel Conversion by Acquisition Source**

The following query shows funnel conversion rate per acquisition source, the core analysis of this project:

```sql
/* =========================================================
   CONVERSION BY SOURCE
   ========================================================= */

WITH conversion AS (
    SELECT
        new_source AS source,
        COUNT(DISTINCT user_id) AS total_user,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'onboarding_completed' THEN user_id END) AS onboarding_complete_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'trial_started' THEN user_id END) AS trial_users,
        COUNT(DISTINCT CASE WHEN funnel_step_real = 'purchase' THEN user_id END) AS purchase_users
    FROM final_clean_data
    GROUP BY new_source
)
SELECT
    *,
    ROUND(trial_users * 1.0 / onboarding_complete_users, 2) AS complete_to_trial,
    ROUND(purchase_users * 1.0 / trial_users, 2) AS trial_to_purchase
FROM conversion
ORDER BY complete_to_trial
```

<br>

_Funnel conversion rate analysis by acquisition source —_ [ See Full SQL Code ⤴ ]()

<br>

## 📌 Key findings

**🔹 Significant drop off occurs in the late funnel stages**

Many users successfully complete onboarding, but only a small number continue to trial and purchase.  
This shows that the main issue happens after onboarding, especially when users are expected to start a trial.

<br>

**🔹 Paid ads drive high traffic but lower conversion quality**

Users from ads make up a large part of total traffic, but their conversion rate from onboarding to trial is lower than other sources.  
This creates a gap between expected and actual trial users, showing that paid traffic may not be well targeted.

<br>

**🔹 Organic and referral channels show stronger conversion performance**

Even though they bring fewer users, organic and referral sources have higher conversion rates in the later stages.  
This suggests these users have stronger intent and better fit with the product.

<br>

**🔹 Measurable user loss in trial stage (Ads segment)**

Based on a benchmark expected ads conversion rate (~35%), ads are expected to generate around 159 trial users.  
In reality, only 106 users reached the trial stage, meaning about 53 users were lost.

<br>

**🔹 Potential revenue loss is concentrated in the trial stage**

The loss of 53 trial users leads to an estimated loss of about 5-6 paying users, assuming a 10.4% conversion from trial to purchase.  
This makes the trial stage the most critical point to improve.

<br>

## 📌 Root Cause Hypothesis

Based on the funnel and source analysis, the drop-off from onboarding to trial is likely driven by several factors:

- **Low intent traffic from paid ads**
  
  Ads users may sign up and complete onboarding, but they may not have strong enough intent to start a trial.

- **Mismatch between ad messaging and product value**
  
  Users may expect a simpler or different product experience based on the ad, which can reduce motivation after onboarding.

- **Weak onboarding to trial transition**
  
  The product may not clearly explain why users should start a trial after completing onboarding.

- **Trial activation friction**
  
  Users may face too many steps, unclear CTA, or lack of incentive before starting a trial.


<br>

## 📌 Business impact


The **main revenue problem** happens between **onboarding completion and trial**, especially for users coming from ads.
Even though many users complete onboarding, the ads channel performs poorly in moving users to the trial stage. 
Based on other sources, ads **should generate around 159 trial users**, but only 106 users actually start a trial.

This creates a **gap of 53 users** who could have entered the trial stage but did not.
If we assume a 10.4% conversion rate from trial to purchase, this means around **5 potential paying users** are lost.
With an average revenue per user (ARPU) of about $49.25, compared to the current total revenue of $1,970, fixing this issue could **increase revenue by around 13.8%**.
This means improving the onboarding to trial step especially for ads users can increase revenue without needing more traffic.

<br>

## 📌 Recommendation

**🔹 Improve onboarding to trial experience for ads users**

Simplify the transition from onboarding to trial by reducing friction.

For example:

- Add a clear and visible “Start Free Trial” call-to-action

- Reduce the number of steps required to begin a trial

- Highlight key benefits before asking users to start the trial

<br>

**🔹 Align ad messaging with product value**

Ensure that what users see in ads matches what they experience in the product.  
If there is a mismatch, users may lose interest after onboarding.
Focus on setting the right expectations in ads to attract higher-quality users.

<br>

**🔹 Add contextual prompts after onboarding**

Introduce in app prompts or reminders right after users complete onboarding.
These prompts can encourage users to start a trial by explaining what they will gain from it.

<br>

**🔹 Segment and personalize the onboarding flow**

Users from ads may need more guidance compared to organic users.  
Consider creating a slightly different onboarding flow for ads users, with more explanation or product education.

<br>

**🔹 Run A/B testing on trial entry experience**

Test different variations of:

- CTA placement

- Trial messaging

- Incentives (limited time offers)

Measure which version improves conversion from onboarding to trial.

<br>

**🔹 Improve trial incentives for paid users**

Offer stronger incentives for ads users to start a trial, such as:

- Extended trial period

- Discount on first purchase

- Bonus features during trial

<br>

## 📌 Tools used

- **SQL**

  Used for data cleaning, transformation, and funnel analysis, including handling duplicates and fixing inconsistent values.

- **Tableau**

  Used for data visualization, including funnel charts and performance comparisons across sources, devices, and countries.

- **Chat GPT**

  Used as writing assistant for documentation, creating slide presentation and executive summary, including data overview & cleaning, funnel analysis, and revenue analysis.

<br>
