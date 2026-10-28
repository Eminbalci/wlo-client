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

# Sample 5 seconds of the video where there are no clicks, e.g. t = 13.0s to 18.0s
target = ref_samples[int(13.0 * ref_sr) : int(18.0 * ref_sr)]
target_norm = np.linalg.norm(target)

bgm_dir = "assets/sound"
matches = []
for f in os.listdir(bgm_dir):
    if f.lower().startswith("bgm") and f.lower().endswith(".wav"):
        samples, sr = load_wav(os.path.join(bgm_dir, f))
        if samples is None or len(samples) / sr < 10.0:
            continue
        # resample if needed
        if sr != ref_sr:
            indices = np.linspace(0, len(samples) - 1, int(len(samples) * ref_sr / sr))
            samples = np.interp(indices, np.arange(len(samples)), samples)
        # Search for target in the first 60s of this BGM
        search_len = min(len(samples), int(60 * ref_sr))
        search_samples = samples[:search_len]
        if len(search_samples) > len(target):
            # compute cross correlation using FFT
            corr = np.correlate(search_samples, target, mode='valid')
            best_corr = np.max(corr) / (target_norm * np.linalg.norm(search_samples[:len(target)]))
            matches.append((best_corr, f))

matches.sort(reverse=True)
print("Top BGM matches for char_create video:")
for sc, f in matches[:5]:
    print(f"  {f:20s}: score = {sc:.4f}")
