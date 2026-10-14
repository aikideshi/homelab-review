#!/usr/bin/env python3
import yaml, sys, json, pathlib
config_path = sys.argv[1] if len(sys.argv)>1 else "/etc/AdGuardHome/config.yaml"
desired_json = sys.argv[2] if len(sys.argv)>2 else "{}"
desired = json.loads(desired_json)
p = pathlib.Path(config_path)
if not p.exists():
    print(f"Config not found {config_path}", file=sys.stderr)
    sys.exit(1)
data = yaml.safe_load(p.read_text()) or {}
rewrites = data.get('rewrites') or []
existing = {r['domain']: r['answer'] for r in rewrites if 'domain' in r and 'answer' in r}
for k,v in desired.items():
    existing[k]=v
sorted_rewrites = [{"domain": k, "answer": v} for k,v in sorted(existing.items())]
data['rewrites'] = sorted_rewrites
p.write_text(yaml.safe_dump(data, sort_keys=False))
print(f"Reconciled {len(sorted_rewrites)} rewrites -> {config_path}")
