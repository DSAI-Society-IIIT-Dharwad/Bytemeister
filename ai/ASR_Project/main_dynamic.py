import os
import time
import requests
from pathlib import Path
from pydub import AudioSegment

from asr_generic import transcribe_audio, translate_to_english
from gemma_engine import extract_independent_data
from gap_detector import detect_rule_based_gaps, merge_gaps

AudioSegment.converter = r"C:\ffmpeg\bin\ffmpeg.exe"
BACKEND_URL = "http://10.0.20.98:8000/process-chat"


def run_tracker_pipeline(audio_path, p1, p2):
    timings = {}
    total_start = time.perf_counter()

    # 1. Load File
    s = time.perf_counter()
    audio = AudioSegment.from_file(audio_path)
    timings["1. Load File"] = f"{time.perf_counter() - s:.2f}s"

    # 2. ASR (Sarvam)
    s = time.perf_counter()
    full_raw_text = ""
    Path("audio_chunks").mkdir(exist_ok=True)

    chunks = range(0, len(audio), 25000)
    for i, start in enumerate(chunks):
        chunk_file = f"audio_chunks/temp_{i}.wav"
        audio[start:start + 25000].export(chunk_file, format="wav")
        full_raw_text += transcribe_audio(chunk_file) + " "

    full_raw_text = full_raw_text.strip()
    timings["2. ASR (Speech-to-Text)"] = f"{time.perf_counter() - s:.2f}s"

    # 3. Translation
    s = time.perf_counter()
    eng = translate_to_english(full_raw_text)
    timings["3. Translation"] = f"{time.perf_counter() - s:.2f}s"

    # 4. AI Consultant Analysis
    s = time.perf_counter()
    analysis = extract_independent_data(eng, p1, p2)

    rule_gaps = detect_rule_based_gaps(
        analysis.get("domain_detected", ""),
        analysis.get("dynamic_fields", {}),
        p2
    )

    analysis["missing_info_detective"] = merge_gaps(
        analysis.get("missing_info_detective", []),
        rule_gaps
    )

    timings["4. AI Gap Analysis"] = f"{time.perf_counter() - s:.2f}s"

    # 5. Backend Sync
    s = time.perf_counter()
    payload = {
        "user_id": f"{p1}_{p2}".replace(" ", "_"),
        "raw_transcript": full_raw_text,
        "domain": analysis.get("domain_detected", "healthcare"),
        "structured_extraction": {
            "summary": analysis.get("overall_summary", ""),
            "gaps": analysis.get("missing_info_detective", []),
            "actions": analysis.get("action_items", {}),
            "speaker_points": analysis.get("speaker_summaries", {}),
            "dynamic_data": analysis.get("dynamic_fields", {})
        }
    }

    try:
        requests.post(BACKEND_URL, json=payload, timeout=5)
        sync_status = "✅ Synced"
    except Exception:
        sync_status = "❌ Offline"

    timings["5. Backend Sync"] = f"{time.perf_counter() - s:.2f}s"
    timings["Total Pipeline Time"] = f"{time.perf_counter() - total_start:.2f}s"

    return {
        "raw_transcript": full_raw_text,
        "english_transcript": eng,
        "speaker_summaries": analysis.get("speaker_summaries", {}),
        "extracted_data": analysis,
        "timings": timings,
        "sync": sync_status
    }