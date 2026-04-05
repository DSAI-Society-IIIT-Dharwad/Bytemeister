import streamlit as st
import os
from history_manager import load_pair_history, save_to_pair_history
from main_dynamic import run_tracker_pipeline

st.set_page_config(page_title="IndicEcho Pro Gemini", layout="wide")
st.title("👥 IndicEcho Pro: AI Studio Cloud Edition")

c1, c2 = st.columns(2)
p1 = c1.text_input("Person 1", "Rahul")
p2 = c2.text_input("Person 2", "Dr. Smith")

file = st.file_uploader("Upload Audio/Video", type=["wav", "mp3", "m4a", "mp4"])

if file and st.button("🚀 Process Conversation"):
    ext = os.path.splitext(file.name)[1]
    temp_name = f"temp_input{ext}"
    with open(temp_name, "wb") as f: f.write(file.getbuffer())
    
    with st.spinner("Gemini 2.0 Flash is analyzing..."):
        result = run_tracker_pipeline(temp_name, p1, p2)
        if result:
            save_to_pair_history(p1, p2, result)
            st.rerun()

st.divider()
history = load_pair_history(p1, p2)
st.subheader(f"📜 Activity Logs for {p1} ↔ {p2}")

if not history["calls"]:
    st.info("No history yet.")
else:
    for call in reversed(history["calls"]):
        ext_data = call.get('extracted_data', {})
        with st.expander(f"📅 Log: {call.get('timestamp')} | {ext_data.get('domain_detected')}"):
            colA, colB = st.columns(2)
            summ = call.get('speaker_summaries', {})
            with colA:
                st.info(f"👤 **{p1}**")
                for line in summ.get(p1, []): st.write(f"• {line}")
            with colB:
                st.success(f"👔 **{p2}**")
                for line in summ.get(p2, []): st.write(f"• {line}")
            
            st.write("---")
            st.json(ext_data.get('dynamic_fields', {}))
            st.warning(f"📝 **Summary:** {ext_data.get('overall_summary')}")

if st.sidebar.button("📂 Open Folder"): os.startfile("history")