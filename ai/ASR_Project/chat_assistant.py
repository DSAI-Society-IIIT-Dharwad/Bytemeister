import os
import json
import logging
from google import genai
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

def answer_query_from_history(user_id, query):
    # 1. Debugging Info
    history_dir = "history"
    print(f"\n[RAG DEBUG] --- New Query ---")
    print(f"[RAG DEBUG] Requested User ID: {user_id}")
    print(f"[RAG DEBUG] Looking in directory: {os.path.abspath(history_dir)}")

    # 2. Smart File Search (Handles case sensitivity and minor naming differences)
    target_filename = f"{user_id}.json".lower()
    found_file = None
    
    if os.path.exists(history_dir):
        files = os.listdir(history_dir)
        print(f"[RAG DEBUG] Files found in history folder: {files}")
        for f in files:
            if f.lower() == target_filename:
                found_file = os.path.join(history_dir, f)
                break
    
    if not found_file:
        print(f"[RAG DEBUG] FAIL: No match found for {target_filename}")
        return f"I don't have a record for '{user_id}'. I see these files: {os.listdir(history_dir) if os.path.exists(history_dir) else 'None'}"

    # 3. Load the data
    try:
        with open(found_file, "r", encoding="utf-8") as f:
            history_data = json.load(f)
        print(f"[RAG DEBUG] SUCCESS: Loaded {found_file}")
    except Exception as e:
        return f"Error reading history file: {e}"
    
    if not history_data.get("calls"):
        return "The record exists, but no calls have been processed yet."

    # 4. Context Building
    context_text = ""
    for idx, call in enumerate(history_data["calls"]):
        ext = call.get("extracted_data", {})
        context_text += f"\n[Call Date: {call.get('timestamp')}]\n"
        context_text += f"Summary: {ext.get('overall_summary')}\n"
        context_text += f"Details: {json.dumps(ext.get('dynamic_fields'))}\n"

    # 5. Gemini RAG Call
   # ... (Keep the file loading logic the same)

    # 4. Construct a Smarter Prompt
    prompt = f"""
    You are the IndicEcho Assistant. 
    
    CONTEXT FROM PREVIOUS CALLS:
    {context_text if context_text else "No past conversations recorded yet."}

    USER QUERY: "{query}"

    INSTRUCTIONS:
    1. If the user is just saying hello or starting an interaction, greet them warmly and tell them you are ready to answer questions about their history.
    2. If they ask about symptoms or medical details:
       - If the info is in the CONTEXT, provide a detailed answer.
       - If the CONTEXT is empty, say: "I haven't processed any audio calls for this session yet. Please upload a recording first so I can help you."
       - If the CONTEXT exists but doesn't mention that specific detail, say: "That specific detail wasn't mentioned in our previous recorded conversations."
    3. Always be professional and helpful.
    """

    try:
        response = client.models.generate_content(model="gemma-4-26b-a4b-it", contents=prompt)
        return response.text
    except Exception as e:
        return f"Gemini Error: {e}"