import wave
import numpy as np
import os

with wave.open("tests/char_create_ref.wav", "rb") as wf:
    sr = wf.getframerate()
    nch = wf.getnchannels()
    frames = wf.readframes(wf.getnframes())
    samples = np.frombuffer(frames, dtype=np.int16)
    if nch > 1:
        samples = samples.reshape(-1, nch).mean(axis=1)

# Detect energy bursts (SFX)
# Normalise
samples = samples.astype(np.float32) / 32768.0

# Frame size 20ms
win = int(sr * 0.02)
hop = int(sr * 0.01)
energy = []
for i in range(0, len(samples) - win, hop):
    seg = samples[i:i+win]
    energy.append(np.sqrt(np.mean(seg**2)))
energy = np.array(energy)

# Find peaks above threshold
threshold = 0.028
peaks = []
for i in range(1, len(energy) - 1):
    if energy[i] > threshold and energy[i] > energy[i-1] and energy[i] > energy[i+1]:
        t = i * hop / sr
        # Avoid duplicate peaks within 150ms
        if not peaks or (t - peaks[-1][0]) > 0.15:
            peaks.append((t, energy[i]))

print(f"Detected {len(peaks)} audio event peaks:")
for t, e in peaks:
    print(f"  t = {t:6.2f}s (frame ~{int(t*30):4d}), energy = {e:.3f}")
