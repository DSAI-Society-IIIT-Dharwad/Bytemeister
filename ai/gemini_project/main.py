import os
import json
import numpy as np
from fastapi import FastAPI, Query
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from supabase import create_client
from google import genai
from security import encrypt_data, decrypt_data
from dotenv import load_dotenv

# Load Environment Variables
load_dotenv()

app = FastAPI(title="IndicEcho Backend: Secure Multilingual Conversational Platform")

# 1. Initialize Clients
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
gemini = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# 2. Data Models (The Handshake with Sachi)
class IngestData(BaseModel):
    user_id: str                   # Patient/Client ID (Longitudinal Tracking)
    raw_transcript: str            # "Person 1: ... Person 2: ..."
    domain: str                    # 'healthcare' or 'finance'
    sentiment: str                 # 'positive', 'negative', 'neutral'
    structured_extraction: Dict[str, Any] # The AI-extracted report

# 3. API ENDPOINTS

@app.get("/")
async def health_check():
    return {"status": "Online", "platform": "IndicEcho Innovators"}

@app.post("/process-chat")
async def process_chat(data: IngestData):
    """
    Ingestion Layer: 
    1. Vectorizes the dialogue for search.
    2. Encrypts sensitive info for DPDP compliance.
    3. Stores in Supabase.
    """
    try:
        # A. Generate 3072-dim Embedding (Multimodal space)
        res = gemini.models.embed_content(
            model="gemini-embedding-2-preview",
            contents=[data.raw_transcript]
        )
        vector = res.embeddings[0].values

        # B. Privacy Shield: Encrypt Sensitive Fields
        enc_transcript = encrypt_data(data.raw_transcript)
        enc_report = encrypt_data(json.dumps(data.structured_extraction))

        # C. Store in Supabase
        db_res = supabase.table("chat_history").insert({
            "user_id": data.user_id,
            "content_encrypted": enc_transcript,
            "structured_data_encrypted": enc_report,
            "domain": data.domain,
            "sentiment": data.sentiment,
            "embedding": vector
        }).execute()

        return {"status": "success", "db_id": db_res.data[0]['id'], "user_id": data.user_id}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/find-history")
async def find_history(
    query: str, 
    user_id: Optional[str] = None, 
    limit: int = 5
):
    """
    Search Layer: Semantic retrieval using Vector Math.
    Supports global search or user-specific history search.
    """
    try:
        # A. Embed the Search Query
        res = gemini.models.embed_content(
            model="gemini-embedding-2-preview",
            contents=[query]
        )
        q_vec = res.embeddings[0].values

        # B. Call Supabase Vector Search (RPC)
        rpc_params = {
            "query_embedding": q_vec,
            "match_threshold": 0.3,
            "match_count": limit,
            "filter_user_id": user_id  # Filters by patient if provided
        }
        rpc_res = supabase.rpc("match_chats", rpc_params).execute()

        # C. Decrypt and Format Results
        results = []
        for item in rpc_res.data:
            results.append({
                "id": item['id'],
                "user_id": item['user_id'],
                "confidence": f"{round(item['similarity'] * 100)}%",
                "dialogue": decrypt_data(item['content_encrypted']),
                "report": json.loads(decrypt_data(item['structured_data_encrypted'])),
                "domain": item['domain']
            })

        return {"results": results}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/user-timeline/{user_id}")
async def get_user_timeline(user_id: str):
    """
    Longitudinal View: Fetches chronological history for a specific patient.
    """
    try:
        res = supabase.table("chat_history") \
            .select("created_at", "sentiment", "structured_data_encrypted") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .execute()

        timeline = []
        for row in res.data:
            report = json.loads(decrypt_data(row['structured_data_encrypted']))
            timeline.append({
                "date": row['created_at'],
                "sentiment": row['sentiment'],
                "summary": report.get("plain_summary", "No summary provided")
            })
        return {"user_id": user_id, "history": timeline}
    except Exception as e:
        return {"status": "error", "message": str(e)}