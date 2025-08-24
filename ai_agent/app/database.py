from pymongo import MongoClient
from .config import MONGO_URI, MONGO_DB

client = MongoClient(MONGO_URI)
db = client[MONGO_DB]
inventory_collection = db["inventories"]
transaction_collection = db["transactions"]
task_collection = db["tasks"]
