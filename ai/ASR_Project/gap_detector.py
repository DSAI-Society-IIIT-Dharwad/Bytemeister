def detect_rule_based_gaps(domain, data, professional_name):
    gaps = []

    domain_l = (domain or "").lower()
    data = data or {}

    # convert symptoms safely
    symptoms_value = data.get("symptoms", [])
    if isinstance(symptoms_value, list):
        symptoms_text = " ".join(str(x) for x in symptoms_value).lower()
    else:
        symptoms_text = str(symptoms_value).lower()

    main_issue = str(data.get("main_issue", "")).lower()
    doctor_advice = str(data.get("doctor_advice", "")).lower()

    combined_text = f"{symptoms_text} {main_issue} {doctor_advice}"

    # -----------------------------
    # HEALTHCARE / MEDICAL RULES
    # -----------------------------
    if any(word in domain_l for word in ["health", "medical", "doctor", "gastro", "consultation", "medicine"]):
        # stomach / vomiting / food poisoning style cases
        stomach_case_words = [
            "vomit", "vomiting", "stomach", "abdomen", "pain",
            "food poisoning", "indigestion", "nausea", "gastric"
        ]

        if any(word in combined_text for word in stomach_case_words):
            if not data.get("symptom_onset_duration"):
                gaps.append({
                    "missing_question": "Since when exactly have the symptoms been happening?",
                    "why_it_matters": "Duration helps assess severity and possible cause.",
                    "priority": "high",
                    "missed_by": professional_name,
                    "category": "timeline"
                })

            if "fever" not in combined_text:
                gaps.append({
                    "missing_question": "Do you also have fever?",
                    "why_it_matters": "Fever helps distinguish infection severity.",
                    "priority": "medium",
                    "missed_by": professional_name,
                    "category": "symptom_check"
                })

            if "diarrhea" not in combined_text and "loose motion" not in combined_text and "loose motions" not in combined_text:
                gaps.append({
                    "missing_question": "Are you also having diarrhea or loose motions?",
                    "why_it_matters": "This is important in stomach infection or food poisoning cases.",
                    "priority": "medium",
                    "missed_by": professional_name,
                    "category": "symptom_check"
                })

            if "dehydration" not in combined_text and "water" not in combined_text and "fluids" not in combined_text:
                gaps.append({
                    "missing_question": "Are you able to drink water and are you feeling weak or dehydrated?",
                    "why_it_matters": "Hydration status is important in vomiting-related illness.",
                    "priority": "high",
                    "missed_by": professional_name,
                    "category": "severity_check"
                })

        # eye-related cases
        eye_case_words = ["eye", "eyes", "vision", "blur", "redness", "itching", "swelling"]
        if any(word in combined_text for word in eye_case_words):
            if "both" not in combined_text and "one eye" not in combined_text and "left eye" not in combined_text and "right eye" not in combined_text:
                gaps.append({
                    "missing_question": "Is the problem in one eye or both eyes?",
                    "why_it_matters": "Laterality helps narrow the likely cause.",
                    "priority": "high",
                    "missed_by": professional_name,
                    "category": "diagnostic_clarification"
                })

            if "vision loss" not in combined_text and "blurred" not in combined_text and "blurry" not in combined_text:
                gaps.append({
                    "missing_question": "Is your vision blurred or reduced?",
                    "why_it_matters": "Vision changes can indicate a more serious eye issue.",
                    "priority": "high",
                    "missed_by": professional_name,
                    "category": "severity_check"
                })

            if "injury" not in combined_text and "trauma" not in combined_text:
                gaps.append({
                    "missing_question": "Did this start after any injury, rubbing, or foreign object entering the eye?",
                    "why_it_matters": "Trauma history changes the likely diagnosis and urgency.",
                    "priority": "medium",
                    "missed_by": professional_name,
                    "category": "cause_check"
                })

        # vague treatment advice
        if doctor_advice and (
            "tablet" in doctor_advice
            or "medicine" in doctor_advice
            or "drops" in doctor_advice
            or "ointment" in doctor_advice
        ):
            if len(doctor_advice.split()) < 10:
                gaps.append({
                    "missing_question": "Which medicine, what dosage, and how often should it be taken?",
                    "why_it_matters": "Treatment is incomplete without clear medicine instructions.",
                    "priority": "high",
                    "missed_by": professional_name,
                    "category": "treatment_details"
                })

        # no follow-up / warning signs
        if "go to hospital" not in combined_text and "emergency" not in combined_text and "if it worsens" not in combined_text:
            gaps.append({
                "missing_question": "What warning signs should the patient watch for, and when should they seek urgent care?",
                "why_it_matters": "Patients need escalation guidance if symptoms worsen.",
                "priority": "medium",
                "missed_by": professional_name,
                "category": "follow_up"
            })

    # -----------------------------
    # FINANCE / BANKING RULES
    # -----------------------------
    if any(word in domain_l for word in ["finance", "bank", "banking", "loan", "payment", "kyc"]):
        all_text = str(data).lower()

        if "account" not in all_text and "customer id" not in all_text and "reference" not in all_text:
            gaps.append({
                "missing_question": "Can you confirm the account number, customer ID, or reference number?",
                "why_it_matters": "The issue cannot be processed without identifying the account or case.",
                "priority": "high",
                "missed_by": professional_name,
                "category": "verification"
            })

        if "amount" not in all_text and "emi" not in all_text and "balance" not in all_text:
            gaps.append({
                "missing_question": "What is the amount involved in this issue?",
                "why_it_matters": "Financial issues usually require the exact amount for resolution.",
                "priority": "medium",
                "missed_by": professional_name,
                "category": "transaction_details"
            })

        if "date" not in all_text and "due" not in all_text and "when" not in all_text:
            gaps.append({
                "missing_question": "When did this issue happen or what is the due date?",
                "why_it_matters": "Timing is important for tracing the issue and deciding next steps.",
                "priority": "medium",
                "missed_by": professional_name,
                "category": "timeline"
            })

        if "kyc" not in all_text and "verify" not in all_text and "verification" not in all_text:
            gaps.append({
                "missing_question": "Was the customer identity or KYC verification completed?",
                "why_it_matters": "Verification is often required before discussing account-specific details.",
                "priority": "high",
                "missed_by": professional_name,
                "category": "compliance"
            })

        if "next step" not in all_text and "resolved" not in all_text and "escalate" not in all_text:
            gaps.append({
                "missing_question": "What is the next step for resolving this issue?",
                "why_it_matters": "The customer should leave the call knowing what happens next.",
                "priority": "medium",
                "missed_by": professional_name,
                "category": "resolution_path"
            })

    return gaps


def merge_gaps(llm_gaps, rule_gaps):
    final_gaps = []
    seen = set()

    for gap in (llm_gaps or []) + (rule_gaps or []):
        if isinstance(gap, dict):
            question = (gap.get("missing_question", "") or "").strip().lower()
            if question and question not in seen:
                seen.add(question)
                final_gaps.append(gap)
        else:
            text = str(gap).strip()
            text_l = text.lower()
            if text and text_l not in seen:
                seen.add(text_l)
                final_gaps.append({
                    "missing_question": text,
                    "why_it_matters": "Identified by the model as relevant missing information.",
                    "priority": "medium",
                    "missed_by": "Professional",
                    "category": "general"
                })

    return final_gaps