CREATE DATABASE IF NOT EXISTS ad_analytics ENGINE = Atomic;
USE ad_analytics;

CREATE TABLE channels (
    channel_id UInt16, channel_name String, channel_type LowCardinality(String)
) ENGINE = MergeTree ORDER BY channel_id;
CREATE TABLE campaigns (
    campaign_id UInt32, campaign_name String, channel_id UInt16,
    start_date Date, end_date Date, daily_budget Decimal(14,2), target_audience String
) ENGINE = MergeTree ORDER BY campaign_id;
CREATE TABLE raw_ads_events (
    event_id UUID, event_date Date, campaign_id UInt32, channel_id UInt16,
    event_type Enum8('impression'=1,'click'=2,'conversion'=3),
    cost Decimal(14,2), revenue Decimal(14,2),
    device LowCardinality(String), country LowCardinality(String),
    CONSTRAINT nonnegative_money CHECK cost>=0 AND revenue>=0
) ENGINE = MergeTree
PARTITION BY toYYYYMM(event_date)
ORDER BY (campaign_id,event_date,channel_id,event_type,event_id)
TTL event_date + INTERVAL 365 DAY DELETE
SETTINGS index_granularity=1024;
CREATE TABLE campaign_kpi (
    campaign_id UInt32, event_date Date, channel_id UInt16,
    impressions UInt64, clicks UInt64, conversions UInt64,
    spend Decimal(18,2), revenue Decimal(18,2),
    ctr Nullable(Float64), cvr Nullable(Float64), cpa Nullable(Float64), roi Nullable(Float64)
) ENGINE = MergeTree
PARTITION BY toYYYYMM(event_date)
ORDER BY (campaign_id,event_date,channel_id)
TTL event_date + INTERVAL 365 DAY DELETE
SETTINGS index_granularity=1024;

INSERT INTO channels VALUES
    (1,'Search','paid'),(2,'Social','paid'),(3,'Email','owned'),(4,'Partners','affiliate');
INSERT INTO campaigns
SELECT toUInt32(number+1),concat('Campaign ',toString(number+1)),toUInt16(1+number%4),
       today()-29,today(),toDecimal64(150+number*50,2),
       arrayElement(['New customers','Returning customers','Business','Students'],1+number%4)
FROM numbers(4);
INSERT INTO campaigns
SELECT toUInt32(5+number),
       arrayElement(['Awareness without spend','Clicks without conversions','Organic conversions'],1+number),
       toUInt16(1+number),today()-29,today(),toDecimal64(if(number=1,100,0),2),
       arrayElement(['New customers','Returning customers','Subscribers'],1+number)
FROM numbers(3);

INSERT INTO raw_ads_events
SELECT generateUUIDv4(),today()-toInt32(intDiv(number,400)),toUInt32(1+number%4),toUInt16(1+number%4),
       multiIf(number%100<80,'impression',number%100<95,'click','conversion'),
       toDecimal64(multiIf(number%100<80,1+number%5,number%100<95,30+number%50,0),2)/100,
       toDecimal64(if(number%100>=95,100+number%900,0),2),
       arrayElement(['desktop','mobile','tablet'],1+number%3),
       arrayElement(['RU','KZ','BY','AM'],1+intDiv(number,7)%4)
FROM numbers(12000);
-- Explicit zero-denominator groups are part of the generated business data.
INSERT INTO raw_ads_events
SELECT generateUUIDv4(),today()-1,toUInt32(5+intDiv(number,40)),toUInt16(1+intDiv(number,40)),
       arrayElement(['impression','click','conversion'],1+intDiv(number,40)),
       toDecimal64(if(number>=40 AND number<80,1,0),2),
       toDecimal64(if(number>=80,100,0),2),'mobile','RU'
FROM numbers(120);
