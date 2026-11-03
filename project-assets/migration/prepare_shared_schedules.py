"""Create unpublished v2 area candidates locally; never upload SQL or private users."""
import argparse
from collections import Counter
from decimal import Decimal, ROUND_HALF_UP
import json
import math
from pathlib import Path
from validate_export import rows


def normalize_rule(rule):
    value = {'garbageType': rule['garbageType'], 'schedule': rule['schedule']}
    kind = value['schedule']
    if kind in {'毎週', '隔週', '第○曜日'}:
        value['yobi'] = rule['yobi']
    if kind == '毎月':
        value['day'] = rule['day']
    if kind == '第○曜日':
        value['weekOfMonth'] = rule['weekOfMonth']
    if kind == '隔週':
        value.update(freqWeek=rule['freqWeek'], strDate=rule['date'][:10])
    return value


def prepare(source, output):
    prepared = Path(__file__).with_name('prepared')
    report = json.loads((prepared / 'semantic-report.json').read_text())
    if report['invalidGroupCount']:
        raise ValueError('Resolve semantic errors before preparing areas')
    groups = {g['legacyGroupId']: g for g in json.loads((prepared / 'schedule-candidates.json').read_text())}
    candidates, excluded = [], []
    for area in rows(source / 'TB_GARBAGE_AREA_CONV.sql'):
        group_id = str(area['garbageGroupId'])
        reason = None
        if group_id not in groups:
            reason = 'missing-or-quarantined-group'
        try:
            lat, lon = float(area['latitude']), float(area['longitude'])
            if not (20 <= lat <= 46 and 122 <= lon <= 154):
                reason = reason or 'invalid-japan-point'
        except (TypeError, ValueError):
            reason = reason or 'missing-point'
        # Use district labels rather than carrying potentially personal free-text names.
        name = ''.join(str(area.get(key) or '') for key in ['administrativeArea', 'locality', 'thoroughfare']).strip()
        if not name or len(name) > 80:
            reason = reason or 'invalid-district-label'
        if reason:
            excluded.append({'legacyAreaId': str(area['No']), 'reason': reason})
            continue
        lat, lon = [float(Decimal(str(v)).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)) for v in [lat, lon]]
        candidates.append({'id': 'legacy-area-' + str(area['No']), 'legacyGroupId': group_id,
            'name': name, 'latitude': lat, 'longitude': lon,
            'cell': f'{math.floor(lat*10)}:{math.floor(lon*10)}',
            'rules': [normalize_rule(r) for r in groups[group_id]['rules']],
            'status': 'pending-review', 'schemaVersion': 2, 'source': 'legacy-snapshot'})
    output.mkdir(parents=True, exist_ok=True)
    (output / 'shared-candidates.json').write_text(json.dumps(candidates, ensure_ascii=False, indent=2)+'\n')
    summary = {'candidateAreas': len(candidates), 'excludedAreas': len(excluded),
        'excludedReasons': dict(Counter(e['reason'] for e in excluded)), 'excluded': excluded,
        'published': 0, 'productionWrites': False,
        'requiresReview': ['district labels and approximate location', 'rule correctness for each district'],
        'privateUsersRead': False, 'legacyOfficialFlagsTrusted': False}
    (output / 'shared-report.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({k:v for k,v in summary.items() if k != 'excluded'}, ensure_ascii=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, default=Path.home() / 'Downloads')
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('prepared'))
    args = parser.parse_args()
    prepare(args.source, args.output)
