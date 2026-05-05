# SaaS-Funnel-Optimization-Identifying-Drop-offs-Segment-Performance-and-Revenue-Loss

<br>

<img src="Images/funnel conversion overall n step.png" width="900">

<br>

## 📌 Background problem
In SaaS B2C businesses, converting users through each stage of the funnel is important for driving revenue. 

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

🔹 **user_id**: unique identifier for each user

🔹 **session_id**: identifier for each user session

🔹 **event_time**: timestamp of the event

🔹 **event_name**: funnel step (e.g., signup, onboarding, trial, purchase)

🔹 **source**: user acquisition channel (organic, ads, referral, social)

🔹 **country**: user location

🔹 **device**: device type (mobile, desktop, tablet)

🔹 **plan_type**: subscription type (free, basic, pro)

🔹 **revenue**: revenue generated from purchase events

<br>

The dataset contains typical data quality issues, such as missing values, inconsistent labeling, and duplicate records.

<br>

## 📌 Key findings

**🔹 Significant drop-off occurs in the late funnel stages**

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

Based on a benchmark conversion rate (~35%), ads are expected to generate around 159 trial users.  
In reality, only 106 users reached the trial stage, meaning about 53 users were lost.

<br>

**🔹 Potential revenue loss is concentrated in the trial stage**

The loss of 53 trial users leads to an estimated loss of about 5 paying users, assuming a 10% conversion from trial to purchase.  
This makes the trial stage the most critical point to improve.

<br>

## 📌 Business impact


🔹The main revenue problem happens between onboarding completion and trial, especially for users coming from ads.

🔹Even though many users complete onboarding, the ads channel performs poorly in moving users to the trial stage. Based on other sources, ads should generate around 159 trial users, but only 106 users actually start a trial.

🔹This creates a gap of 53 users who could have entered the trial stage but did not.

🔹If we assume a 10% conversion rate from trial to purchase, this means around 5 potential paying users are lost.

🔹With an average revenue per user (ARPU) of about $50, this results in an estimated revenue loss of $250.

🔹Compared to the current total revenue of $1,970, fixing this issue could increase revenue by around 12.5%.

🔹This means improving the onboarding to trial step especially for ads users—can increase revenue without needing more traffic.

<br>

## 📌 Recommendation

<br>

## 📌 Tools used

<br>
