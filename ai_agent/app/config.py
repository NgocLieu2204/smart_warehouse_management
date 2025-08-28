import os
from dotenv import load_dotenv

# ============================================================
# Load biến môi trường từ file .env
# ============================================================
load_dotenv()

# ============================================================
# Các biến cấu hình
# ============================================================

# API Key cho GROQ
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# URL MongoDB (nếu bạn kết nối tới database)
MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://levancu976:levancu%40123@cluster0.hbapxy4.mongodb.net/smart_warehouse_management?retryWrites=true&w=majority&appName=Cluster0")

# Tên database
MONGO_DB = os.getenv("MONGO_DB", "smart_warehouse_management")

GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3-70b-8192")
# ============================================================
# Kiểm tra để đảm bảo key được load
# ============================================================
if not GROQ_API_KEY:
    raise ValueError("🚨 Lỗi: Chưa cấu hình GROQ_API_KEY trong file .env")
