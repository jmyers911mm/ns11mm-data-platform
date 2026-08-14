import json, re
from collections import defaultdict, deque
d=json.load(open("pentaho_parsed.json")); T=d["trans"]
prpt=json.load(open("prpt_tables.json"))

writers=defaultdict(set)
for n,v in T.items():
    for t in v.get("tables_out",[]): writers[t["table"].lower()].add(n)

pat=re.compile(r'\b(?:from|join)\s+([`"\[]?[\w\.\$#]+[`"\]]?)', re.I)
def reads(n):
    v=T.get(n,{}); out=set()
    for s in v.get("sql",[]):
        for m in pat.findall(re.sub(r'--.*','',s["sql"])):
            t=m.strip('`"[]').split('.')[-1].lower()
            if t not in ('select','(','dual','$'): out.add((s["conn"] or "?", t))
    for t in v.get("tables_lookup",[]): out.add((t["conn"], t["table"].lower()))
    return out

SEEDS = {
 "Today's Sales Report": ["t_todays_sales_report_verification","t_fact_todays_retail_data"],
 "Retail Performance Report": ["t_rpt_retail"],
 "Retail Carts Analysis Report": ["t_retail_cart_analysis_tabs"],
 "Monthly Retail KPI": ["t_rpt_monthly_retail_kpi"],
 "Attendance Report": ["t_attendance_values_excel","t_fact_attendance_all_locations"],
 "Earned Income Variance Report": ["t_earned_income_variance_tabs","t_fact_earned_income_variance_values_table","t_fact_guided_tours_earned_income_variance","t_fact_citypass_c3_earned_income_variance","t_fact_earned_income_variance_revenue_table","t_fact_earned_income_variance_totals_table","t_fact_earned_income_variance_avg_ticket","t_fact_earned_income_variance_values_excel"],
 "M&M Daily Tracker - YTD": ["t_rpt_tracker_ytd_verification"],
 "Daily Performance Report - New": ["t_rpt_daily_performance"],
 "Blue State WiFi Export": ["t_bluestate_write_to_excel","t_wifi_data_load","t_wifi_save_daily_data_dpr"],
 "DPR Excel Data": ["t_dpr_write_to_excel","t_dpr_excel_data_update"],
 "Website Commerce Report": ["t_website_commerce_report_excel"],
 "Donations Analysis Report": ["t_fact_donations_analysis_report","t_donations_analysis_tabs"],
 "Retail Analysis Report": ["t_retail_analysis_tabs"],
 "Daily Performance Report - YTD": ["t_rpt_finance_ytd_dpr"],
 "Daily Performance Report - MTD": ["t_rpt_finance_mtd_dpr"],
 "Daily Scan Report": ["t_daily_scan_report","t_fact_dailyscan_data"],
 "Daily Attendance Report": ["t_rpt_daily_attendance_union"],
}
q=deque(n for v in SEEDS.values() for n in v)
# seed from prpt-referenced tables too
for r,tbls in prpt.items():
    for t in tbls: q.extend(writers.get(t,()))

live=set(); tabs=defaultdict(set)
while q:
    n=q.popleft()
    if n in live or n not in T: continue
    live.add(n)
    for conn,tbl in reads(n):
        tabs[conn].add(tbl)
        if conn in ("911DW","?",""):
            q.extend(w for w in writers.get(tbl,()) if w not in live)

dead=sorted(set(T)-live)
print(f"LIVE transformations: {len(live)}/{len(T)}   DEAD: {len(dead)}")
print("\n=== SOURCE SYSTEMS still in scope ===")
for c in sorted(tabs):
    if c in ("911DW","?",""): continue
    print(f"  {c:16s} {sorted(tabs[c])}")
print("\n=== SOURCE SYSTEMS now OUT of scope ===")
allconn=set()
for n,v in T.items():
    for s in v.get("sql",[]): allconn.add(s["conn"])
for c in sorted(allconn-set(tabs)):
    if c: print("  ",c)
print(f"\n=== DEAD transformations ({len(dead)}) ===")
for t in dead: print("  ",t)
json.dump({"live":sorted(live),"dead":dead,"tabs":{k:sorted(v) for k,v in tabs.items()}}, open("closure2.json","w"), indent=1)
