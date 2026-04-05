import os
import json
from google import genai
from dotenv import load_dotenv

load_dotenv()
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
        # Using Gemini 2.0 Flash for speed and intelligence
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
            }
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"Gemini Error: {e}")
        return {"speaker_summaries": {}, "dynamic_fields": {"Error": str(e)}, "overall_summary": "AI Error"}