from moviepy.editor import VideoFileClip

video = VideoFileClip("tests/char_create_ref.mp4")
video.audio.write_audiofile("tests/char_create_ref.wav", fps=44100)
video.close()
print("Extracted tests/char_create_ref.wav")
