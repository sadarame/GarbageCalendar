"""Regression checks for local collection names visible in the reported screenshots."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
style = (root / 'Shared/CollectionStyle.swift').read_text()
start = style.index('    static let iconTypes')
end = style.index('    static func color')
source = (root/'GarbageCalendar/Models/GarbageRegistModel.swift').read_text() + '\n' + (root/'Shared/ScheduleEngine.swift').read_text() + '\nenum CollectionStyle {\n' + style[start:end] + '\n}\n'
source += r'''
precondition(CollectionStyle.displayType("資源物2類", iconType: "古紙") == "古紙")
precondition(CollectionStyle.displayType("資源物2類", iconType: nil) == "資源物2類")
precondition(CollectionStyle.displayType("可燃ごみ", iconType: "unknown") == "可燃ごみ")
var monday = GarbageRegistModel()
monday.garbageType = "資源物2類"
monday.yobi = "月曜日"
monday.iconType = "古紙"
var tuesday = monday
tuesday.yobi = "火曜日"
tuesday.iconType = "繊維"
let date = ISO8601DateFormatter().date(from: "2026-10-19T00:00:00Z")!
precondition(CollectionStyle.iconType(for: "資源物2類", on: date, models: [tuesday, monday]) == "古紙")
let known = [
    ("もえるごみ", "gomi_mark01_moeru", "flame.fill"),
    ("もえないごみ", "gomi_mark02_moenai", "trash.fill"),
    ("可燃ごみ", "gomi_mark01_moeru", "flame.fill"),
    ("不燃ごみ", "gomi_mark02_moenai", "trash.fill"),
    ("燃えるゴミ", "gomi_mark01_moeru", "flame.fill"),
    (" 粗大ごみ ", "gomi_mark08_sodai", "sofa.fill")
]
for (name, asset, symbol) in known {
    precondition(CollectionStyle.asset(name) == asset, name)
    precondition(CollectionStyle.symbol(name) == symbol, name)
}
// Preserve each municipality's category label without guessing its materials.
for name in ["資源物1類", "資源物2類", "資源物１類", "資源物２類"] {
    precondition(CollectionStyle.normalizedType(name) == name)
    precondition(CollectionStyle.asset(name) == "gomi_mark13_blank")
    precondition(CollectionStyle.symbol(name) == "arrow.3.trianglepath")
}
precondition(CollectionStyle.symbol("地域独自の区分") == "trash.fill")
print("PASS: screenshot collection names, numbered resources and unknown-name fallback")
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / 'Icons.swift'
    path.write_text(source)
    subprocess.run(['xcrun', 'swift', str(path)], check=True)
