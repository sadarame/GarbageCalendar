"""Validate schedule semantics locally; output only IDs and error categories."""
import json
from datetime import datetime
from pathlib import Path

root = Path(__file__).parent / 'prepared'
items = json.loads((root / 'schedule-candidates.json').read_text())
weekdays = {'日曜日','月曜日','火曜日','水曜日','木曜日','金曜日','土曜日'}
ordinals = {'第一','第二','第三','第四','第五'}
types = {'燃えるゴミ','燃えないゴミ','プラスチック','ビン・カン','ペットボトル','古紙','ダンボール','資源ゴミ','粗大ごみ','危険・有害','繊維'}
accepted, rejected = [], []
for group in items:
    errors = []
    for rule in group['rules']:
        kind = rule['schedule']
        reasons = []
        if rule['garbageType'] not in types: reasons.append('unsupported-type')
        if kind not in {'毎週','隔週','毎月','第○曜日'}: reasons.append('unsupported-schedule')
        if kind in {'毎週','隔週','第○曜日'} and rule['yobi'] not in weekdays: reasons.append('invalid-weekday')
        if kind == '毎月' and (not isinstance(rule['day'], int) or not 1 <= rule['day'] <= 31): reasons.append('invalid-day')
        if kind == '第○曜日' and rule['weekOfMonth'] not in ordinals: reasons.append('invalid-ordinal')
        if kind == '隔週':
            if rule['freqWeek'] not in {'二週に一回','三週に一回','四週に一回'}: reasons.append('invalid-interval')
            try: datetime.strptime(rule['date'], '%Y-%m-%d %H:%M:%S')
            except (TypeError, ValueError): reasons.append('invalid-anchor-date')
        if reasons: errors.append({'ruleId': rule['id'], 'reasons': reasons})
    if errors: rejected.append({'groupId': group['legacyGroupId'], 'errors': errors})
    else: accepted.append(group['legacyGroupId'])
report = {'validGroupCount':len(accepted), 'invalidGroupCount':len(rejected), 'invalidGroups':rejected,
          'productionWrites':False, 'note':'Validates supported rule values only; not approval to publish private locations or user data.'}
(root / 'semantic-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k != 'invalidGroups'},ensure_ascii=False))
