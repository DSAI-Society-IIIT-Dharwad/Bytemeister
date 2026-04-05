import os
import json
from google import genai
from dotenv import load_dotenv

load_dotenv()
# This uses the GOOGLE_API_KEY from your .env file
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

def extract_independent_data(transcript, p1, p2):
    prompt = f"""
    You are a Cross-Sector AI Data Extractor. Analyze this transcript between {p1} and {p2}.
    Transcript: "{transcript}"

    TASK:
    1. Identify Domain: Healthcare or Financial.
    2. Speaker Summary: Extract important points for {p1} and {p2} separately.
    3. Dynamic Extraction: Extract relevant fields only.
    
    FIELD REFERENCE:
    - Health: Symptoms, Diagnosis, Treatment, Immunization, Risk, ENT findings.
    - Finance: ID Verification, Account/Loan, Payment Status, Payer, Amount.

    RETURN ONLY VALID JSON:
    {{
      "domain_detected": "...",
      "speaker_summaries": {{ "{p1}": [], "{p2}": [] }},
      "dynamic_fields": {{ "Field": "Value" }},
      "overall_summary": "..."
    }}
    """
    try:
        # Calls the Gemini 2.0 Flash API
        response = client.models.generate_content(
            model="gemma-4-26b-a4b-it",
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
            }
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return {
            "domain_detected": "Error",
            "speaker_summaries": {p1: ["API Error"], p2: ["API Error"]},
            "dynamic_fields": {},
            "overall_summary": "Could not connect to Gemini."
        }