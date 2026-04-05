import streamlit as st
import os
import pandas as pd

from history_manager import load_pair_history, save_to_pair_history
from main_dynamic import run_tracker_pipeline

st.set_page_config(page_title="IndicEcho Pro: AI Consultant", layout="wide")

st.title("🏥 IndicEcho Pro: AI Consultant Dashboard")
st.caption("Multilingual ASR + Expert Gap Analysis + Backend Sync")

# --- Sidebar Inputs ---
with st.sidebar:
    st.header("Session Settings")
    p1 = st.text_input("Patient/Client Name", "Rahul")
    p2 = st.text_input("Professional Name", "Dr. Smith")

    if st.button("📂 Open History Folder"):
        try:
            os.startfile("history")
        except Exception:
            st.warning("Could not open history folder automatically.")

# --- Main Uploader ---
file = st.file_uploader(
    "Upload Consultation (MP4/MP3/WAV)",
    type=["wav", "mp3", "m4a", "mp4"]
)

if file and st.button("🚀 Analyze & Audit Consultation"):
    ext = os.path.splitext(file.name)[1]
    temp_path = f"temp_in{ext}"

    with open(temp_path, "wb") as f:
        f.write(file.getbuffer())

    with st.spinner("AI Consultant is auditing the conversation..."):
        result = run_tracker_pipeline(temp_path, p1, p2)

        if result:
            save_to_pair_history(p1, p2, result)
            st.success(f"Analysis Complete! Sync Status: {result['sync']}")

            with st.expander("🕒 Performance Insights"):
                st.table(
                    pd.DataFrame(
                        list(result["timings"].items()),
                        columns=["Step", "Duration"]
                    )
                )

            st.rerun()

st.divider()

# --- History Display ---
history = load_pair_history(p1, p2)
st.subheader(f"📜 Audit Logs for {p1} ↔ {p2}")

if not history["calls"]:
    st.info("Upload a file to see the AI Consultant's audit.")
else:
    for call in reversed(history["calls"]):
        data = call.get("extracted_data", {})

        with st.expander(
            f"📅 Record: {call.get('timestamp')} | {data.get('domain_detected', 'Unknown Domain')}"
        ):
            # 1. OVERALL SUMMARY
            st.markdown("### 🧾 Overall Summary")
            st.write(data.get("overall_summary", "No summary available."))

            st.write("---")

            # 2. MISSING INFO DETECTIVE
            st.markdown("### 🚨 Missing Info Detective")
            gaps = data.get("missing_info_detective", [])

            if gaps:
                for gap in gaps:
                    if isinstance(gap, dict):
                        st.markdown(
                            f"**Missing Question:** {gap.get('missing_question', 'N/A')}"
                        )
                        st.write(
                            f"**Why it matters:** {gap.get('why_it_matters', 'N/A')}"
                        )
                        st.write(
                            f"**Priority:** {gap.get('priority', 'N/A')}"
                        )
                        st.write(
                            f"**Missed by:** {gap.get('missed_by', 'N/A')}"
                        )
                        st.write(
                            f"**Category:** {gap.get('category', 'N/A')}"
                        )
                        st.write("---")
                    else:
                        st.write(f"- {gap}")
            else:
                st.success("✅ Audit Passed: No major missing professional questions detected.")

            # 3. ACTION ITEMS
            st.markdown("### ✅ Next Steps / Action Items")
            c_act1, c_act2 = st.columns(2)
            actions = data.get("action_items", {})

            with c_act1:
                st.write(f"**For {p1}:**")
                person1_actions = actions.get(p1, [])
                if person1_actions:
                    for a in person1_actions:
                        st.write(f"- {a}")
                else:
                    st.write("No action items.")

            with c_act2:
                st.write(f"**For {p2}:**")
                person2_actions = actions.get(p2, [])
                if person2_actions:
                    for a in person2_actions:
                        st.write(f"- {a}")
                else:
                    st.write("No action items.")

            st.write("---")

            # 4. SPEAKER SUMMARIES
            st.markdown("### 🗣️ Speaker Summaries")
            c1, c2 = st.columns(2)
            summ = call.get("speaker_summaries", {})

            with c1:
                st.info(f"👤 **{p1}** (Key Points)")
                p1_summary = summ.get(p1, [])
                if p1_summary:
                    for line in p1_summary:
                        st.write(f"• {line}")
                else:
                    st.write("No summary available.")

            with c2:
                st.success(f"👔 **{p2}** (Key Points)")
                p2_summary = summ.get(p2, [])
                if p2_summary:
                    for line in p2_summary:
                        st.write(f"• {line}")
                else:
                    st.write("No summary available.")

            st.write("---")

            # 5. STRUCTURED DATA
            st.markdown("### 📦 Extracted Structured Data")
            st.json(data.get("dynamic_fields", {}))

            # 6. OPTIONAL RAW TRANSCRIPT
            raw_text = call.get("raw_transcript", "")
            if raw_text:
                st.write("---")
                with st.expander("📝 Raw Transcript"):
                    st.write(raw_text)

            # 7. OPTIONAL ENGLISH TRANSCRIPT
            english_text = call.get("english_transcript", "")
            if english_text:
                with st.expander("🌐 English Transcript"):
                    st.write(english_text)