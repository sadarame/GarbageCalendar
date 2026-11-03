"""Prepare local schedule-only candidates; never connect to or write a database.
Missing-reference groups are quarantined as a whole, never silently truncated.
"""
import json
from pathlib import Path
from validate_export import rows

source=Path.home()/'Downloads'
rules={str(r['id']):r for r in rows(source/'TB_GARBAGE_INFO.sql')}
groups={}
for row in rows(source/'TB_GARBAGE_GROUP.sql'):
    groups.setdefault(str(row['garbageGroupId']),set()).add(str(row['garbageId']))
valid=[]
quarantine=[]
for group_id, ids in sorted(groups.items(),key=lambda item:int(item[0])):
    missing=sorted(ids-rules.keys())
    if missing:
        quarantine.append({'legacyGroupId':group_id,'reason':'missing-rules','missingRuleIds':missing})
    else:
        valid.append({'id':'legacy-'+group_id,'legacyGroupId':group_id,'schemaVersion':1,
                      'status':'pending-semantic-validation',
                      'rules':[rules[i] for i in sorted(ids,key=int)]})
out=Path(__file__).with_name('prepared');out.mkdir(exist_ok=True)
(out/'schedule-candidates.json').write_text(json.dumps(valid,ensure_ascii=False,indent=2)+'\n')
(out/'quarantine.json').write_text(json.dumps(quarantine,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'candidateSchedules':len(valid),'quarantinedSchedules':len(quarantine),'productionWrites':False}))
