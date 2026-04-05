import os
from dotenv import load_dotenv
from sarvamai import SarvamAI

load_dotenv()

sarvam_client = SarvamAI(api_subscription_key=os.getenv("SARVAM_API_KEY"))

def translate_to_english(text: str, source_language_code: str) -> str:
    if source_language_code == "en-IN":
        return text

    response = sarvam_client.text.translate(
        input=text,
        source_language_code=source_language_code,
        target_language_code="en-IN",
        model="sarvam-translate:v1",
        mode="formal"
    )
    return response.translated_text.strip()