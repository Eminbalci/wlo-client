import os
import wave
import numpy as np

def load_wav(path):
    with wave.open(path, 'rb') as wf:
        sr = wf.getframerate()
        nch = wf.getnchannels()
        frames = wf.readframes(wf.getnframes())
        samples = np.frombuffer(frames, dtype=np.int16).astype(np.float32)
        if nch > 1:
            samples = samples.reshape(-1, nch).mean(axis=1)
        return samples, sr

ref_samples, ref_sr = load_wav("tests/char_create_ref.wav")

sound_dir = "assets/sound"
candidate_files = []
for f in os.listdir(sound_dir):
    fl = f.lower()
    if fl.endswith(".wav"):
        if fl.startswith("seb") or fl.startswith("wav") or fl.startswith("kw") or "click" in fl or "btn" in fl:
            candidate_files.append(f)

print(f"Total candidates: {len(candidate_files)}")

# High pass filter / remove background hum to isolate sharp clicks
def highpass(sig):
    # simple diff highpass
    return sig[1:] - 0.95 * sig[:-1]

ref_hp = highpass(ref_samples)

# Key timestamps:
# 3.12 (Btn Create)
# 4.64 (Arrow Next Role)
# 11.60 (Btn Continue -> Error)
# 11.93 (Alert sound?)
# 21.07 (Btn Continue -> Step 2)
# 23.51 (Tab change)
# 41.82 (Btn Continue -> Step 3)
# 43.04 (Element click)
# 51.26 (Finish click)
timestamps = [3.12, 4.64, 11.60, 11.93, 21.07, 23.51, 41.82, 43.04, 51.26]

for t in timestamps:
    # 200ms window
    idx = int(t * ref_sr)
    target = ref_hp[idx:idx + int(0.25 * ref_sr)]
    target_norm = np.linalg.norm(target)
    if target_norm == 0:
        continue
    
    scores = []
    for f in candidate_files:
        try:
            samples, sr = load_wav(os.path.join(sound_dir, f))
            if len(samples) / sr > 4.0:
                continue
            if sr != ref_sr:
                indices = np.linspace(0, len(samples) - 1, int(len(samples) * ref_sr / sr))
                samples = np.interp(indices, np.arange(len(samples)), samples)
            s_hp = highpass(samples)
            if len(s_hp) < len(target):
                s_hp = np.pad(s_hp, (0, len(target) - len(s_hp)))
            else:
                s_hp = s_hp[:len(target)]
            s_norm = np.linalg.norm(s_hp)
            if s_norm > 0:
                score = np.dot(target, s_hp) / (target_norm * s_norm)
                scores.append((score, f))
        except:
            pass
    scores.sort(reverse=True)
    top_str = ", ".join([f"{f} ({sc:.3f})" for sc, f in scores[:4]])
    print(f"t={t:5.2f}s -> {top_str}")
