"""Extract the scan script from each rendered Job/CronJob and syntax-check it with `sh -n`."""
import subprocess
import sys

import yaml


def pod_spec(doc):
    spec = doc.get("spec", {})
    if doc.get("kind") == "CronJob":
        spec = spec.get("jobTemplate", {}).get("spec", {})
    return spec.get("template", {}).get("spec", {})


found = 0
for doc in yaml.safe_load_all(sys.stdin):
    if not doc or doc.get("kind") not in ("Job", "CronJob"):
        continue
    for container in pod_spec(doc).get("containers", []):
        script = container["args"][0]
        print(script)
        subprocess.run(["sh", "-n"], input=script, text=True, check=True)
        found += 1

if not found:
    sys.exit("no scan script found in rendered output")
print(f"{found} scan script(s) passed sh -n")
