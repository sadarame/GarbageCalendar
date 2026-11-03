"""Read phpMyAdmin SQL as data, never execute it. Output aggregate validation only."""
import argparse
import json
import re
from pathlib import Path

TOKEN = re.compile(r"\s*(?:(?P<string>'(?:[^'\\]|\\.|'')*')|(?P<null>NULL)\b|(?P<number>-?\d+(?:\.\d+)?)|(?P<punct>[(),;]))", re.S)

def rows(path):
    text = path.read_text()
    result = []
    for insert in re.finditer(r'INSERT INTO `[^`]+`\s*\(([^)]+)\)\s*VALUES\s*', text):
        columns = re.findall(r'`([^`]+)`', insert[1])
        position = insert.end()
        row = None
        while True:
            token = TOKEN.match(text, position)
            if not token:
                raise ValueError(f'Unsupported SQL literal in {path.name} at {position}')
            position = token.end()
            kind = token.lastgroup
            value = token[kind]
            if kind == 'punct':
                if value == ';':
                    break
                if value == '(':
                    row = []
                elif value == ')':
                    if row is None or len(row) != len(columns):
                        raise ValueError(f'Column mismatch in {path.name}')
                    result.append(dict(zip(columns, row)))
                    row = None
            elif row is None:
                raise ValueError('Value outside row')
            else:
                if kind == 'string':
                    value = re.sub(r"\\(.)", lambda m: {'n':'\n','r':'\r','t':'\t','0':'\0'}.get(m[1],m[1]), value[1:-1].replace("''", "'"))
                elif kind == 'null':
                    value = None
                else:
                    value = float(value) if '.' in value else int(value)
                row.append(value)
    return result


def validate(directory):
    names = ['TB_GARBAGE_AREA_CONV', 'TB_GARBAGE_GROUP', 'TB_GARBAGE_INFO', 'TB_USER_INFO']
    data = {n: rows(directory / (n + '.sql')) for n in names}
    rules = {str(r['id']) for r in data['TB_GARBAGE_INFO']}
    groups = {str(r['garbageGroupId']) for r in data['TB_GARBAGE_GROUP']}
    missing_rules = sorted({str(r['garbageId']) for r in data['TB_GARBAGE_GROUP']} - rules)
    missing_area_groups = sorted({str(r['garbageGroupId']) for r in data['TB_GARBAGE_AREA_CONV']} - groups)
    missing_user_groups = sorted({str(r['garbage_group_id']) for r in data['TB_USER_INFO'] if r['garbage_group_id']} - groups)
    frequencies = {}
    for r in data['TB_GARBAGE_INFO']:
        label = str(r['schedule'])
        frequencies[label] = frequencies.get(label, 0) + 1
    return {
        'rowCounts': {name: len(items) for name, items in data.items()},
        'distinctGroups': len(groups),
        'missingRuleIds': missing_rules,
        'missingAreaGroupIds': missing_area_groups,
        'missingUserGroupIds': missing_user_groups,
        'scheduleCounts': frequencies,
        'readyForRelationshipImport': not (missing_rules or missing_area_groups),
        'privateUserImport': False,
        'productionWrites': False,
        'note': 'Relationship validation only; rule semantics and privacy review remain. User row count is not active-user count.'
    }

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, default=Path.home() / 'Downloads')
    parser.add_argument('--output', type=Path, default=Path(__file__).with_name('validation-report.json'))
    args = parser.parse_args()
    report = validate(args.source)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False, indent=2))
