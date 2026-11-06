USE ad_analytics;
-- Full snapshot rebuild: re-running this file does not add duplicate aggregates.
-- Atomic name exchange keeps the previous complete snapshot readable during the build.
DROP TABLE IF EXISTS campaign_kpi_build;
CREATE TABLE campaign_kpi_build AS campaign_kpi;
INSERT INTO campaign_kpi_build
SELECT campaign_id,event_date,channel_id,impressions,clicks,conversions,spend,revenue,
       toFloat64(clicks)/nullIf(toFloat64(impressions),0) AS ctr,
       toFloat64(conversions)/nullIf(toFloat64(clicks),0) AS cvr,
       toFloat64(spend)/nullIf(toFloat64(conversions),0) AS cpa,
       (toFloat64(revenue)-toFloat64(spend))/nullIf(toFloat64(spend),0) AS roi
FROM (
    SELECT campaign_id,event_date,channel_id,countIf(event_type='impression') AS impressions,
           countIf(event_type='click') AS clicks,countIf(event_type='conversion') AS conversions,
           CAST(sum(cost) AS Decimal(18,2)) AS spend,CAST(sum(revenue) AS Decimal(18,2)) AS revenue
    FROM raw_ads_events
    WHERE event_date>today()-365
    GROUP BY campaign_id,event_date,channel_id
);
EXCHANGE TABLES campaign_kpi AND campaign_kpi_build;
DROP TABLE campaign_kpi_build;
