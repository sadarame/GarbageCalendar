"""Flag ambiguous and repeated imported schedules without claiming official accuracy."""
from collections import defaultdict
import hashlib
import json
from datetime import datetime
from zoneinfo import ZoneInfo
from pathlib import Path
root=Path(__file__).with_name('prepared')
items=json.loads((root/'shared-candidates.json').read_text())
def fingerprint(rules):
    # Schedule order and duplicate rules do not change the set of collection days.
    return hashlib.sha256(json.dumps(sorted({json.dumps(r,sort_keys=True,ensure_ascii=False) for r in rules}),ensure_ascii=False).encode()).hexdigest()
by_label=defaultdict(list)
by_exact=defaultdict(list)
repeated_rules=[]
for item in items:
    signature=fingerprint(item['rules'])
    by_label[item['name']].append((item['id'],signature))
    by_exact[(item['name'],item['latitude'],item['longitude'],signature)].append(item['id'])
    encoded=[json.dumps(r,sort_keys=True) for r in item['rules']]
    if len(set(encoded))!=len(encoded): repeated_rules.append(item['id'])
ambiguous=[{'ids':[i for i,_ in values],'ruleVariants':len({s for _,s in values})} for values in by_label.values() if len({s for _,s in values})>1]
duplicates=[ids for ids in by_exact.values() if len(ids)>1]
report={'checkedDate':datetime.now(ZoneInfo('Asia/Tokyo')).date().isoformat(),'candidateCount':len(items),'sameDistrictDifferentRules':len(ambiguous),'affectedAreaCount':sum(len(g['ids']) for g in ambiguous),'exactDuplicateSets':len(duplicates),'redundantAreaCount':sum(len(g)-1 for g in duplicates),'areasWithRepeatedRules':len(repeated_rules),'ambiguities':ambiguous,'duplicates':duplicates,'repeatedRuleAreaIds':repeated_rules,'publicationsApproved':0,'note':'Differences may be legitimate subdistricts. Compare each district with authoritative collection information before publishing; no automatic deduplication or rule correction.'}
(root/'publication-review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['ambiguities','duplicates','repeatedRuleAreaIds']},ensure_ascii=False))
