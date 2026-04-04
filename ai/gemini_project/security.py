from cryptography.fernet import Fernet
import os
from dotenv import load_dotenv

load_dotenv()

# Get key from .env or generate a temporary one if missing
key_str = os.getenv("ENCRYPTION_KEY")
if not key_str:
    # This is just for testing. In production, always use the .env key!
    print("WARNING: ENCRYPTION_KEY not found in .env. Generating a temporary one.")
    key = Fernet.generate_key()
else:
    key = key_str.encode()

cipher = Fernet(key)

def encrypt_data(data: str) -> str:
    return cipher.encrypt(data.encode()).decode()

def decrypt_data(token: str) -> str:
    return cipher.decrypt(token.encode()).decode()