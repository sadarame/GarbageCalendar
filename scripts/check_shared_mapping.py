"""Exercise production Swift decoding and schedule mapping in multiple time zones."""
from pathlib import Path
import os
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root/'GarbageCalendar/Models/GarbageRegistModel.swift').read_text()
source += '\n' + (root/'Shared/ScheduleEngine.swift').read_text()
api = (root/'GarbageCalendar/ViewModel/baseVM.swift').read_text()
start = api.index('struct SharedRule:')
# Stop at this struct's closing brace; later declarations have app-only dependencies.
opening = api.index('{', start)
depth = 1
end = opening + 1
while depth:
    depth += (api[end] == '{') - (api[end] == '}')
    end += 1
source += '\n' + api[start:end]
source += r'''
let json = """
[
 {"garbageType":"燃えるゴミ","schedule":"毎週","yobi":"日曜日"},
 {"garbageType":"古紙","schedule":"毎月","day":31},
 {"garbageType":"資源ゴミ","schedule":"第○曜日","yobi":"火曜日","weekOfMonth":"第三"},
 {"garbageType":"ビン・カン","schedule":"隔週","yobi":"月曜日","freqWeek":"三週に一回","strDate":"2026-10-05"}
]
"""
let rules = try JSONDecoder().decode([SharedRule].self, from: Data(json.utf8))
let models = rules.map { $0.model() }
precondition(models[0].iconType == nil)
let customJSON = """
{"garbageType":"資源物2類","iconType":"古紙","schedule":"毎週","yobi":"月曜日"}
"""
let custom = try JSONDecoder().decode(SharedRule.self, from: Data(customJSON.utf8)).model()
precondition(custom.garbageType == "資源物2類" && custom.iconType == "古紙")
let restored = try JSONDecoder().decode(GarbageRegistModel.self, from: JSONEncoder().encode(custom))
precondition(restored.iconType == "古紙")
let f = DateFormatter()
f.calendar = ScheduleEngine.calendar
f.timeZone = ScheduleEngine.calendar.timeZone
f.dateFormat = "yyyy-MM-dd"
precondition(ScheduleEngine.matches(models[0], on: f.date(from:"2026-10-11")!))
precondition(ScheduleEngine.matches(models[1], on: f.date(from:"2026-10-31")!))
precondition(models[2].weekOfMonth == "第三")
precondition(ScheduleEngine.matches(models[2], on: f.date(from:"2026-10-20")!))
precondition(models[3].strDate == "2026-10-05")
precondition(models[3].freqWeek == "三週に一回")
precondition(ScheduleEngine.matches(models[3], on: f.date(from:"2026-10-26")!))
precondition(!ScheduleEngine.matches(models[3], on: f.date(from:"2026-10-12")!))
let local = DateFormatter()
local.calendar = Calendar(identifier: .gregorian)
local.timeZone = .current
local.dateFormat = "yyyy-MM-dd"
precondition(local.string(from: models[3].date) == "2026-10-05")
print("PASS: shared schedule decoding and mapping")
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder)/'SharedMapping.swift'
    path.write_text(source)
    for zone in ['Asia/Tokyo', 'America/Los_Angeles', 'Pacific/Auckland']:
        subprocess.run(['xcrun', 'swift', '-module-cache-path', '/private/tmp/garbage-swift-module-cache', str(path)], env={**os.environ, 'TZ':zone}, check=True)
