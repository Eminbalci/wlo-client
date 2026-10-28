import os

skins_dir = "assets/menu/Skins"
forms = []
for root, dirs, files in os.walk(skins_dir):
    for f in files:
        fl = f.lower()
        if "form" in fl or "msg" in fl or "alert" in fl or "dialog" in fl or "prompt" in fl:
            forms.append(os.path.join(root, f))

for f in sorted(forms):
    print(f)
