"""Decode fixtures produced by the previous Git revision with current production models.

Uses isolated temporary files, never real user preferences or remote services.
HEAD is the available legacy baseline, not a verified App Store binary.
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MODELS = ['GarbageRegistModel', 'UserAddressRegistModel', 'NotificateModel', 'GarbageAreaConvModel']

def source(legacy=False):
    parts = ['import Foundation\nfunc saveUserID(_ value: String) {}']
    for name in MODELS:
        path = f'GarbageCalendar/Models/{name}.swift'
        parts.append(subprocess.check_output(['git', 'show', f'HEAD:{path}'], cwd=ROOT, text=True)
                     if legacy else (ROOT / path).read_text())
    return '\n'.join(parts)

writer = r'''
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
func save<T: Encodable>(_ value: T, _ name: String) throws {
    try JSONEncoder().encode(value).write(to: directory.appendingPathComponent(name))
}
var rules: [GarbageRegistModel] = []
for schedule in ["毎週", "隔週", "毎月", "第○曜日"] {
    var rule = GarbageRegistModel()
    rule.schedule = schedule
    rule.garbageType = "資源ゴミ"; rule.garbageInfoName = "引継ぎテスト"
    rule.yobi = "水曜日"; rule.day = 31; rule.weekOfMonth = "第三"
    rule.freqWeek = "三週に一回"; rule.strDate = "2026-10-07"
    rules.append(rule)
}
try save(rules, "garbageRegistModels")
let address = UserAddressRegistModel()
address.userId = "upgrade-test-user"; address.postalCode = "1000001"
address.administrativeArea = "東京都"; address.locality = "引継ぎ市"
address.buildName = "テスト棟"; address.latitude = "35.0"; address.longitude = "139.0"
try save(address, "userAddressRegistModel")
for enabled in [false, true] {
    for timing in NotificationTiming.allCases {
        let setting = NotificateModel(isNotificationEnabled: enabled, notificationTiming: timing)
        setting.notificateTime = Date(timeIntervalSince1970: 1792188900)
        try save(setting, "notification-\(enabled)-\(timing.rawValue)")
    }
}
try save(GarbageAreaConvModel(), "garbageAreaConvModel")
'''

reader = r'''
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
var count = 0
func verify<T: Codable>(_ type: T.Type, _ name: String) throws -> T {
    let data = try Data(contentsOf: directory.appendingPathComponent(name))
    let decoded = try JSONDecoder().decode(type, from: data)
    let original = try JSONSerialization.jsonObject(with: data) as AnyObject
    let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as AnyObject
    precondition((original as! NSObject).isEqual(encoded), "Changed legacy fields: \(name)")
    count += 1
    return decoded
}
let rules = try verify([GarbageRegistModel].self, "garbageRegistModels")
precondition(rules.count == 4)
precondition(rules.allSatisfy { $0.excludedDates == nil && $0.additionalDates == nil })
_ = try verify(UserAddressRegistModel.self, "userAddressRegistModel")
_ = try verify(GarbageAreaConvModel.self, "garbageAreaConvModel")
for enabled in [false, true] {
    for timing in NotificationTiming.allCases {
        let setting = try verify(NotificateModel.self, "notification-\(enabled)-\(timing.rawValue)")
        precondition(setting.isNotificationEnabled == enabled && setting.dateType == timing)
    }
}
print("PASS: \(count) legacy fixtures preserve all saved fields; four schedule types and notification ON/OFF × same/previous day")
'''

with tempfile.TemporaryDirectory(prefix='garbage-upgrade-') as folder:
    for name, code in [('legacy', source(True) + writer), ('current', source() + reader)]:
        path = Path(folder) / f'{name}.swift'
        path.write_text(code)
        subprocess.run(['xcrun', 'swift', str(path), folder], check=True, timeout=120)
