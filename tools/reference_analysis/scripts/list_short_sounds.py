import os, wave

sound_dir = "assets/sound"
files = []
for f in os.listdir(sound_dir):
    if f.lower().endswith(".wav"):
        try:
            with wave.open(os.path.join(sound_dir, f), 'rb') as wf:
                dur = wf.getnframes() / wf.getframerate()
                files.append((f, dur))
        except Exception:
            pass

files.sort(key=lambda x: x[1])
print("Shortest 30 files:")
for f, d in files[:30]:
    print(f"  {f:20s}: {d:.3f}s")

print("\nFiles with duration between 0.3s and 3.0s:")
for f, d in files:
    if 0.3 <= d <= 3.0:
        print(f"  {f:20s}: {d:.3f}s")
