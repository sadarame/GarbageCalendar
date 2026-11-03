"""Production smoke test with a temporary Auth user and temporary App Check debug token.
No public schedules or enabled notifications are created. Test resources are removed.
"""
import json, plistlib, subprocess, uuid
from pathlib import Path
PROJECT='garbagecalendar-1923d'
BASE=f'https://asia-northeast1-{PROJECT}.cloudfunctions.net/'
ROOT=Path(__file__).resolve().parents[1]

def main():
    settings=plistlib.loads((ROOT/'GarbageCalendar/GarbageCalendar/GoogleService-Info.plist').read_bytes())
    app=settings['GOOGLE_APP_ID']; key=settings['API_KEY']
    access=subprocess.check_output(['gcloud','auth','print-access-token'],text=True).strip()
    def request(method,url,data=None,headers=None,admin=False):
        config='url = '+json.dumps(url)+'\nrequest = '+json.dumps(method)+'\n'
        hs={'Content-Type':'application/json',**(headers or {})}
        if admin: hs.update({'Authorization':'Bearer '+access,'X-Goog-User-Project':PROJECT})
        for k,v in hs.items(): config+='header = '+json.dumps(k+': '+v)+'\n'
        if data is not None: config+='data = '+json.dumps(json.dumps(data))+'\n'
        raw=subprocess.run(['curl','--silent','--show-error','--max-time','60','--config','-','--write-out','\n%{http_code}'],input=config,text=True,capture_output=True,check=True).stdout
        body,status=raw.rsplit('\n',1)
        return int(status),json.loads(body or '{}')
    result={'project':PROJECT,'checks':{},'cleanup':{}}
    debug_name=None; identity=None
    def check(label,condition):
        result['checks'][label]=bool(condition)
        if not condition: raise RuntimeError('Failed check: '+label)
    try:
        token=str(uuid.uuid4())
        code,data=request('POST',f'https://firebaseappcheck.googleapis.com/v1/projects/{PROJECT}/apps/{app}/debugTokens',{'displayName':'Temporary deployment smoke test','token':token},admin=True)
        check('temporaryAppCheckRegistration',code==200)
        debug_name=data['name']
        code,data=request('POST',f'https://firebaseappcheck.googleapis.com/v1/projects/{PROJECT}/apps/{app}:exchangeDebugToken?key={key}',{'debugToken':token})
        check('appCheckTokenExchange',code==200)
        app_token=data['token']
        code,identity=request('POST',f'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={key}',{'returnSecureToken':True})
        check('anonymousAuthentication',code==200)
        headers={'Authorization':'Bearer '+identity['idToken'],'X-Firebase-AppCheck':app_token}
        code,data=request('POST',BASE+'searchSharedSchedulesV2',{'data':{'latitude':35.68,'longitude':139.76}})
        check('missingCredentialsRejected',code==401)
        code,data=request('POST',BASE+'searchSharedSchedulesV2',{'data':{'latitude':35.68,'longitude':139.76}},headers={'X-Firebase-AppCheck':app_token})
        check('missingAuthRejected',code==401)
        sample=json.loads((ROOT/'migration/prepared/shared-candidates.json').read_text())[0]
        code,data=request('POST',BASE+'searchSharedSchedulesV2',{'data':{'latitude':sample['latitude'],'longitude':sample['longitude']}},headers=headers)
        check('authenticatedSearchHidesPendingImports',code==200 and data['result']['result']==[])
        code,data=request('POST',BASE+'getSharedScheduleV2',{'data':{'id':sample['id']}},headers=headers)
        check('pendingDocumentNotReadable',code==404)
        code,data=request('POST',BASE+'saveSharedScheduleV2',{'data':{'name':'smoke','latitude':35.68,'longitude':139.76,'rules':[]}},headers=headers)
        check('invalidSharedWriteRejected',code==400)
        code,data=request('POST',BASE+'unpublishSharedScheduleV2',{'data':{}},headers=headers)
        check('withdrawAbsentContributionIsSafe',code==200)
        code,data=request('POST',BASE+'saveNotificationSettingsV2',{'data':{'settings':{'enabled':False,'previousDay':False,'hour':7,'minute':0,'timeZone':'Asia/Tokyo'},'rules':[{'garbageType':'燃えるゴミ','schedule':'毎週','yobi':'火曜日','excludedDates':['2026-10-13'],'additionalDates':['2026-10-14']}]}},headers=headers)
        check('notificationOffAccepted',code==200 and data['result']['nextNotificationAt'] is None)
        code,saved=request('GET',f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/v2NotificationSubscriptions/{identity["localId"]}',admin=True)
        fields=saved.get('fields',{}).get('rules',{}).get('arrayValue',{}).get('values',[{}])[0].get('mapValue',{}).get('fields',{})
        check('exceptionDatesPersisted',code==200 and fields.get('excludedDates',{}).get('arrayValue',{}).get('values')==[{'stringValue':'2026-10-13'}] and fields.get('additionalDates',{}).get('arrayValue',{}).get('values')==[{'stringValue':'2026-10-14'}])
        code,_=request('GET',f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/v2SharedSchedules/{sample["id"]}',headers={'Authorization':'Bearer '+identity['idToken']})
        check('directFirestoreReadDenied',code==403)
    finally:
        if identity and identity.get('localId'):
            code,_=request('DELETE',f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/v2NotificationSubscriptions/{identity["localId"]}',admin=True)
            result['cleanup']['testSubscriptionRemoved']=code in [200,404]
            code,_=request('POST',f'https://identitytoolkit.googleapis.com/v1/accounts:delete?key={key}',{'idToken':identity['idToken']})
            result['cleanup']['testAuthUserRemoved']=code==200
        if debug_name:
            code,_=request('DELETE',f'https://firebaseappcheck.googleapis.com/v1/{debug_name}',admin=True)
            result['cleanup']['temporaryAppCheckTokenRemoved']=code==200
        (ROOT/'migration/audit/production-smoke.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps(result))
    if not all(result['cleanup'].values()): raise RuntimeError('Test cleanup incomplete')

if __name__=='__main__': main()
