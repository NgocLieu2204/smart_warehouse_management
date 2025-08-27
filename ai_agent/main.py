from fastapi import FastAPI
from pydantic import BaseModel
from app.agent import (
    agent,
    get_stock_by_sku,
    get_transaction_history,
    inbound_tool_wrapper,
    outbound_tool_wrapper,
    search_transactions,
    search_inventories
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
        return {"response": response["output"]}
    except Exception as e:
        return {"error": str(e)}

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
    result = inbound_tool_wrapper(req.args)
    return {"message": result}

@app.post("/outbound")
async def outbound_endpoint(req: TransactionRequest):
    result = outbound_tool_wrapper(req.args)
    return {"message": result}

# ============================================================
# Search transactions endpoint
# ============================================================
class SearchRequest(BaseModel):
    query: str  # JSON string: {"by":"...","wh":"...","sku":"...","limit":5}

@app.post("/search_transactions")
async def search_transactions_endpoint(req: SearchRequest):
    result = search_transactions(req.query)
    return {"message": result}
