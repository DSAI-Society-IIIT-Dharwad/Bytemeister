import os
import sys
import time
import shutil
import logging
import traceback
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# Import your pipeline logic
from main_dynamic import run_tracker_pipeline
from history_manager import save_to_pair_history
from chat_assistant import answer_query_from_history

# ---------------------------------------------------------------------------
# Logging Setup
# ---------------------------------------------------------------------------
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
log = logging.getLogger("api_server")

app = FastAPI(title="IndicEcho API Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# ENDPOINT: Upload and Process Audio
# ---------------------------------------------------------------------------
@app.post("/upload-audio")
async def upload_audio(
    file: UploadFile = File(...),
    Patient: str = Form(...),
    Doctor: str = Form(...),
):
    start_time = time.perf_counter()
    
    log.info("──────────────────────────────────────────────────")
    log.info("📥 NEW UPLOAD REQUEST RECEIVED")
    log.info(f"   Filename: {file.filename}")
    log.info(f"   Patient Name: '{Patient}'")
    log.info(f"   Doctor Name:  '{Doctor}'")
    
    # 1. Standardize the User ID (This is what the Chatbot looks for)
    user_id = f"{Patient.strip().replace(' ', '_')}_{Doctor.strip().replace(' ', '_')}"
    log.info(f"🔑 Generated User ID: {user_id}")

    # 2. Save the incoming file
    ext = os.path.splitext(file.filename or "")[1] or ".wav"
    temp_name = f"temp_upload_{int(time.time())}{ext}"
    
    try:
        log.debug(f"💾 Saving file to disk as: {temp_name}...")
        with open(temp_name, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        file_size = os.path.getsize(temp_name) / 1024
        log.info(f"✅ File saved successfully ({file_size:.2f} KB)")

        # 3. Run the Pipeline (ASR -> Translate -> Gemini)
        log.info("🚀 Launching AI Pipeline (main_dynamic.run_tracker_pipeline)...")
        pipeline_start = time.perf_counter()
        
        result = run_tracker_pipeline(temp_name, Patient, Doctor)
        
        pipeline_duration = time.perf_counter() - pipeline_start
        log.info(f"⚙️ Pipeline Finished in {pipeline_duration:.2f}s")

        if result:
            # 4. Save to History Folder
            log.info(f"📂 Archiving analysis into history/{user_id}.json...")
            save_to_pair_history(Patient, Doctor, result)
            log.info("✅ Archive complete.")
            
            # Clean up
            if os.path.exists(temp_name): os.remove(temp_name)
            
            total_duration = time.perf_counter() - start_time
            log.info(f"🏆 SUCCESS: Total Request Time: {total_duration:.2f}s")
            log.info("──────────────────────────────────────────────────")

            return JSONResponse(
                status_code=200, 
                content={
                    "status": "success", 
                    "user_id": user_id, 
                    "data": result['extracted_data']
                }
            )
        else:
            log.error("⚠️ Pipeline returned None. Check main_dynamic logs.")
            return JSONResponse(status_code=500, content={"status": "error", "message": "AI failed to extract data."})
        
    except Exception as e:
        log.error("❌ CRITICAL ERROR IN UPLOAD ENDPOINT")
        log.error(f"Error Type: {type(e).__name__}")
        log.error(f"Message: {str(e)}")
        log.error(traceback.format_exc())
        
        if os.path.exists(temp_name): os.remove(temp_name)
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})

# ---------------------------------------------------------------------------
# ENDPOINT: Chat Assistant (RAG)
# ---------------------------------------------------------------------------
@app.post("/chat-assistant")
async def chat_assistant(user_id: str = Form(...), query: str = Form(...)):
    log.info(f"💬 CHAT QUERY: ID='{user_id}' | Text='{query}'")
    answer = answer_query_from_history(user_id, query)
    return {"status": "success", "answer": answer}

if __name__ == "__main__":
    import uvicorn
    log.info("IndicEcho Server starting on port 8080...")
    uvicorn.run(app, host="0.0.0.0", port=8080)