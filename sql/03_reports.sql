USE ad_analytics;
-- 1. Seven calendar days including today; ROI is a ratio of totals.
SELECT k.campaign_id,any(c.campaign_name) AS campaign_name,sum(k.spend) AS spend,sum(k.revenue) AS revenue,
       (toFloat64(sum(k.revenue))-toFloat64(sum(k.spend)))/nullIf(toFloat64(sum(k.spend)),0) AS roi
FROM campaign_kpi k INNER JOIN campaigns c ON c.campaign_id=k.campaign_id
WHERE k.event_date>=today()-6 AND k.event_date<=today()
GROUP BY k.campaign_id HAVING sum(k.spend)>0 ORDER BY roi DESC,k.campaign_id LIMIT 5;
-- 2. Undefined CPA is excluded from ranking, not turned into a fictitious zero.
SELECT k.channel_id,any(c.channel_name) AS channel_name,sum(k.conversions) AS conversions,
       sum(k.spend) AS spend,toFloat64(sum(k.spend))/nullIf(toFloat64(sum(k.conversions)),0) AS cpa
FROM campaign_kpi k INNER JOIN channels c ON c.channel_id=k.channel_id
GROUP BY k.channel_id HAVING sum(k.conversions)>0 ORDER BY cpa,k.channel_id LIMIT 5;
-- 3. CTR is a fraction: 1% = 0.01.
SELECT k.campaign_id,any(c.campaign_name) AS campaign_name,sum(k.impressions) AS impressions,
       sum(k.clicks) AS clicks,toFloat64(sum(k.clicks))/nullIf(toFloat64(sum(k.impressions)),0) AS ctr
FROM campaign_kpi k INNER JOIN campaigns c ON c.campaign_id=k.campaign_id
GROUP BY k.campaign_id HAVING sum(k.impressions)>0 AND ctr<0.01 ORDER BY ctr,k.campaign_id;
-- 4. Daily dynamics for campaign 1. Change the literal to select another campaign.
SELECT event_date,sum(spend) AS spend,sum(revenue) AS revenue
FROM campaign_kpi WHERE campaign_id=1 GROUP BY event_date ORDER BY event_date;
-- 5. A complete campaign/day calendar includes days without events and expenses.
SELECT c.campaign_id,c.campaign_name,toDate(d.event_date) AS event_date,c.daily_budget,
       coalesce(k.spend,toDecimal64(0,2)) AS spend,
       spend-c.daily_budget AS budget_overrun,
       toFloat64(spend)/nullIf(toFloat64(c.daily_budget),0) AS budget_used
FROM campaigns c
CROSS JOIN (SELECT today()-toInt32(number) AS event_date FROM numbers(30)) d
LEFT JOIN (SELECT campaign_id,event_date,sum(spend) AS spend FROM campaign_kpi GROUP BY campaign_id,event_date) k
    ON k.campaign_id=c.campaign_id AND k.event_date=d.event_date
WHERE d.event_date BETWEEN c.start_date AND c.end_date
ORDER BY c.campaign_id,event_date
SETTINGS join_use_nulls=1;
