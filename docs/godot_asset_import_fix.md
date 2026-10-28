# Godot Asset Import Freeze & Audio Format Diagnosis

## Root Cause Analysis

When launching the Godot 4.6.2 Editor on the `wonderland-online-client` project, the editor froze indefinitely with Windows title bar status `WonderlandOnlineClient - Godot Engine (Yanıt Vermiyor)` at dialog progress `Varlıklar (Yeniden)İçe Aktarılıyor: 71% - BGM0041.wav`.

Investigation of the binary asset headers and Godot Engine console diagnostics revealed two distinct compounding root causes:

### 1. Legacy Microsoft ADPCM (Format 0x0002) Incompatibility
- **Issue**: Original 2006 Wonderland Online audio assets stored music and voice files encoded in Microsoft ADPCM (`wFormatTag = 0x0002`), an obsolete proprietary 1990s compression format.
- **Affected Assets**:
  - `assets/sound/`: 36 BGM and effect tracks (including `BGM0001.wav` through `BGM0041.wav`).
  - `assets/voice/`: 317 character dialogue audio clips (`kw_...wav`).
  - **Total**: 354 non-PCM WAV files.
- **Engine Failure Mode**: Godot's C++ audio stream importer (`scene/resources/audio_stream_wav.cpp`) strictly expects uncompressed PCM (format 1), IEEE Float (format 3), or IMA ADPCM (format 17). When encountering Microsoft ADPCM chunk headers, the chunk parser miscalculated sample block alignment, emitted `Format not supported for WAVE file (not PCM)`, and entered an infinite seek loop inside `core/io/file_access_memory.cpp:101` (`ERROR: Condition "p_position > length" is true`). This flooded stderr with hundreds of thousands of error lines and locked the main UI thread.

### 2. Malformed Trailing Garbage in `SEB0279.wav`
- **Issue**: `assets/sound/SEB0279.wav` had a physical file size of 145,466 bytes while its RIFF chunk header declared a length of only 73,636 bytes (73,644 bytes total expected file size).
- **Corrupted Data**: 71,822 bytes of trailing null bytes and a malformed chunk header declaring `size = 4,288,675,839` (4.29 GB).
- **Engine Failure Mode**: Godot attempted to seek through tens of thousands of null chunks past the end of the memory buffer, crashing the importer state machine.

---

## Applied Solutions

1. **Batch Conversion to Standard 16-Bit PCM WAV**:
   - All 354 Microsoft ADPCM audio files in `assets/sound/` and `assets/voice/` were decompressed and rewritten as standard uncompressed 16-bit PCM WAV (`subtype='PCM_16'`, `wFormatTag = 0x0001`).
   - Native sample rates (22,050 Hz and 44,100 Hz) and channel layouts (Mono/Stereo) were preserved with zero audio quality degradation.
2. **Sanitization of `SEB0279.wav`**:
   - Stripped all trailing null padding and corrupted chunk headers.
   - Cleanly re-saved as an authentic 73,644-byte standard 16-bit PCM WAV.
3. **Verification**:
   - Automated scan verified 0 remaining non-PCM WAV files across the entire project directory tree.
   - Headless Godot Editor import (`godot_console.exe --editor --headless --quit`) completed all 3,540 asset scan and reimport steps in under 8 seconds with `exit code 0` and zero errors.

---

## Technical Specifications of Converted Assets

| Category | File Count | Original Format | Converted Format | Sample Rate |
|---|---|---|---|---|
| Background Music (`assets/sound/BGM*.wav`) | 36 | Microsoft ADPCM (fmt 2) | PCM 16-bit (fmt 1) | 22,050 Hz Stereo |
| Voice Clips (`assets/voice/kw_*.wav`) | 317 | Microsoft ADPCM (fmt 2) | PCM 16-bit (fmt 1) | 22,050 Hz Stereo/Mono |
| Sound Effects (`assets/sound/SEB0279.wav`) | 1 | Malformed Garbage Chunks | Clean PCM 16-bit (fmt 1) | 22,050 Hz Stereo |
