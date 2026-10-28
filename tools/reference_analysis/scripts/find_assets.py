import os

matches = []
for root, dirs, files in os.walk("assets"):
    for f in files:
        fl = f.lower()
        if "form" in fl or "select" in fl or "create" in fl or "role" in fl:
            matches.append(os.path.join(root, f))

for m in sorted(matches):
    print(m)
