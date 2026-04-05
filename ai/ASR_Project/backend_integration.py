import requests
import json

# Chhavi's Backend Configuration
BACKEND_URL = "http://10.0.20.98:8000/process-chat"

def send_data_to_backend(user_id, raw_transcript, ai_result):
    """
    Maps your AI Specialist output to Chhavi's Backend payload structure.
    """
    
    # Mapping your 'extracted_data' to her 'structured_extraction'
    payload = {
        "user_id": user_id,
        "raw_transcript": raw_transcript,
        "domain": ai_result.get("domain_detected", "healthcare"),
        "sentiment": "neutral", # Default since we removed sentiment analysis
        "structured_extraction": {
            "plain_summary": ai_result.get("overall_summary", "No summary provided"),
            "speaker_points": ai_result.get("speaker_summaries", {}),
            "dynamic_data": ai_result.get("dynamic_fields", {})
        }
    }

    try:
        print(f"[INTEGRATION] 🚀 Sending data to Chhavi's Backend ({BACKEND_URL})...")
        response = requests.post(BACKEND_URL, json=payload, timeout=10)
        
        if response.status_code == 200:
            print("[INTEGRATION] ✅ Successfully synced with Backend.")
            return response.json()
        else:
            print(f"[INTEGRATION] ⚠️ Backend returned error {response.status_code}: {response.text}")
            return None
    except Exception as e:
        print(f"[INTEGRATION] ❌ Failed to connect to Backend: {e}")
        return None