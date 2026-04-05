import os
from pathlib import Path
from pydub import AudioSegment
from asr_generic import transcribe_audio, translate_to_english
from gemini_engine import extract_independent_data 
from backend_integration import send_data_to_backend

AudioSegment.converter = r"C:\ffmpeg\bin\ffmpeg.exe"

def run_tracker_pipeline(audio_path, p1, p2):
    # 1. Audio Processing
    audio = AudioSegment.from_file(audio_path)
    full_raw_indic_text = ""
    Path("audio_chunks").mkdir(exist_ok=True)
    
    # 25s chunks for Sarvam
    for i, start in enumerate(range(0, len(audio), 25000)):
        chunk_file = f"audio_chunks/temp_{i}.wav"
        audio[start : start + 25000].export(chunk_file, format="wav")
        try:
            full_raw_indic_text += transcribe_audio(chunk_file) + " "
        except: pass

    # 2. Translation
    english_transcript = translate_to_english(full_raw_indic_text)

    # 3. Gemini Extraction
    ai_analysis = extract_independent_data(english_transcript, p1, p2)
    
    # 4. BACKEND INTEGRATION (Push to Chhavi)
    user_id = f"{p1}_{p2}".replace(" ", "_")
    sync_result = send_data_to_backend(
        user_id=user_id,
        raw_transcript=full_raw_indic_text,
        ai_result=ai_analysis
    )

    return {
        "speaker_summaries": ai_analysis.get("speaker_summaries", {}),
        "extracted_data": ai_analysis,
        "raw_indic_text": full_raw_indic_text,
        "backend_synced": True if sync_result else False
    }