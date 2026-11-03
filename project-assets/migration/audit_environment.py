"""Read-only production inventory; never prints tokens or API response bodies."""
import concurrent.futures
import json
from datetime import datetime
from zoneinfo import ZoneInfo
import subprocess
from pathlib import Path
PROJECT = 'garbagecalendar-1923d'
APP = '1:949074036020:ios:56cf288529d665d62e5161'

def main():
    token = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
    endpoints = {
        'project': f'https://firebase.googleapis.com/v1beta1/projects/{PROJECT}',
        'billing': f'https://cloudbilling.googleapis.com/v1/projects/{PROJECT}/billingInfo',
        'databases': f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases',
        'auth': f'https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config',
        'appAttest': f'https://firebaseappcheck.googleapis.com/v1/projects/{PROJECT}/apps/{APP}/appAttestConfig',
        'deviceCheck': f'https://firebaseappcheck.googleapis.com/v1/projects/{PROJECT}/apps/{APP}/deviceCheckConfig',
        'rules': f'https://firebaserules.googleapis.com/v1/projects/{PROJECT}/releases',
        'functions': f'https://cloudfunctions.googleapis.com/v2/projects/{PROJECT}/locations/-/functions',
    }
    def read(item):
        key,url=item
        try:
            response = subprocess.run(['curl','--silent','--show-error','--max-time','30','--config','-','--write-out','\n%{http_code}',url], input='header = '+json.dumps('Authorization: Bearer '+token)+('\nheader = '+json.dumps('X-Goog-User-Project: '+PROJECT) if key!='billing' else '')+'\n', text=True, capture_output=True, check=True).stdout
            body, code = response.rsplit('\n',1)
            if code != '200':
                error = json.loads(body).get('error', {})
                reasons = [d.get('reason') for d in error.get('details',[]) if d.get('reason')]
                return key, {'httpStatus':int(code),'status':error.get('status'),'reasons':reasons,'services':[{'service':d.get('metadata',{}).get('service'),'consumer':d.get('metadata',{}).get('consumer')} for d in error.get('details',[]) if d.get('reason')]} 
            data=json.loads(body)
            if key=='project': value={k:data.get(k) for k in ['projectId','projectNumber','state']}
            elif key=='billing': value={'billingEnabled':data.get('billingEnabled')}
            elif key=='databases': value={'databases':[{k:d.get(k) for k in ['name','locationId','type','deleteProtectionState']} for d in data.get('databases',[])]}
            elif key=='auth': value={'anonymousEnabled':data.get('signIn',{}).get('anonymous',{}).get('enabled',False)}
            elif key in ['appAttest','deviceCheck']: value={k:data.get(k) for k in ['name','tokenTtl']}
            elif key=='rules': value={'releases':[{k:r.get(k) for k in ['name','rulesetName']} for r in data.get('releases',[])]}
            else: value={'functions':[{k:f.get(k) for k in ['name','state','environment']} for f in data.get('functions',[])]}
            return key,{'httpStatus':200,**value}
        except Exception as e:
            return key,{'status':'unavailable','errorType':type(e).__name__}
    report={'checkedDate':datetime.now(ZoneInfo('Asia/Tokyo')).date().isoformat(),'projectId':PROJECT,'readOnly':True,'checks':dict(concurrent.futures.ThreadPoolExecutor(max_workers=6).map(read,endpoints.items()))}
    Path(__file__).with_name('audit').joinpath('environment.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
