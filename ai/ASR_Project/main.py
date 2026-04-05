import os
from pathlib import Path
from dotenv import load_dotenv
from pydub import AudioSegment
from pydub.utils import which
from sarvamai import SarvamAI

# =========================
# LOAD ENV
# =========================
load_dotenv()

# =========================
# CONFIG
# =========================
SARVAM_API_KEY = os.getenv("SARVAM_API_KEY")
INPUT_FILE = "kannada.mp4"   # or full path
MODEL = "saaras:v3"
MODE = "translate"
MAX_CHUNK_SECONDS = 25

# OPTIONAL: set ffmpeg path manually if needed
# Example:
# FFMPEG_PATH = r"C:\ffmpeg\bin\ffmpeg.exe"
# FFPROBE_PATH = r"C:\ffmpeg\bin\ffprobe.exe"

FFMPEG_PATH = r"C:\ffmpeg\bin\ffmpeg.exe"
FFPROBE_PATH = r"C:\ffmpeg\bin\ffprobe.exe"

# =========================
# VALIDATIONS
# =========================
if not SARVAM_API_KEY:
    raise ValueError("SARVAM_API_KEY not set")

if not os.path.exists(INPUT_FILE):
    raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

# =========================
# FFMPEG SETUP
# =========================
if os.path.exists(FFMPEG_PATH):
    AudioSegment.converter = FFMPEG_PATH

if os.path.exists(FFPROBE_PATH):
    AudioSegment.ffprobe = FFPROBE_PATH

print("ffmpeg found:", which("ffmpeg") or AudioSegment.converter)
print("ffprobe found:", which("ffprobe") or getattr(AudioSegment, "ffprobe", None))

# =========================
# INITIALIZE SARVAM
# =========================
sarvam_client = SarvamAI(api_subscription_key=SARVAM_API_KEY)

# =========================
# HELPERS
# =========================
def split_audio_into_chunks(input_audio: str, chunk_seconds: int = 25):
    audio = AudioSegment.from_file(input_audio)
    chunk_length_ms = chunk_seconds * 1000

    output_dir = Path("audio_chunks")
    output_dir.mkdir(exist_ok=True)

    chunks = []
    for i, start_ms in enumerate(range(0, len(audio), chunk_length_ms), start=1):
        end_ms = min(start_ms + chunk_length_ms, len(audio))
        chunk = audio[start_ms:end_ms]
        chunk_path = output_dir / f"chunk_{i:03d}.wav"
        chunk.export(chunk_path, format="wav")
        chunks.append(str(chunk_path))

    return chunks


def transcribe_audio_chunk_kannada(file_path: str) -> str:
    with open(file_path, "rb") as f:
        response = sarvam_client.speech_to_text.transcribe(
            file=f,
            model="saaras:v3",
            mode="transcribe",
            language_code="kn-IN"
        )
    return response.transcript.strip()


def translate_audio_chunk_to_english(file_path: str) -> str:
    with open(file_path, "rb") as f:
        response = sarvam_client.speech_to_text.transcribe(
            file=f,
            model="saaras:v3",
            mode="translate",
            language_code="kn-IN"
        )
    return response.transcript.strip()
# =========================
# MAIN
# =========================
def main():
    audio = AudioSegment.from_file(INPUT_FILE)
    duration = len(audio) / 1000
    print(f"Audio duration: {duration:.2f} seconds")

    if duration <= MAX_CHUNK_SECONDS:
        print("Translating single audio file to English...")
        english_text = translate_audio_chunk_to_english(INPUT_FILE)
    else:
        print(f"Audio is longer than {MAX_CHUNK_SECONDS} seconds.")
        print("Splitting into chunks and translating one by one...")

        chunks = split_audio_into_chunks(INPUT_FILE, MAX_CHUNK_SECONDS)
        parts = []

        for i, chunk in enumerate(chunks, start=1):
            print(f"Processing chunk {i}/{len(chunks)}: {chunk}")
            try:
                translated = translate_audio_chunk_to_english(chunk)
                parts.append(translated)
            except Exception as e:
                print(f"Failed on {chunk}: {e}")
                parts.append(f"[ERROR in {chunk}]")

        english_text = "\n".join(parts)

    print("\n" + "=" * 80)
    print("FINAL ENGLISH TEXT")
    print("=" * 80)
    print(english_text)

    with open("transcript_english.txt", "w", encoding="utf-8") as f:
        f.write(english_text)

    print("\nSaved to transcript_english.txt")


if __name__ == "__main__":
    main()