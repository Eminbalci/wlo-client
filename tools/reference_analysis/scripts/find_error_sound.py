import os, wave
import numpy as np

def load_wav(path):
    try:
        with wave.open(path, 'rb') as wf:
            sr = wf.getframerate()
            nch = wf.getnchannels()
            frames = wf.readframes(wf.getnframes())
            samples = np.frombuffer(frames, dtype=np.int16).astype(np.float32)
            if nch > 1:
                samples = samples.reshape(-1, nch).mean(axis=1)
            return samples, sr
    except:
        return None, 0

ref_samples, ref_sr = load_wav("tests/char_create_ref.wav")

# Highpass filter
def hp(sig):
    return sig[1:] - 0.95 * sig[:-1]

ref_hp = hp(ref_samples)

# Let's inspect t = 11.4s to 12.5s
# Find local peak in ref_hp
idx_start = int(11.4 * ref_sr)
idx_end = int(12.5 * ref_sr)
slice_hp = ref_hp[idx_start:idx_end]

# Find peak inside this slice
p_idx = np.argmax(np.abs(slice_hp))
exact_t = 11.4 + p_idx / ref_sr
print(f"Exact peak at t = {exact_t:.3f}s")

target = ref_hp[idx_start + p_idx : idx_start + p_idx + int(0.3 * ref_sr)]
target_norm = np.linalg.norm(target)

matches = []
for f in os.listdir("assets/sound"):
    if not f.lower().endswith(".wav"): continue
    samples, sr = load_wav(os.path.join("assets/sound", f))
    if samples is None or len(samples) == 0: continue
    if len(samples) / sr > 3.0: continue
    if sr != ref_sr:
        indices = np.linspace(0, len(samples) - 1, int(len(samples) * ref_sr / sr))
        samples = np.interp(indices, np.arange(len(samples)), samples)
    s_hp = hp(samples)
    if len(s_hp) < len(target):
        s_hp = np.pad(s_hp, (0, len(target) - len(s_hp)))
    else:
        s_hp = s_hp[:len(target)]
    s_norm = np.linalg.norm(s_hp)
    if s_norm > 0:
        score = np.dot(target, s_hp) / (target_norm * s_norm)
        matches.append((score, f))

matches.sort(reverse=True)
print("Top 10 matches for t=11.60s (empty name error):")
for sc, f in matches[:10]:
    print(f"  {f:20s}: {sc:.4f}")
