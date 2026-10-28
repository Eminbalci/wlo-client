import os
import wave
import numpy as np

# Load reference audio
with wave.open("tests/char_create_ref.wav", "rb") as wf:
    ref_nchannels = wf.getnchannels()
    ref_sampwidth = wf.getsampwidth()
    ref_framerate = wf.getframerate()
    ref_nframes = wf.getnframes()
    ref_data = wf.readframes(ref_nframes)
    ref_samples = np.frombuffer(ref_data, dtype=np.int16)
    if ref_nchannels > 1:
        ref_samples = ref_samples.reshape(-1, ref_nchannels).mean(axis=1)

print(f"Ref audio: {ref_framerate}Hz, {len(ref_samples)} samples ({len(ref_samples)/ref_framerate:.2f}s)")

# List sound files in assets/sound
sound_dir = "assets/sound"
sound_files = [f for f in os.listdir(sound_dir) if f.lower().endswith(".wav")]
print(f"Found {len(sound_files)} wav files in {sound_dir}")

# We can search for short sound occurrences in the ref video
# Let's check some known UI sounds:
# Let's test which sound files exist that might be UI clicks
ui_candidates = [f for f in sound_files if f.lower().startswith("seb") or f.lower().startswith("kw") or f.lower().startswith("se") or f.lower().startswith("s_") or "btn" in f.lower() or "click" in f.lower() or "ui" in f.lower()]
print(f"Candidate UI sound files: {len(ui_candidates)}")
for c in ui_candidates[:30]:
    print(" ", c)
