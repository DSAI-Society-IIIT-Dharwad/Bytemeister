import json
import os
from pathlib import Path
from datetime import datetime

HISTORY_BASE_DIR = Path("history")
HISTORY_BASE_DIR.mkdir(exist_ok=True)

def get_pair_id(patient_name, doctor_name):
    p = patient_name.strip().replace(" ", "_")
    d = doctor_name.strip().replace(" ", "_")
    return f"{p}_{d}"

def load_pair_history(patient_name, doctor_name):
    pair_id = get_pair_id(patient_name, doctor_name)
    file_path = HISTORY_BASE_DIR / f"{pair_id}.json"
    if file_path.exists():
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"patient": patient_name, "doctor": doctor_name, "calls": []}

def save_to_pair_history(patient_name, doctor_name, call_data):
    pair_id = get_pair_id(patient_name, doctor_name)
    history = load_pair_history(patient_name, doctor_name)
    call_data["timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    history["calls"].append(call_data)
    file_path = HISTORY_BASE_DIR / f"{pair_id}.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2, ensure_ascii=False)
    return history