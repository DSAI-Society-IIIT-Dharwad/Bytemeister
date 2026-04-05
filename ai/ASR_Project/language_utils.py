def detect_language_code(text: str) -> str:
    for ch in text:
        code = ord(ch)

        # Kannada
        if 0x0C80 <= code <= 0x0CFF:
            return "kn-IN"

        # Devanagari / Hindi
        if 0x0900 <= code <= 0x097F:
            return "hi-IN"

    # Default assume English-ish / Roman text
    return "en-IN"