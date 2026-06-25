CREATE OR REPLACE SEMANTIC VIEW NS11MM_DW_PROD.MARTS.SV_MARKETING_PERFORMANCE

  TABLES (
    ad_performance AS NS11MM_DW_PROD.MARTS.FCT_DIGITAL_AD_PERFORMANCE
      WITH SYNONYMS ('ads', 'digital ads', 'paid media')
      COMMENT = 'Unified digital advertising performance across Google Ads and Meta platforms',
    website_traffic AS NS11MM_DW_PROD.MARTS.FCT_WEBSITE_TRAFFIC
      WITH SYNONYMS ('web traffic', 'GA sessions', 'website sessions')
      COMMENT = 'Daily website traffic aggregated by channel, campaign, page category, and device',
    email_campaigns AS NS11MM_DW_PROD.MARTS.FCT_CAMPAIGN_PERFORMANCE
      WITH SYNONYMS ('email', 'email marketing', 'SFMC campaigns')
      COMMENT = 'Email campaign performance with open/click/bounce/unsubscribe rates',
    channel_summary AS NS11MM_DW_PROD.MARTS.FCT_MARKETING_CHANNEL_SUMMARY
      WITH SYNONYMS ('cross-channel', 'all channels', 'channel comparison')
      COMMENT = 'Unified daily channel performance across all marketing channels',
    channels AS NS11MM_DW_PROD.MARTS.DIM_MARKETING_CHANNEL
      PRIMARY KEY (channel_id)
      COMMENT = 'Marketing channel dimension with paid/owned/earned classification',
    dates AS NS11MM_DW_PROD.MARTS.DIM_DATE
      PRIMARY KEY (date_day)
      COMMENT = 'Date dimension with fiscal year context'
  )

  RELATIONSHIPS (
    ad_performance_to_dates AS
      ad_performance (report_date) REFERENCES dates (date_day),
    website_traffic_to_dates AS
      website_traffic (report_date) REFERENCES dates (date_day),
    email_campaigns_to_dates AS
      email_campaigns (first_send_date) REFERENCES dates (date_day),
    channel_summary_to_dates AS
      channel_summary (report_date) REFERENCES dates (date_day),
    channel_summary_to_channels AS
      channel_summary (channel_id) REFERENCES channels (channel_id)
  )

  FACTS (
    ad_performance.fact_impressions AS impressions
      COMMENT = 'Number of ad impressions',
    ad_performance.fact_clicks AS clicks
      COMMENT = 'Number of ad clicks',
    ad_performance.fact_spend AS spend
      COMMENT = 'Ad spend in dollars',
    ad_performance.fact_conversions AS conversions
      COMMENT = 'Number of ad-attributed conversions',
    ad_performance.fact_conversion_value AS conversion_value
      COMMENT = 'Revenue value from ad-attributed conversions',
    ad_performance.fact_reach AS reach
      COMMENT = 'Total unique users reached (Meta only, NULL for Google)',
    ad_performance.fact_frequency AS frequency
      COMMENT = 'Average ad frequency per user (Meta only, NULL for Google)',
    website_traffic.fact_sessions AS sessions
      COMMENT = 'Number of website sessions',
    website_traffic.fact_unique_users AS unique_users
      COMMENT = 'Count of distinct website visitors',
    website_traffic.fact_web_conversions AS website_traffic.conversions
      COMMENT = 'Number of website purchase conversions',
    email_campaigns.fact_total_sent AS total_sent
      COMMENT = 'Total emails sent for campaign',
    email_campaigns.fact_total_opens AS total_opens
      COMMENT = 'Total email opens',
    email_campaigns.fact_total_clicks AS total_clicks
      COMMENT = 'Total email link clicks',
    email_campaigns.fact_total_bounces AS total_bounces
      COMMENT = 'Total email bounces',
    email_campaigns.fact_total_unsubscribes AS total_unsubscribes
      COMMENT = 'Total email unsubscribes',
    channel_summary.fact_channel_spend AS channel_summary.spend
      COMMENT = 'Daily spend per channel',
    channel_summary.fact_channel_conversions AS channel_summary.conversions
      COMMENT = 'Daily conversions per channel',
    channel_summary.fact_channel_conversion_value AS channel_summary.conversion_value
      COMMENT = 'Daily conversion value per channel'
  )

  DIMENSIONS (
    ad_performance.ad_platform AS ad_platform
      WITH SYNONYMS = ('platform', 'ad network', 'advertising platform')
      COMMENT = 'Advertising platform (Google Ads, Facebook, Instagram)',
    ad_performance.campaign_name AS ad_campaign_name
      WITH SYNONYMS = ('ad campaign', 'paid campaign')
      COMMENT = 'Name of the advertising campaign',
    ad_performance.campaign_category AS ad_campaign_category
      WITH SYNONYMS = ('campaign type', 'campaign category')
      COMMENT = 'Derived campaign category (Tickets, Membership, Retail, Promotions, Awareness, General)',
    ad_performance.ad_group_or_adset AS ad_group_or_adset
      COMMENT = 'Ad group (Google) or ad set (Meta) name',
    ad_performance.placement AS ad_placement
      COMMENT = 'Ad placement or network type (SEARCH, DISPLAY, feed, reels, stories)',
    website_traffic.channel_grouping AS channel_grouping
      WITH SYNONYMS = ('channel', 'traffic channel', 'marketing channel')
      COMMENT = 'Marketing channel grouping (Paid Search, Paid Social, Organic Search, Email, Direct)',
    website_traffic.source AS traffic_source
      WITH SYNONYMS = ('source', 'referrer')
      COMMENT = 'Traffic source (google, facebook, direct, email)',
    website_traffic.medium AS traffic_medium
      COMMENT = 'Traffic medium (cpc, organic, paid, email)',
    website_traffic.page_category AS page_category
      WITH SYNONYMS = ('section', 'site section')
      COMMENT = 'Website page category (Tickets, Membership, Retail, Exhibitions, Donations, General)',
    website_traffic.device_category AS device_category
      WITH SYNONYMS = ('device', 'device type')
      COMMENT = 'Device category (desktop, mobile, tablet)',
    email_campaigns.campaign_name AS email_campaign_name
      WITH SYNONYMS = ('email campaign', 'SFMC campaign')
      COMMENT = 'Email campaign name from Salesforce Marketing Cloud',
    channels.channel_name AS channel_name
      WITH SYNONYMS = ('channel', 'marketing channel name')
      COMMENT = 'Marketing channel name (Paid Search, Paid Social, Email, etc.)',
    channels.is_paid AS is_paid_channel
      COMMENT = 'Whether this is a paid channel',
    channels.channel_group AS channel_group
      COMMENT = 'Channel ownership group (Paid, Owned, Earned)',
    dates.fiscal_year AS fiscal_year
      COMMENT = 'Fiscal year (July start)',
    dates.month_name AS month_name
      COMMENT = 'Calendar month name',
    dates.is_weekend AS is_weekend
      COMMENT = 'Whether the date is a weekend'
  )

  METRICS (
    ad_performance.total_impressions AS SUM(ad_performance.fact_impressions)
      COMMENT = 'Total ad impressions',
    ad_performance.total_clicks AS SUM(ad_performance.fact_clicks)
      COMMENT = 'Total ad clicks',
    ad_performance.total_spend AS SUM(ad_performance.fact_spend)
      COMMENT = 'Total ad spend in dollars',
    ad_performance.total_ad_conversions AS SUM(ad_performance.fact_conversions)
      COMMENT = 'Total ad-attributed conversions',
    ad_performance.total_conversion_value AS SUM(ad_performance.fact_conversion_value)
      COMMENT = 'Total revenue from ad conversions',
    ad_performance.total_reach AS SUM(ad_performance.fact_reach)
      COMMENT = 'Total reach (Meta only)',
    ad_performance.avg_frequency AS AVG(ad_performance.fact_frequency)
      COMMENT = 'Average frequency (Meta only)',
    ad_performance.avg_ctr AS AVG(ad_performance.ctr)
      COMMENT = 'Average click-through rate',
    ad_performance.avg_cpc AS AVG(ad_performance.avg_cpc)
      COMMENT = 'Average cost per click',
    ad_performance.avg_roas AS AVG(ad_performance.roas)
      COMMENT = 'Average return on ad spend',
    website_traffic.total_sessions AS SUM(website_traffic.fact_sessions)
      COMMENT = 'Total website sessions',
    website_traffic.total_unique_users AS SUM(website_traffic.fact_unique_users)
      COMMENT = 'Total unique website visitors',
    website_traffic.total_web_conversions AS SUM(website_traffic.fact_web_conversions)
      COMMENT = 'Total website purchase conversions',
    website_traffic.avg_conversion_rate AS AVG(website_traffic.conversion_rate_pct)
      COMMENT = 'Average website conversion rate percentage',
    email_campaigns.total_emails_sent AS SUM(email_campaigns.fact_total_sent)
      COMMENT = 'Total emails sent across campaigns',
    email_campaigns.avg_open_rate AS AVG(email_campaigns.open_rate_pct)
      COMMENT = 'Average email open rate',
    email_campaigns.avg_click_to_open_rate AS AVG(email_campaigns.click_to_open_rate_pct)
      COMMENT = 'Average click-to-open rate',
    email_campaigns.avg_bounce_rate AS AVG(email_campaigns.bounce_rate_pct)
      COMMENT = 'Average email bounce rate',
    channel_summary.total_channel_spend AS SUM(channel_summary.fact_channel_spend)
      COMMENT = 'Total spend across all channels',
    channel_summary.total_channel_conversions AS SUM(channel_summary.fact_channel_conversions)
      COMMENT = 'Total conversions across all channels',
    overall_roas AS CASE WHEN SUM(ad_performance.fact_spend) > 0 THEN SUM(ad_performance.fact_conversion_value) / SUM(ad_performance.fact_spend) ELSE NULL END
      COMMENT = 'Overall return on ad spend'
  )

  COMMENT = 'Marketing performance semantic view covering digital advertising (Google Ads, Meta), email campaigns (SFMC), and website traffic (Google Analytics) for the 9/11 Memorial & Museum'

  AI_SQL_GENERATION 'Round all numeric results to 2 decimal places. When comparing platforms, always include Google Ads, Facebook, and Instagram separately. Use fiscal_year for year-based groupings unless the user specifically asks for calendar year. For cross-channel comparisons, use the channel_summary entity. For email-only questions, use the email_campaigns entity.'

  AI_QUESTION_CATEGORIZATION 'This semantic view covers digital marketing, email campaigns, and website analytics. If the user asks about ticket sales revenue, retail sales, membership, or donor data, tell them to use the Museum Operations semantic view instead.';
