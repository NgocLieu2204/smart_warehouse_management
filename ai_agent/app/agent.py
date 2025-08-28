from datetime import datetime
from langchain.agents import initialize_agent, Tool
from langchain_groq import ChatGroq
from dotenv import load_dotenv
import os
import json
from .database import db
from .config import GROQ_API_KEY, GROQ_MODEL

# ============================================================
# Load biến môi trường
# ============================================================
load_dotenv()

# ============================================================
# MongoDB Collections
# ============================================================
transactions = db["transactions"]
tasks = db["tasks"]
inventories = db["inventories"]

# ============================================================
# INVENTORIES
# ============================================================
def get_stock_by_sku(sku: str) -> str:
    pipeline = [
        {"$match": {"sku": sku}},
        {"$group": {
            "_id": "$sku",
            "inbound": {"$sum": {"$cond": [{"$eq": ["$type", "inbound"]}, "$qty", 0]}},
            "outbound": {"$sum": {"$cond": [{"$eq": ["$type", "outbound"]}, "$qty", 0]}}
        }},
        {"$project": {"sku": "$_id", "stock": {"$subtract": ["$inbound", "$outbound"]}}}
    ]
    result = list(transactions.aggregate(pipeline))
    if result:
        new_qty = result[0]['stock']
        inventories.update_one(
            {"sku": sku},
            {"$set": {"qty": new_qty, "updatedAt": datetime.utcnow()}}
        )
        item = inventories.find_one({"sku": sku})
        uom = item.get("uom", "sản phẩm") if item else "sản phẩm"
        return f"📦 SKU {sku} hiện còn {new_qty} {uom} trong kho."
    else:
        return f"❌ Không tìm thấy SKU {sku} trong transaction log."

def get_stock_by_name(name: str) -> str:
    item = inventories.find_one({"name": name})
    if not item:
        return f"❌ Không tìm thấy sản phẩm '{name}' trong kho."
    return get_stock_by_sku(item["sku"])

def search_inventories(args: str) -> str:
    try:
        params = json.loads(args)
    except Exception as e:
        return f"❌ Lỗi parse input: {e}"
    query = {}
    if "sku" in params: query["sku"] = params["sku"]
    if "name" in params: query["name"] = {"$regex": params["name"], "$options": "i"}
    if "wh" in params: query["wh"] = params["wh"]
    cursor = inventories.find(query).limit(int(params.get("limit", 10)))
    items = [f"{i['sku']} - {i['name']} ({i['qty']} {i['uom']} tại {i['wh']})" for i in cursor]
    return "\n".join(items) if items else "❌ Không tìm thấy sản phẩm nào."

# ============================================================
# TRANSACTIONS
# ============================================================
def get_transaction_history(sku: str, limit: int = 5) -> str:
    cursor = transactions.find({"sku": sku}).sort("at", -1).limit(limit)
    logs = []
    for t in cursor:
        logs.append(
            f"{t['at'].strftime('%Y-%m-%d %H:%M:%S')} - {t['type']} {t['qty']} "
            f"(by {t['by']}, wh: {t['wh']}, note: {t.get('note','')})"
        )
    return "\n".join(logs) if logs else f"❌ Không có giao dịch nào cho {sku}."

def add_inbound_transaction(sku: str, qty: int, wh: str, by: str, note: str = "") -> str:
    doc = {"sku": sku, "type": "inbound", "qty": int(qty), "wh": wh,
           "at": datetime.utcnow(), "by": by, "note": note}
    transactions.insert_one(doc)
    get_stock_by_sku(sku)
    return f"✅ Đã ghi nhận nhập {qty} sản phẩm (SKU {sku}) vào kho {wh} bởi {by}."

def add_outbound_transaction(sku: str, qty: int, wh: str, by: str, note: str = "") -> str:
    doc = {"sku": sku, "type": "outbound", "qty": int(qty), "wh": wh,
           "at": datetime.utcnow(), "by": by, "note": note}
    transactions.insert_one(doc)
    get_stock_by_sku(sku)
    return f"✅ Đã ghi nhận xuất {qty} sản phẩm (SKU {sku}) từ kho {wh} bởi {by}."

