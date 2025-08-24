from langchain_groq import ChatGroq
import os
from dotenv import load_dotenv

# Load biến môi trường
load_dotenv()

llm = ChatGroq(
    model="llama-3.3-70b-versatile",
    groq_api_key=os.getenv("GROQ_API_KEY"),
    temperature=0
)

resp = llm.invoke("Xin chào, bạn có chạy được không?")
print(resp)
