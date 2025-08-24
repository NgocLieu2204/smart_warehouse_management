# main.py
from fastapi import FastAPI, Request
from pydantic import BaseModel
from app.agent import (
    agent,
    rebuild_inventory,
    rebuild_and_sync_inventory,
    get_stock_by_sku,
    get_transaction_history,
    inbound_tool,
    outbound_tool,
    search_transactions_tool
)

app = FastAPI()

# ============================================================
# Model cho request query chatbot
# ============================================================
class QueryRequest(BaseModel):
    query: str

# ============================================================
# Chatbot endpoint
# ============================================================
@app.post("/ask")
async def ask_agent(req: QueryRequest):
    try:
        response = agent.invoke({"input": req.query})
        return {"response": response["output"]}
    except Exception as e:
        return {"error": str(e)}

# ============================================================
# Rebuild inventory endpoint
# ============================================================
@app.post("/rebuild_inventory")
async def rebuild_inventory_api():
    """Cập nhật tồn kho cơ bản từ transaction log"""
    result = rebuild_inventory()
    return {"message": result}

# ============================================================
# Rebuild & sync nâng cao
# ============================================================
@app.post("/sync_inventory")
async def rebuild_and_sync_inventory_api():
    """Đồng bộ inventory nâng cao từ transaction log"""
    result = rebuild_and_sync_inventory()
    return {"message": result}

# ============================================================
# Stock checker endpoint
# ============================================================
class SKURequest(BaseModel):
    sku: str

@app.post("/stock")
async def stock_endpoint(req: SKURequest):
    result = get_stock_by_sku(req.sku)
    return {"message": result}

# ============================================================
# Transaction history endpoint
# ============================================================
@app.post("/history")
async def history_endpoint(req: SKURequest):
    result = get_transaction_history(req.sku)
    return {"message": result}

# ============================================================
# Inbound / Outbound endpoints
# ============================================================
class TransactionRequest(BaseModel):
    args: str  # format: sku,qty,wh,by,note

@app.post("/inbound")
async def inbound_endpoint(req: TransactionRequest):
    result = inbound_tool(req.args)
    return {"message": result}

@app.post("/outbound")
async def outbound_endpoint(req: TransactionRequest):
    result = outbound_tool(req.args)
    return {"message": result}

# ============================================================
# Search transactions endpoint
# ============================================================
class SearchRequest(BaseModel):
    query: str  # JSON string: {"by":"...","wh":"...","sku":"...","limit":5}

@app.post("/search_transactions")
async def search_transactions_endpoint(req: SearchRequest):
    result = search_transactions_tool(req.query)
    return {"message": result}
