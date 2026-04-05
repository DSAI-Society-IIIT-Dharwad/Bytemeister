import os
import json
import time
import numpy as np
from fastapi import FastAPI, Query, HTTPException, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from supabase import create_client
from google import genai
from google.genai import types 
from security import encrypt_data, decrypt_data
from dotenv import load_dotenv

# 1. LOAD ENVIRONMENT VARIABLES
load_dotenv()

# 2. CONFIGURATION & SAFETY CHECKS
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not GEMINI_API_KEY:
    print("CRITICAL ERROR: GOOGLE_API_KEY not found in .env!")
    exit(1)

# 3. INITIALIZE APP
app = FastAPI(title="API")

# CORS allows Kartik (UI) and Sachi (AI) to connect across the network
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. INITIALIZE CLIENTS
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
client = genai.Client(api_key=GEMINI_API_KEY)

# 5. DATA MODELS
class IngestData(BaseModel):
    user_id: str                   
    raw_transcript: str            
    domain: str                    # 'healthcare' or 'finance'
    sentiment: str                 
    structured_extraction: Dict[str, Any] 

class UpdateData(BaseModel):
    """Requirement 3.5: Human validation/correction data model"""
    corrected_transcript: str
    corrected_extraction: Dict[str, Any]

# 6. HELPER FUNCTION: EMBED WITH RETRY
def get_embedding_with_retry(text: str, max_retries=3):
    """Handles Gemini API rate limits (429 errors)."""
    for attempt in range(max_retries):
        try:
            res = client.models.embed_content(
                model="gemini-embedding-2-preview",
                contents=[text]
            )
            return res.embeddings[0].values
        except Exception as e:
            if "429" in str(e) and attempt < max_retries - 1:
                print(f"Rate limit hit. Retrying in 2s... (Attempt {attempt+1})")
                time.sleep(2)
                continue
            else:
                raise e

# 7. API ENDPOINTS

@app.get("/", tags=["Multi-Domain System Status"])
async def system_connectivity_check():
    """Confirms platform is operational for both Healthcare and Financial sectors."""
    return {
        "status": "Online", 
        "platform": "IndicEcho Innovators",
        "supported_domains": ["Healthcare (Clinical Scribe)", "Financial Services (Loan/Survey)"],
        "security": "AES-256 Encrypted",
        "vector_search": "3072-dim Gemini-2"
    }

@app.post("/process-chat", tags=["Multi-Domain Ingestion (Health & Finance)"])
async def process_chat(data: IngestData):
    """
    Requirement 3.4 & 4: Ingests conversational data for Health or Finance.
    Generates 3072-dim vectors, encrypts text, and stores in the cloud.
    """
    try:
        vector = get_embedding_with_retry(data.raw_transcript)
        enc_transcript = encrypt_data(data.raw_transcript)
        enc_report = encrypt_data(json.dumps(data.structured_extraction))

        db_res = supabase.table("chat_history").insert({
            "user_id": data.user_id,
            "content_encrypted": enc_transcript,
            "structured_data_encrypted": enc_report,
            "domain": data.domain,
            "sentiment": data.sentiment,
            "embedding": vector
        }).execute()

        return {"status": "success", "db_id": db_res.data[0]['id']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/update-record/{db_id}", tags=["Human Correction Interface"])
async def update_record(db_id: str, data: UpdateData):
    """
    Requirement 3.5: Real-time human modification of AI records.
    Allows experts to fix transcription or extraction errors.
    """
    try:
        new_vector = get_embedding_with_retry(data.corrected_transcript)
        enc_text = encrypt_data(data.corrected_transcript)
        enc_report = encrypt_data(json.dumps(data.corrected_extraction))

        supabase.table("chat_history").update({
            "content_encrypted": enc_text,
            "structured_data_encrypted": enc_report,
            "embedding": new_vector
        }).eq("id", db_id).execute()

        return {"status": "success", "message": "Record manually validated and re-indexed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/semantic-search", tags=["Semantic Search Engine"])
async def semantic_search(query: str, user_id: Optional[str] = None, limit: int = 5):
    """
    Requirement 3.6: Multi-sector semantic retrieval. 
    Searches across Healthcare and Finance logs using meaning-based vector math.
    """
    try:
        q_vec = get_embedding_with_retry(query)
        rpc_res = supabase.rpc("match_chats", {
            "query_embedding": q_vec,
            "match_threshold": 0.25,
            "match_count": limit,
            "filter_user_id": user_id 
        }).execute()

        results = []
        for item in rpc_res.data:
            results.append({
                "confidence": f"{round(item['similarity'] * 100)}%",
                "dialogue": decrypt_data(item['content_encrypted']),
                "report": json.loads(decrypt_data(item['structured_data_encrypted'])),
                "domain": item['domain'],
                "user_id": item['user_id'],
                "db_id": item['id'] 
            })
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/user-timeline/{user_id}", tags=["Longitudinal History"])
async def get_user_timeline(user_id: str):
    """
    Requirement 3.6 & 7: Tracks historical timeline for a patient or a financial client.
    """
    try:
        res = supabase.table("chat_history") \
            .select("id", "created_at", "sentiment", "domain", "content_encrypted", "structured_data_encrypted") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .execute()

        timeline = []
        for row in res.data:
            report = json.loads(decrypt_data(row['structured_data_encrypted']))
            transcript = decrypt_data(row['content_encrypted']) if row.get('content_encrypted') else "No transcript found"
            
            timeline.append({
                "db_id": row['id'],
                "date": row['created_at'],
                "sentiment": row['sentiment'],
                "domain": row['domain'],
                "transcript": transcript,
                "domain_fields": report,
                "summary": report.get("plain_summary", report.get("summary", "No summary provided"))
            })
        return {"user_id": user_id, "history": timeline}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))