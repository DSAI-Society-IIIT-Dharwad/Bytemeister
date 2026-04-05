import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

print("--- YOUR ALLOWED MODELS ---")
# Using the correct attribute 'supported_methods'
for m in client.models.list():
    if 'generate_content' in m.supported_methods:
        print(f"ID: {m.name}")