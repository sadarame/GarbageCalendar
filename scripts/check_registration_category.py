"""Decode old/new search responses and verify master/user grouping."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'GarbageCalendar/Models/GarbageAreaConvModel.swift').read_text()
source += r'''
let cases: [(String, ScheduleRegistrationCategory)] = [
    (#"{"registrationSource":"admin","officialFlag":"0"}"#, .master),
    (#"{"registrationSource":"community"}"#, .community),
    (#"{"registrationSource":"community","officialFlag":"1"}"#, .community),
    (#"{"registrationSource":"unknown"}"#, .community),
    (#"{"registrationSource":"unknown","officialFlag":"1"}"#, .community),
    (#"{"registrationSource":""}"#, .community),
    (#"{"officialFlag":"1"}"#, .master),
    (#"{"officialFlag":"0"}"#, .community),
    (#"{"officialFlag":null}"#, .community),
    (#"{}"#, .community)
]
precondition(ScheduleRegistrationCategory.allCases.map(\.rawValue) == ["運営が登録した収集日", "利用者が登録した収集日"])
for (json, expected) in cases {
    let model = try JSONDecoder().decode(GarbageAreaConvModel.self, from: Data(json.utf8))
    precondition(model.registrationCategory == expected, json)
    let restored = try JSONDecoder().decode(GarbageAreaConvModel.self, from: JSONEncoder().encode(model))
    precondition(restored.registrationCategory == expected, json)
    precondition(restored.registrationSource == model.registrationSource, "Do not rewrite stored provenance")
}
print("PASS: master/user categories for \(cases.count) current and legacy responses")
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / 'RegistrationCategory.swift'
    path.write_text(source)
    subprocess.run(['xcrun', 'swift', str(path)], check=True)
