from pathlib import Path

import pandas as pd
import plotly.express as px
import streamlit as st

st.set_page_config(page_title="Manufacturing Defect Analytics", layout="wide")
st.title("Manufacturing Defect Detection Analytics Dashboard")

sample_defects = Path("data/samples/defects.csv")
sample_production = Path("data/samples/production.csv")

if not sample_defects.exists() or not sample_production.exists():
    st.error("Sample data not found. Expected data/samples/defects.csv and production.csv")
    st.stop()

defects = pd.read_csv(sample_defects)
production = pd.read_csv(sample_production)

defects["event_ts"] = pd.to_datetime(defects["event_ts"])
production["event_date"] = pd.to_datetime(production["event_date"])

factory_filter = st.sidebar.multiselect(
    "Factory",
    options=sorted(defects["factory_id"].dropna().unique().tolist()),
    default=sorted(defects["factory_id"].dropna().unique().tolist()),
)

line_filter = st.sidebar.multiselect(
    "Line",
    options=sorted(defects["line_id"].dropna().unique().tolist()),
    default=sorted(defects["line_id"].dropna().unique().tolist()),
)

filtered_defects = defects[
    defects["factory_id"].isin(factory_filter)
    & defects["line_id"].isin(line_filter)
]

filtered_prod = production[
    production["factory_id"].isin(factory_filter)
    & production["line_id"].isin(line_filter)
]

kpi_defects = filtered_defects["defect_count"].sum()
kpi_units = filtered_prod["units_produced"].sum()
kpi_rate = (kpi_defects / kpi_units) if kpi_units else 0

c1, c2, c3 = st.columns(3)
c1.metric("Total Defects", f"{int(kpi_defects):,}")
c2.metric("Total Units", f"{int(kpi_units):,}")
c3.metric("Defect Rate", f"{kpi_rate:.2%}")

defect_trend = (
    filtered_defects.assign(event_date=filtered_defects["event_ts"].dt.date)
    .groupby("event_date", as_index=False)["defect_count"]
    .sum()
)

fig_trend = px.line(defect_trend, x="event_date", y="defect_count", title="Daily Defect Trend")
st.plotly_chart(fig_trend, use_container_width=True)

pareto = filtered_defects.groupby("defect_type", as_index=False)["defect_count"].sum().sort_values("defect_count", ascending=False)
fig_pareto = px.bar(pareto, x="defect_type", y="defect_count", title="Defect Pareto")
st.plotly_chart(fig_pareto, use_container_width=True)

line_perf = filtered_defects.groupby("line_id", as_index=False)["defect_count"].sum()
fig_line = px.bar(line_perf, x="line_id", y="defect_count", title="Defects by Line")
st.plotly_chart(fig_line, use_container_width=True)
