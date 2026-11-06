USE ad_analytics;
SELECT table,partition,count() AS active_parts,sum(rows) AS rows,sum(bytes_on_disk) AS bytes_on_disk
FROM system.parts WHERE database='ad_analytics' AND active
GROUP BY table,partition ORDER BY table,partition;
SELECT database,table,elapsed,progress,num_parts,total_size_bytes_compressed
FROM system.merges WHERE database='ad_analytics';
SHOW CREATE TABLE raw_ads_events;
SHOW CREATE TABLE campaign_kpi;
EXPLAIN indexes=1
SELECT sum(cost),sum(revenue) FROM raw_ads_events
WHERE campaign_id=1 AND event_date>=today()-6 AND event_date<=today();
EXPLAIN indexes=1
SELECT sum(spend),sum(revenue) FROM campaign_kpi
WHERE campaign_id=1 AND event_date>=today()-6 AND event_date<=today();
SET log_queries=1;
SELECT sum(cost),sum(revenue) FROM raw_ads_events
WHERE campaign_id=1 AND event_date>=today()-6 AND event_date<=today();
SELECT sum(spend),sum(revenue) FROM campaign_kpi
WHERE campaign_id=1 AND event_date>=today()-6 AND event_date<=today();
SYSTEM FLUSH LOGS;
SELECT event_time,query_duration_ms,read_rows,read_bytes,result_rows,memory_usage,query
FROM system.query_log
WHERE type='QueryFinish' AND current_database='ad_analytics'
  AND (query LIKE 'SELECT sum(cost),sum(revenue) FROM raw_ads_events%'
       OR query LIKE 'SELECT sum(spend),sum(revenue) FROM campaign_kpi%')
ORDER BY event_time DESC LIMIT 4;
