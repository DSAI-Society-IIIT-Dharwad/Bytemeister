import os
from sarvamai import SarvamAI
from dotenv import load_dotenv

load_dotenv()
client = SarvamAI(api_subscription_key=os.getenv("SARVAM_API_KEY"))

def transcribe_audio(file_path):
    with open(file_path, "rb") as f:
        response = client.speech_to_text.transcribe(
            file=f,
            model="saaras:v3",
            language_code="hi-IN", # Logic should eventually use language_utils to set this
            mode="transcribe"
        )
    return response.transcript

def translate_to_english(text):
    if not text.strip(): return ""
    response = client.text.translate(
        input=text,
        source_language_code="hi-IN", 
        target_language_code="en-IN",
        model="sarvam-translate:v1"
    )
    return response.translated_text