def search_transactions(args: str) -> str:
    try:
        params = json.loads(args)
    except Exception as e:
        return f"❌ Lỗi parse input: {e}"
    query = {}
    if "by" in params: query["by"] = params["by"]
    if "wh" in params: query["wh"] = params["wh"]
    if "sku" in params: query["sku"] = params["sku"]
    cursor = transactions.find(query).sort("at", -1).limit(int(params.get("limit", 10)))
    logs = [f"{t['at'].strftime('%Y-%m-%d %H:%M:%S')} - {t['sku']} - {t['type']} {t['qty']} "
            f"(by {t['by']}, wh: {t['wh']}, note: {t.get('note','')})" for t in cursor]
    return "\n".join(logs) if logs else "❌ Không tìm thấy giao dịch phù hợp."

# ============================================================
# TASKS
# ============================================================
def get_open_tasks(limit: int = 10) -> str:
    cursor = tasks.find({"status": "open"}).sort("created_at", -1).limit(limit)
    items = [f"{t['_id']} - {t['type']} (sku={t['payload'].get('sku')}, wh={t['payload'].get('wh')})"
             for t in cursor]
    return "\n".join(items) if items else "❌ Không có task nào đang mở."

def assign_task(args: str) -> str:
    try:
        params = json.loads(args)
        task_id = params["task_id"]
        assignee = params["assignee"]
    except Exception as e:
        return f"❌ Input phải có task_id và assignee. Lỗi: {e}"
    result = tasks.update_one({"_id": task_id}, {"$set": {"assignee": assignee}})
    return "✅ Đã gán task." if result.modified_count else "❌ Không tìm thấy task."

def complete_task(task_id: str) -> str:
    if not task_id:
        return "❌ Thiếu task_id. Hãy cung cấp ID task cần hoàn thành."
    result = tasks.update_one({"_id": task_id}, {"$set": {"status": "done"}})
    return "✅ Task đã hoàn thành." if result.modified_count else "❌ Không tìm thấy task."

def search_tasks(args: str) -> str:
    try:
        params = json.loads(args)
    except Exception as e:
        return f"❌ Lỗi parse input: {e}"
    query = {}
    if "sku" in params: query["payload.sku"] = params["sku"]
    if "wh" in params: query["payload.wh"] = params["wh"]
    if "assignee" in params: query["assignee"] = params["assignee"]
    cursor = tasks.find(query).limit(int(params.get("limit", 10)))
    items = [f"{t['_id']} - {t['type']} ({t['status']}, sku={t['payload'].get('sku')})"
             for t in cursor]
    return "\n".join(items) if items else "❌ Không tìm thấy task nào."

# ============================================================
# WRAPPER (Hỏi lại khi thiếu input)
# ============================================================
def stock_tool(args: str) -> str:
    sku = args.strip()
    if not sku:
        return "📦 Bạn muốn kiểm tra tồn kho của sản phẩm nào? Hãy nhập mã SKU."
    return get_stock_by_sku(sku)

def transaction_history_tool(args: str) -> str:
    sku = args.strip()
    if not sku:
        return "📜 Bạn muốn xem lịch sử giao dịch của sản phẩm nào? Hãy nhập mã SKU."
    return get_transaction_history(sku)

def inbound_tool_wrapper(args: str) -> str:
    if not args.strip():
        return "📥 Bạn muốn nhập kho cho sản phẩm nào? Format: sku,qty,wh,by,note"
    return add_inbound_transaction(*[p.strip() for p in args.split(",")[:4]])

def outbound_tool_wrapper(args: str) -> str:
    if not args.strip():
        return "📤 Bạn muốn xuất kho cho sản phẩm nào? Format: sku,qty,wh,by,note"
    return add_outbound_transaction(*[p.strip() for p in args.split(",")[:4]])

def complete_task_wrapper(args: str) -> str:
    task_id = args.strip()
    if not task_id:
        return "📝 Bạn muốn hoàn thành task nào? Hãy nhập task_id."
    return complete_task(task_id)

