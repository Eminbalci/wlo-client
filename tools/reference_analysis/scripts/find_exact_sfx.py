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
        # resample to 44100 if needed (most are 44100 or 22050)
        return samples, sr

ref_samples, ref_sr = load_wav("tests/char_create_ref.wav")

sound_dir = "assets/sound"
all_wavs = {}
for f in os.listdir(sound_dir):
    if f.lower().endswith(".wav"):
        try:
            samples, sr = load_wav(os.path.join(sound_dir, f))
            # keep if duration < 3 seconds (UI sfx)
            if len(samples) / sr < 3.0:
                all_wavs[f] = (samples, sr)
        except Exception:
            pass

print(f"Loaded {len(all_wavs)} short SFX files.")

# Check specific timestamps:
# t = 3.12s (clicking create character or button)
# t = 4.64s (cycling role)
# t = 6.85s (cycling role)
# t = 11.60s (missing name error or click)
test_times = [3.12, 4.64, 6.85, 11.60, 21.07, 23.51, 31.32, 51.26, 53.68]

for tt in test_times:
    start_idx = int((tt - 0.05) * ref_sr)
    end_idx = int((tt + 0.6) * ref_sr)
    target = ref_samples[start_idx:end_idx]
    target_norm = np.linalg.norm(target)
    if target_norm == 0:
        continue
    
    best_file = None
    best_score = -1.0
    
    for fname, (samples, sr) in all_wavs.items():
        # if sample rate differs, interpolate
        if sr != ref_sr:
            # simple linear resample
            indices = np.linspace(0, len(samples) - 1, int(len(samples) * ref_sr / sr))
            s_res = np.interp(indices, np.arange(len(samples)), samples)
        else:
            s_res = samples
            
        if len(s_res) > len(target):
            s_res = s_res[:len(target)]
        elif len(s_res) < len(target):
            s_res = np.pad(s_res, (0, len(target) - len(s_res)))
            
        s_norm = np.linalg.norm(s_res)
        if s_norm > 0:
            score = np.dot(target, s_res) / (target_norm * s_norm)
            if score > best_score:
                best_score = score
                best_file = fname
                
    print(f"Time {tt:5.2f}s -> Best match: {best_file} (similarity: {best_score:.4f})")
