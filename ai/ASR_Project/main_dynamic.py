import os
from pathlib import Path
from pydub import AudioSegment
from history_manager import load_pair_history
from asr_generic import transcribe_audio, translate_to_english
# IMPORT GEMINI ENGINE INSTEAD OF OLLAMA
from gemini_engine import extract_independent_data 

AudioSegment.converter = r"C:\ffmpeg\bin\ffmpeg.exe"

def run_tracker_pipeline(audio_path, p1, p2):
    audio = AudioSegment.from_file(audio_path)
    full_raw_text = ""
    Path("audio_chunks").mkdir(exist_ok=True)
    
    # 25s chunks for Sarvam
    for i, start in enumerate(range(0, len(audio), 25000)):
        chunk = audio[start : start + 25000]
        chunk_file = f"audio_chunks/temp_{i}.wav"
        chunk.export(chunk_file, format="wav")
        try:
            full_raw_text += transcribe_audio(chunk_file) + " "
        except: pass

    eng = translate_to_english(full_raw_text)
    # This now calls Gemini 2.0 Flash
    analysis = extract_independent_data(eng, p1, p2)
    
    return {
        "speaker_summaries": analysis.get("speaker_summaries", {}),
        "extracted_data": analysis
    }