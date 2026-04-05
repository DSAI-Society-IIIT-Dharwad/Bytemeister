import os
from google import genai
from dotenv import load_dotenv
load_dotenv()

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
try:
    # Testing the most basic model name possible
    res = client.models.generate_content(model="gemini-1.5-flash", contents="say hello")
    print("API IS ALIVE:", res.text)
except Exception as e:
    print("API IS DEAD. Error:", e)