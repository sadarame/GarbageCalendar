#!/usr/bin/env python3
"""Check privacy resources in the actual release .app, not just source files."""
import plistlib
import sys
from pathlib import Path

app = Path(sys.argv[1])
assert app.is_dir() and app.suffix == '.app', 'Pass an archived or exported .app'
# Relevant SDK names from https://developer.apple.com/support/third-party-SDK-requirements/
required = {
    'FBLPromises', 'FirebaseAuth', 'FirebaseCore', 'FirebaseCoreExtension',
    'FirebaseCoreInternal', 'FirebaseInstallations', 'FirebaseMessaging',
    'GoogleDataTransport', 'GoogleUtilities', 'GTMSessionFetcher', 'nanopb',
}
errors = []
manifests = list(app.rglob('PrivacyInfo.xcprivacy'))
for path in manifests:
    try:
        data = plistlib.loads(path.read_bytes())
        assert isinstance(data, dict)
        for entry in data.get('NSPrivacyAccessedAPITypes', []):
            assert entry['NSPrivacyAccessedAPITypeReasons']
    except Exception as error:
        errors.append(f'Invalid manifest {path.relative_to(app)}: {error}')
for framework in (app / 'Frameworks').glob('*.framework'):
    if framework.stem in required and not list(framework.rglob('PrivacyInfo.xcprivacy')):
        errors.append(f'Missing SDK manifest: {framework.name}')
for bundle, reasons in [(app, {'CA92.1', '1C8F.1'}),
                        (app / 'PlugIns/WidgetGarbageExtension.appex', {'1C8F.1'})]:
    path = bundle / 'PrivacyInfo.xcprivacy'
    if not path.exists():
        errors.append(f'Missing app/extension manifest: {bundle.name}')
        continue
    data = plistlib.loads(path.read_bytes())
    declared = {reason for entry in data.get('NSPrivacyAccessedAPITypes', [])
                if entry['NSPrivacyAccessedAPIType'] == 'NSPrivacyAccessedAPICategoryUserDefaults'
                for reason in entry['NSPrivacyAccessedAPITypeReasons']}
    if not reasons <= declared:
        errors.append(f'Missing UserDefaults reasons in {bundle.name}: {reasons - declared}')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'PASS: {len(manifests)} valid manifests; required embedded SDKs and app/Widget UserDefaults reasons present')
