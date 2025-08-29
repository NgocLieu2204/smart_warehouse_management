from fastapi import FastAPI
from pydantic import BaseModel
from app.agent import (
    agent,
    stock_tool,
    transaction_history_tool,
    inbound_tool_wrapper,
    outbound_tool_wrapper,
    search_transactions_tool,
    rebuild_inventory_wrapper,
    rebuild_and_sync_inventory_wrapper
)

app = FastAPI()

# ============================================================
# Model cho request query chatbot
# ============================================================
class QueryRequest(BaseModel):
    query: str

@app.post("/ask")
async def ask_agent(req: QueryRequest):
    try:
        response = agent.invoke({"input": req.query})
        # agent.invoke trả về dict: {"output": "..."} hoặc lỗi
        return {"response": response.get("output", "🤖 Bot không trả lời được.")}
    except Exception as e:
        return {"error": str(e)}

# ============================================================
# Stock checker endpoint (wrapper)
# ============================================================
class SKURequest(BaseModel):
    sku: str = ""

@app.post("/stock")
async def stock_endpoint(req: SKURequest):
    # stock_tool sẽ hỏi lại nếu sku trống
    result = stock_tool(req.sku)
    return {"message": result}

# ============================================================
# Transaction history endpoint (wrapper)
# ============================================================
@app.post("/history")
async def history_endpoint(req: SKURequest):
    result = transaction_history_tool(req.sku)
    return {"message": result}

# ============================================================
# Inbound / Outbound endpoints (wrapper)
# ============================================================
class TransactionRequest(BaseModel):
    args: str = ""  # format: sku,qty,wh,by,note

@app.post("/inbound")
async def inbound_endpoint(req: TransactionRequest):
    result = inbound_tool_wrapper(req.args)
    return {"message": result}

@app.post("/outbound")
async def outbound_endpoint(req: TransactionRequest):
    result = outbound_tool_wrapper(req.args)
    return {"message": result}

# ============================================================
# Search transactions endpoint (wrapper)
# ============================================================
class SearchRequest(BaseModel):
    query: str = ""  # JSON string: {"by":"...","wh":"...","sku":"...","limit":5}

@app.post("/search_transactions")
async def search_transactions_endpoint(req: SearchRequest):
    result = search_transactions_tool(req.query)
    return {"message": result}

# ============================================================
# Rebuild / Sync inventory endpoints (wrapper)
# ============================================================
class ConfirmRequest(BaseModel):
    confirm: str = ""  # user phải nhập "yes" để thực hiện

@app.post("/rebuild_inventory")
async def rebuild_inventory_endpoint(req: ConfirmRequest):
    result = rebuild_inventory_wrapper(req.confirm)
    return {"message": result}

@app.post("/rebuild_and_sync_inventory")
async def rebuild_and_sync_inventory_endpoint(req: ConfirmRequest):
    result = rebuild_and_sync_inventory_wrapper(req.confirm)
    return {"message": result}
