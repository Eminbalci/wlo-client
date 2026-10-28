import os

# Search for exes in project or parent
for base in [".", "..", "D:/Godot/WonderlandOnline", "D:/GitHub/WLRI"]:
    if os.path.exists(base):
        for root, dirs, files in os.walk(base):
            for f in files:
                if f.lower().endswith(".exe") or f.lower().endswith(".dat") or f.lower().endswith(".txt"):
                    if "login" in f.lower() or "main" in f.lower() or "string" in f.lower() or "msg" in f.lower():
                        print(os.path.join(root, f))
