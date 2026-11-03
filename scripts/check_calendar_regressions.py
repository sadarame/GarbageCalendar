"""Exercise production models and ScheduleEngine using the installed Swift compiler."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/'GarbageCalendar/Models/GarbageRegistModel.swift').read_text()+'\n'+(root/'Shared/ScheduleEngine.swift').read_text()
source+='''
let cal = ScheduleEngine.calendar
func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
    cal.date(from: DateComponents(year:y, month:m, day:d, hour:h))!
}
var count = 0
func check(_ value: Bool) { precondition(value); count += 1 }
var model = GarbageRegistModel()
model.schedule = "第○曜日"
for year in [2024,2025] {
 for month in 1...12 {
  for day in cal.range(of: .day, in: .month, for: date(year,month,1))! {
   for (weekday,name) in ScheduleEngine.weekdays.enumerated() {
    model.yobi = name
    for (ordinal,label) in ScheduleEngine.ordinals.enumerated() {
     model.weekOfMonth = label
     check(ScheduleEngine.matches(model,on:date(year,month,day)) ==
       (cal.component(.weekday,from:date(year,month,day)) == weekday+1 && (day-1)/7 == ordinal))
    }
   }
  }
 }
}
model.schedule = "隔週"
model.yobi = "月曜日"
model.strDate = "2025-12-29"
for (label,weeks) in [("二週に一回",2),("三週に一回",3),("四週に一回",4)] {
 model.freqWeek = label
 for offset in -30...120 {
  let d=cal.date(byAdding:.day,value:offset,to:date(2025,12,29))!
  check(ScheduleEngine.matches(model,on:d) == (offset >= 0 && offset % (weeks*7) == 0))
 }
}
model.yobi = "水曜日"; model.freqWeek = "二週に一回"
check(ScheduleEngine.matches(model,on:date(2025,12,31)))
check(!ScheduleEngine.matches(model,on:date(2026,1,7)))
check(ScheduleEngine.matches(model,on:date(2026,1,14)))
model.schedule = "毎月"; model.day = 31
check(!ScheduleEngine.matches(model,on:date(2026,2,28)))
check(ScheduleEngine.matches(model,on:date(2026,3,31)))
model.day = 1
let reminders=ScheduleEngine.reminders(models:[model,model],after:date(2025,12,30),previousDay:true,hour:7,minute:15)
check(reminders.first!.date == cal.date(byAdding:.minute,value:15,to:date(2025,12,31,7))!)
check(reminders.first!.types.count == 1)
model.schedule = "毎週"; model.yobi = "日曜日"
let weekly=ScheduleEngine.reminders(models:[model],after:date(2026,1,1),previousDay:true,hour:7,minute:0,limit:5)
check(weekly.count == 5)
for item in weekly { check(cal.component(.weekday,from:item.date) == 7);check(cal.component(.hour,from:item.date) == 7) }
check(ScheduleEngine.reminders(models:[model],after:date(2026,1,1),previousDay:false,hour:25,minute:0).isEmpty)
model.schedule = "指定日のみ"
model.specificDates = ["2026-05-16", "2026-11-07"]
check(ScheduleEngine.matches(model,on:date(2026,5,16)))
check(ScheduleEngine.matches(model,on:date(2026,11,7)))
check(!ScheduleEngine.matches(model,on:date(2026,5,23)))
check(!ScheduleEngine.matches(model,on:date(2027,5,16)))
model.validFrom = "2026-04-01"; model.validTo = "2026-10-31"
check(!ScheduleEngine.matches(model,on:date(2026,11,7)))
model.schedule = "毎週"; model.yobi = "木曜日"
model.validTo = "2027-03-31"
model.excludedDates = ["2026-12-31"]; model.additionalDates = ["2026-12-28", "2027-04-01"]
check(!ScheduleEngine.matches(model,on:date(2026,12,31)))
check(ScheduleEngine.matches(model,on:date(2026,12,28)))
check(!ScheduleEngine.matches(model,on:date(2027,4,1)))
print("PASS: \\(count) production schedule checks")
'''
with tempfile.TemporaryDirectory() as folder:
 p=Path(folder)/'Regression.swift';p.write_text(source)
 subprocess.run(['xcrun','swift',str(p)],check=True)