# ============================================================
# Khởi tạo Tools
# ============================================================
tools = [
    # Inventories
    Tool(
        name="MongoDBStockBySKU",
        func=get_stock_by_sku,
        description="Dùng khi người dùng cung cấp rõ mã SKU. Trả về tồn kho hiện tại của SKU đó từ MongoDB."
    ),
    Tool(
        name="MongoDBStockByName",
        func=get_stock_by_name,
        description="Dùng khi người dùng chỉ nhớ hoặc nhập tên sản phẩm. Tìm SKU theo tên, sau đó trả về tồn kho."
    ),
    Tool(
        name="MongoDBInventorySearcher",
        func=search_inventories,
        description="Tìm kiếm nhiều sản phẩm trong kho. Input phải là JSON, có thể gồm: "
                    '{"sku": "...", "name": "...", "wh": "...", "limit": N}. '
                    "Trả về danh sách SKU, tên, số lượng tồn và kho lưu trữ."
    ),
    Tool(
        name="MongoDBStockCheckerWrapper",
        func=stock_tool,
        description="Dùng khi người dùng hỏi chung chung về tồn kho nhưng chưa nhập SKU. "
                    "Tool sẽ hỏi lại user để lấy SKU."
    ),
    
    # Transactions
    Tool(
        name="MongoDBTransactionHistory",
        func=get_transaction_history,
        description="Dùng khi user nhập SKU và muốn xem lịch sử giao dịch gần đây. "
                    "Trả về danh sách inbound/outbound của SKU."
    ),
    Tool(
        name="MongoDBTransactionHistoryWrapper",
        func=transaction_history_tool,
        description="Dùng khi user muốn xem lịch sử giao dịch nhưng chưa nhập SKU. "
                    "Tool sẽ hỏi lại user để bổ sung SKU."
    ),
    Tool(
        name="MongoDBInboundRecorderWrapper",
        func=inbound_tool_wrapper,
        description="Dùng để ghi nhận giao dịch nhập kho (inbound). Input format: sku,qty,wh,by,note. "
                    "Nếu thiếu tham số sẽ hỏi lại user."
    ),
    Tool(
        name="MongoDBOutboundRecorderWrapper",
        func=outbound_tool_wrapper,
        description="Dùng để ghi nhận giao dịch xuất kho (outbound). Input format: sku,qty,wh,by,note. "
                    "Nếu thiếu tham số sẽ hỏi lại user."
    ),
    Tool(
        name="MongoDBTransactionSearcher",
        func=search_transactions,
        description="Dùng khi cần lọc nhiều giao dịch. Input là JSON có thể gồm: "
                    '{"sku": "...", "wh": "...", "by": "...", "limit": N}. '
                    "Trả về danh sách giao dịch phù hợp."
    ),

    # Tasks
    Tool(name="MongoDBOpenTasks", func=get_open_tasks, description="Danh sách task đang mở."),
    Tool(name="MongoDBTaskAssigner", func=assign_task, description="Gán người thực hiện cho task."),
    Tool(name="MongoDBTaskCompleterWrapper", func=complete_task_wrapper, description="Đánh dấu task hoàn thành, nếu thiếu task_id thì hỏi lại."),
    Tool(name="MongoDBTaskSearcher", func=search_tasks, description="Tìm kiếm task theo tiêu chí."),
]


# ============================================================
# Khởi tạo LLM & Agent
# ============================================================
llm = ChatGroq(model=GROQ_MODEL, groq_api_key=GROQ_API_KEY, temperature=0)

agent = initialize_agent(
    tools,
    llm,
    agent="chat-zero-shot-react-description",
    verbose=True,
    handle_parsing_errors=True,
    return_intermediate_steps=False,
    agent_kwargs={
        "prefix": "Bạn là trợ lý quản lý kho. Luôn dùng tool MongoDB để trả lời. "
                  "Không bịa ra thông tin. Nếu thiếu dữ liệu, hãy hỏi lại user."
    }
)



print("✅ Agent đã khởi tạo thành công")
