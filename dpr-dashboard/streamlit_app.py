# Daily Performance Report dashboard with YoY comparisons

import os
import streamlit as st
import pandas as pd

st.set_page_config(page_title="DPR Dashboard", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

METRICS = {
    "Museum Attendance": "MUS_ATTENDANCE",
    "Ticket Revenue": "TICKET_REVENUE",
    "Pass Revenue": "PASS_REVENUE",
    "Guided Tour Revenue": "MUS_GUIDED_TOUR_REVENUE",
    "Field Trip Revenue": "MEM_FIELD_TRIP_REVENUE + MUS_FIELD_TRIP_REVENUE",
    "Audio Revenue": "MEM_AUDIO_GUIDE_REVENUE + AUDIO_TOUR_HEADSET",
    "Museum Store Profit": "MUS_STORE_GROSS_PROFIT",
    "Cafe Profit": "CAFE1_ALL_PROFIT",
    "Total Donations": (
        "TICKETING_DONATIONS + BOX_OFFICE_MEM_DON + BOX_OFFICE_MUS_EXIT_DON + "
        "COATCHECK_DON + MASK_DONATIONS + DONATION_BOX + MUS_STORE_DONATIONS + "
        "MUS_EXIT_DONATIONS + CART_DONATION_ASK + ECOM_DONATION_ASK + CAFE1_DONATIONS"
    ),
    "Service Fees": "SERVICE_FEES",
    "Tickets Sold": "TICKETS_SOLD",
    "Retail Carts Profit": "RETAIL_CARTS_GROSS_PROFIT",
}


@st.cache_data(ttl=600)
def load_dpr_data():
    metric_cols = ", ".join(
        [f"SUM({expr}) AS {name.replace(' ', '_').upper()}"
         for name, expr in METRICS.items()]
    )
    sql = f"""
        SELECT
            DATE_VALUE::DATE AS report_date,
            DAYNAME(DATE_VALUE) AS day_name,
            {metric_cols}
        FROM MARTS.FCT_DAILY_PERFORMANCE
        GROUP BY DATE_VALUE, DAYNAME(DATE_VALUE)
        ORDER BY DATE_VALUE
    """
    return conn.query(sql)


def format_metric(value, is_currency=True):
    if value is None or pd.isna(value):
        return "N/A"
    if is_currency:
        if abs(value) >= 1_000_000:
            return f"${value/1_000_000:.1f}M"
        elif abs(value) >= 1_000:
            return f"${value/1_000:.1f}K"
        return f"${value:,.0f}"
    else:
        if abs(value) >= 1_000_000:
            return f"{value/1_000_000:.1f}M"
        elif abs(value) >= 1_000:
            return f"{value/1_000:.1f}K"
        return f"{value:,.0f}"


def calc_delta(current, prior):
    if prior is None or prior == 0 or pd.isna(prior):
        return None
    return (current - prior) / prior * 100


df = load_dpr_data()

if df.empty:
    st.error("No data found in FCT_DAILY_PERFORMANCE.")
    st.stop()

df["REPORT_DATE"] = pd.to_datetime(df["REPORT_DATE"])

today = df["REPORT_DATE"].max()
yesterday = today
yesterday_ly = yesterday - pd.DateOffset(years=1)

current_month_start = yesterday.replace(day=1)
prior_year_month_start = current_month_start - pd.DateOffset(years=1)
prior_year_month_end = yesterday - pd.DateOffset(years=1)

ytd_start = yesterday.replace(month=1, day=1)
prior_ytd_start = ytd_start - pd.DateOffset(years=1)
prior_ytd_end = yesterday - pd.DateOffset(years=1)

# Filter data
df_yesterday = df[df["REPORT_DATE"] == yesterday]
df_yesterday_ly = df[df["REPORT_DATE"] == yesterday_ly]

df_mtd = df[(df["REPORT_DATE"] >= current_month_start) & (df["REPORT_DATE"] <= yesterday)]
df_mtd_ly = df[(df["REPORT_DATE"] >= prior_year_month_start) & (df["REPORT_DATE"] <= prior_year_month_end)]

df_ytd = df[(df["REPORT_DATE"] >= ytd_start) & (df["REPORT_DATE"] <= yesterday)]
df_ytd_ly = df[(df["REPORT_DATE"] >= prior_ytd_start) & (df["REPORT_DATE"] <= prior_ytd_end)]

# Header
st.title("Daily Performance Report")
st.caption(f"Data through **{yesterday.strftime('%B %d, %Y')}** ({df_yesterday['DAY_NAME'].iloc[0] if not df_yesterday.empty else ''})")

with st.sidebar:
    st.markdown("### Refresh")
    if st.button("Reload data", on_click=load_dpr_data.clear):
        st.rerun()

# Display metrics in 3 time periods
metric_names = list(METRICS.keys())
currency_metrics = [m for m in metric_names if m not in ("Museum Attendance", "Tickets Sold")]

tabs = st.tabs(["Yesterday", "Month to Date", "Year to Date"])

with tabs[0]:
    st.subheader(f"Yesterday — {yesterday.strftime('%a %b %d, %Y')}")
    cols = st.columns(4)
    for i, metric in enumerate(metric_names):
        col_key = metric.replace(" ", "_").upper()
        current_val = df_yesterday[col_key].sum() if not df_yesterday.empty else 0
        prior_val = df_yesterday_ly[col_key].sum() if not df_yesterday_ly.empty else None
        is_currency = metric in currency_metrics
        delta = calc_delta(current_val, prior_val)
        with cols[i % 4]:
            st.metric(
                label=metric,
                value=format_metric(current_val, is_currency),
                delta=f"{delta:+.1f}% vs LY" if delta is not None else "No LY data",
            )

with tabs[1]:
    st.subheader(f"Month to Date — {current_month_start.strftime('%B %Y')}")
    cols = st.columns(4)
    for i, metric in enumerate(metric_names):
        col_key = metric.replace(" ", "_").upper()
        current_val = df_mtd[col_key].sum() if not df_mtd.empty else 0
        prior_val = df_mtd_ly[col_key].sum() if not df_mtd_ly.empty else None
        is_currency = metric in currency_metrics
        delta = calc_delta(current_val, prior_val)
        with cols[i % 4]:
            st.metric(
                label=metric,
                value=format_metric(current_val, is_currency),
                delta=f"{delta:+.1f}% vs LY" if delta is not None else "No LY data",
                border=True,
            )

with tabs[2]:
    st.subheader(f"Year to Date — {ytd_start.strftime('%Y')}")
    cols = st.columns(4)
    for i, metric in enumerate(metric_names):
        col_key = metric.replace(" ", "_").upper()
        current_val = df_ytd[col_key].sum() if not df_ytd.empty else 0
        prior_val = df_ytd_ly[col_key].sum() if not df_ytd_ly.empty else None
        is_currency = metric in currency_metrics
        delta = calc_delta(current_val, prior_val)
        with cols[i % 4]:
            st.metric(
                label=metric,
                value=format_metric(current_val, is_currency),
                delta=f"{delta:+.1f}% vs LY" if delta is not None else "No LY data",
                border=True,
            )

# Daily trend chart
st.divider()
st.subheader("Daily Trend")
chart_metric = st.selectbox("Select metric", metric_names, index=0)
chart_col = chart_metric.replace(" ", "_").upper()

chart_df = df[["REPORT_DATE", chart_col]].copy()
chart_df = chart_df.rename(columns={"REPORT_DATE": "Date", chart_col: chart_metric})
st.line_chart(chart_df, x="Date", y=chart_metric)
