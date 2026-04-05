import os
import json
from google import genai
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

def extract_independent_data(transcript, p1, p2):
    prompt = f"""
    Analyze this transcript between {p1} and {p2}.
    Transcript: "{transcript}"

    TASK:
    1. Identify Domain (Healthcare or Financial).
    2. Summaries: Important key points for {p1} and {p2} separately.
    3. Extraction: Relevant medical or financial fields discussed.

    RETURN JSON:
    {{
      "domain_detected": "...",
      "speaker_summaries": {{ "{p1}": [], "{p2}": [] }},
      "dynamic_fields": {{}},
      "overall_summary": "..."
    }}
    """
    try:
        response = client.models.generate_content(
            model="gemma-4-26b-a4b-it",
            contents=prompt,
            config={'response_mime_type': 'application/json'}
        )
        return json.loads(response.text)
    except Exception as e:
        return {"overall_summary": "AI Error", "dynamic_fields": {"error": str(e)}}