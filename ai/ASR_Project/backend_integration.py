import requests
import logging

log = logging.getLogger("api")

# Use Chhavi's Local IP Address
CHHAVI_URL = "http://10.0.20.98:8000/process-chat"

def send_data_to_backend(user_id, raw_transcript, ai_result):
    """
    Sends processed AI data to the remote backend.
    """
    payload = {
        "user_id": user_id,
        "raw_transcript": raw_transcript,
        "domain": ai_result.get("domain_detected", "healthcare"),
        "sentiment": "neutral",
        "structured_extraction": {
            "plain_summary": ai_result.get("overall_summary", "No summary provided"),
            "speaker_points": ai_result.get("speaker_summaries", {}),
            "dynamic_data": ai_result.get("dynamic_fields", {})
        }
    }

    try:
        log.info(f"🚀 Syncing with Chhavi's Backend: {CHHAVI_URL}")
        response = requests.post(CHHAVI_URL, json=payload, timeout=10)
        
        if response.status_code == 200:
            log.info("✅ Sync Successful.")
            return response.json()
        else:
            log.error(f"⚠️ Backend Error: {response.status_code}")
            return None
    except Exception as e:
        log.error(f"❌ Connection to Chhavi failed: {e}")
        return None