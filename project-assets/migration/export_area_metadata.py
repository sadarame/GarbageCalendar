"""Rebuild public registration metadata without reading user records."""
import argparse
import json
from pathlib import Path
from validate_export import rows

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
args = parser.parse_args()
metadata = {
    'legacy-area-' + str(area['No']): {
        # Owner designated all existing Saitama area records as admin on 2026-10-18.
        # Use the exported prefecture, not approximate coordinates or display names.
        'registrationSource': 'admin' if area.get('administrativeArea') == '埼玉県' else
            {'1': 'admin', '0': 'community'}.get(str(area.get('officialFlag')), 'unknown'),
        'legacyUsageCount': max(0, int(area.get('usageCount') or 0)),
    }
    for area in rows(args.source)
}
output = Path(__file__).resolve().parents[1] / 'GarbageCalendarAPI/firebase/functions/src/legacyAreaMetadata.ts'
output.write_text('// Registration origin and historical usage from the legacy area export. No user records.\n'
    + 'export const legacyAreaMetadata: Record<string, {registrationSource: string; legacyUsageCount: number}> = '
    + json.dumps(metadata, ensure_ascii=False, indent=2) + ';\n')
print(f'Exported {len(metadata)} area metadata records')
