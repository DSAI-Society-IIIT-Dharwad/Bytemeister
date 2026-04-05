import os
import json
from pathlib import Path
from pydub import AudioSegment

from asr_kannada import transcribe_audio_chunk_kannada
from cleanup_kannada import clean_kannada_transcript
from translator import translate_kannada_to_english
from extractor import extract_structured_data, load_schema

INPUT_FILE = "kannada_call.wav"
MAX_CHUNK_SECONDS = 25
SCHEMA_FILE = "healthcare.yaml"

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

def main():
    if not os.path.exists(INPUT_FILE):
        raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

    if not os.path.exists(SCHEMA_FILE):
        raise FileNotFoundError(f"Schema file not found: {SCHEMA_FILE}")

    chunks = split_audio_into_chunks(INPUT_FILE, MAX_CHUNK_SECONDS)

    # STEP 1: Kannada ASR
    raw_parts = []
    for i, chunk in enumerate(chunks, start=1):
        print(f"Transcribing chunk {i}/{len(chunks)}")
        raw_parts.append(transcribe_audio_chunk_kannada(chunk))

    raw_kn = "\n".join(raw_parts)

    # STEP 2: Cleanup Kannada
    print("Cleaning Kannada transcript...")
    corrected_kn = clean_kannada_transcript(raw_kn)

    # STEP 3: Translate to English
    print("Translating to English...")
    english_text = translate_kannada_to_english(corrected_kn)

    # STEP 4: Structured extraction
    print("Extracting structured data...")
    schema = load_schema(SCHEMA_FILE)
    extracted = extract_structured_data(english_text, schema)

    # SAVE TEXT FILES
    with open("transcript_kn_raw.txt", "w", encoding="utf-8") as f:
        f.write(raw_kn)

    with open("transcript_kn_corrected.txt", "w", encoding="utf-8") as f:
        f.write(corrected_kn)

    with open("transcript_english.txt", "w", encoding="utf-8") as f:
        f.write(english_text)

    # SAVE EXTRACTION
    with open("medical_extraction.json", "w", encoding="utf-8") as f:
        json.dump(extracted, f, ensure_ascii=False, indent=2)

    summary = extracted.get("plain_summary", "")
    with open("medical_summary.txt", "w", encoding="utf-8") as f:
        f.write(summary)

    print("\n" + "=" * 80)
    print("RAW KANNADA TRANSCRIPT")
    print("=" * 80)
    print(raw_kn)

    print("\n" + "=" * 80)
    print("CORRECTED KANNADA TRANSCRIPT")
    print("=" * 80)
    print(corrected_kn)

    print("\n" + "=" * 80)
    print("ENGLISH TRANSCRIPT")
    print("=" * 80)
    print(english_text)

    print("\n" + "=" * 80)
    print("STRUCTURED EXTRACTION")
    print("=" * 80)
    print(json.dumps(extracted, ensure_ascii=False, indent=2))

    print("\nSaved files:")
    print("- transcript_kn_raw.txt")
    print("- transcript_kn_corrected.txt")
    print("- transcript_english.txt")
    print("- medical_extraction.json")
    print("- medical_summary.txt")

if __name__ == "__main__":
    main()