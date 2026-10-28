import os, wave

for f in sorted(os.listdir("assets/sound")):
    if f.lower().startswith("wav015") or f.lower().startswith("wav990") or f.lower().startswith("wav160") or f.lower().startswith("seb002"):
        try:
            with wave.open(os.path.join("assets/sound", f), 'rb') as wf:
                dur = wf.getnframes() / wf.getframerate()
                print(f"{f:15s}: {dur:.3f}s, {wf.getframerate()}Hz, {wf.getnchannels()}ch")
        except Exception as e:
            print(f"{f:15s}: Error: {e}")
