import os, re, json, glob
import xml.etree.ElementTree as ET
from collections import defaultdict, Counter

ROOT="pentaho_raw/Pentaho"
out={"trans":{}, "jobs":{}}
def txt(e): return (e.text or "").strip() if e is not None else ""

for f in sorted(glob.glob(ROOT+"/Transformations/*.ktr")):
    name=os.path.basename(f)[:-4]
    try: r=ET.parse(f).getroot()
    except Exception as ex:
        out["trans"][name]={"error":str(ex)}; continue
    d={"desc":"","conns":[],"steps":[],"sql":[],"tables_out":[],"tables_lookup":[],"files":[],"excel":[],"prpt":[]}
    info=r.find("info")
    if info is not None: d["desc"]=txt(info.find("description"))
    for c in r.findall("connection"):
        d["conns"].append(txt(c.find("name")))
    for s in r.findall("step"):
        stype=txt(s.find("type")); sname=txt(s.find("name")); conn=txt(s.find("connection"))
        d["steps"].append(stype)
        e=s.find("sql")
        if e is not None and txt(e):
            d["sql"].append({"step":sname,"type":stype,"conn":conn,"sql":txt(e)})
        lk=s.find("lookup")
        tbl=""; sch=""
        if lk is not None:
            tbl=txt(lk.find("table")); sch=txt(lk.find("schema"))
        if not tbl: tbl=txt(s.find("table")); sch=txt(s.find("schema"))
        if tbl:
            if stype in ("TableOutput","InsertUpdate","Update","Delete","DimensionLookup","CombinationLookup"):
                d["tables_out"].append({"schema":sch,"table":tbl,"step_type":stype,"conn":conn})
            elif stype in ("DBLookup",):
                d["tables_lookup"].append({"schema":sch,"table":tbl,"conn":conn})
        if stype=="TypeExitExcelWriterStep":
            fn=s.find("file")
            nm = txt(fn.find("name")) if fn is not None else ""
            ext = txt(fn.find("extention")) if fn is not None else ""
            sheet = txt(s.find("sheetname")) if s.find("sheetname") is not None else ""
            tmpl=""
            tf=s.find("template")
            if tf is not None: tmpl=txt(tf.find("filename"))
            d["excel"].append({"step":sname,"file":nm,"ext":ext,"sheet":sheet,"template":tmpl})
        if stype=="PentahoReportingOutput":
            d["prpt"].append({"step":sname,"input":txt(s.find("input_file")),"output":txt(s.find("output_file")),
                              "fmt":txt(s.find("output_processor_type"))})
    out["trans"][name]=d

for f in sorted(glob.glob(ROOT+"/Jobs/*.kjb")):
    name=os.path.basename(f)[:-4]
    try: r=ET.parse(f).getroot()
    except Exception as ex:
        out["jobs"][name]={"error":str(ex)}; continue
    d={"desc":txt(r.find("description")),"entries":[],"sql":[],"emails":[],"trans":[],"jobs":[]}
    ents=r.find("entries")
    if ents is not None:
        for e in ents.findall("entry"):
            et=txt(e.find("type")); en=txt(e.find("name"))
            rec={"type":et,"name":en}
            if et=="TRANS":
                tn=txt(e.find("transname")) or txt(e.find("filename"))
                rec["target"]=tn; d["trans"].append(tn)
            if et=="JOB":
                jn=txt(e.find("jobname")) or txt(e.find("filename"))
                rec["target"]=jn; d["jobs"].append(jn)
            if et=="MAIL":
                d["emails"].append({"name":en,"to":txt(e.find("destination")),
                  "cc":txt(e.find("destination_cc")),"subject":txt(e.find("subject"))})
            se=e.find("sql")
            if se is not None and txt(se): d["sql"].append({"entry":en,"sql":txt(se)})
            d["entries"].append(rec)
    out["jobs"][name]=d

json.dump(out, open("pentaho_parsed.json","w"), indent=1)

tt=Counter()
for n,v in out["trans"].items():
    for t in v.get("tables_out",[]): tt[(t["conn"],t["schema"],t["table"])]+=1
print("=== WRITE TARGETS ===", len(tt))
for k,v in sorted(tt.items()): print(f"  {v:3d}  conn={k[0]:14s} {k[1]}.{k[2]}" if k[1] else f"  {v:3d}  conn={k[0]:14s} {k[2]}")
