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
# Tool 1: Tính tồn kho hiện tại theo SKU (và update inventories)
# ============================================================
def get_stock_by_sku(sku: str) -> str:
    pipeline = [
        {"$match": {"sku": sku}},
        {"$group": {
            "_id": "$sku",
            "inbound": {"$sum": {"$cond": [{"$eq": ["$type", "inbound"]}, "$qty", 0]}},
            "outbound": {"$sum": {"$cond": [{"$eq": ["$type", "outbound"]}, "$qty", 0]}}
        }},
        {"$project": {
            "sku": "$_id",
            "stock": {"$subtract": ["$inbound", "$outbound"]}
        }}
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

# ============================================================
# Tool 1b: Tính tồn kho theo tên (và update inventories)
# ============================================================
def get_stock_by_name(name: str) -> str:
    item = inventories.find_one({"name": name})
    if not item:
        return f"❌ Không tìm thấy sản phẩm '{name}' trong kho."
    sku = item["sku"]

    pipeline = [
        {"$match": {"sku": sku}},
        {"$group": {
            "_id": "$sku",
            "inbound": {"$sum": {"$cond": [{"$eq": ["$type", "inbound"]}, "$qty", 0]}},
            "outbound": {"$sum": {"$cond": [{"$eq": ["$type", "outbound"]}, "$qty", 0]}}
        }},
        {"$project": {
            "sku": "$_id",
            "stock": {"$subtract": ["$inbound", "$outbound"]}
        }}
    ]
    result = list(transactions.aggregate(pipeline))
    if result:
        new_qty = result[0]["stock"]
        inventories.update_one(
            {"sku": sku},
            {"$set": {"qty": new_qty, "updatedAt": datetime.utcnow()}}
        )
        return f"📦 Sản phẩm '{name}' (SKU: {sku}) hiện còn {new_qty} {item['uom']} trong kho."
    else:
        return f"❌ Không tìm thấy transaction log cho sản phẩm '{name}' (SKU: {sku})."

# ============================================================
# Tool 2: Lấy lịch sử giao dịch gần nhất
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

# ============================================================
# Tool 3: Ghi nhận inbound (cập nhật inventories luôn)
# ============================================================
def add_inbound_transaction(sku: str, qty: int, wh: str, by: str, note: str = "") -> str:
    doc = {"sku": sku, "type": "inbound", "qty": int(qty), "wh": wh,
           "at": datetime.utcnow(), "by": by, "note": note}
    transactions.insert_one(doc)
    # Sau khi insert → cập nhật lại tồn kho
    get_stock_by_sku(sku)
    return f"✅ Đã ghi nhận nhập {qty} sản phẩm (SKU {sku}) vào kho {wh} bởi {by}."

# ============================================================
# Tool 4: Ghi nhận outbound (cập nhật inventories luôn)
# ============================================================
def add_outbound_transaction(sku: str, qty: int, wh: str, by: str, note: str = "") -> str:
    doc = {"sku": sku, "type": "outbound", "qty": int(qty), "wh": wh,
           "at": datetime.utcnow(), "by": by, "note": note}
    transactions.insert_one(doc)
    # Sau khi insert → cập nhật lại tồn kho
    get_stock_by_sku(sku)
    return f"✅ Đã ghi nhận xuất {qty} sản phẩm (SKU {sku}) từ kho {wh} bởi {by}."

# ============================================================
# Tool 5 & 6: Wrapper inbound / outbound
# ============================================================


def inbound_tool_wrapper(args: str) -> str:
    try:
        # Nếu là JSON string
        if args.strip().startswith("{"):
            data = json.loads(args)
            sku = data["sku"]
            qty = int(data["qty"])
            wh = data["wh"]
            by = data["by"]
            note = data.get("note", "")
            return add_inbound_transaction(sku, qty, wh, by, note)

        # Nếu là CSV string
        parts = [p.strip() for p in args.split(",")]
        if len(parts) >= 4:
            sku, qty, wh, by = parts[:4]
            note = parts[4] if len(parts) > 4 else ""
            return add_inbound_transaction(sku, int(qty), wh, by, note)

        # Nếu là tiếng Việt tự nhiên → regex parse
        match = re.search(r"(Nhập kho\s+(\d+)\s+cái\s+SKU\s+(\w+)\s+vào\s+kho\s+(\w+)\s+bởi\s+(\w+)(?:,\s*ghi chú\s*(.*))?", args, re.IGNORECASE)
        if match:
            qty, sku, wh, by, note = match.groups()
            return add_inbound_transaction(sku, int(qty), wh, by, note or "")

        return "❌ Không hiểu dữ liệu nhập kho."
    except Exception as e:
        return f"❌ Lỗi xử lý inbound: {e}"

def outbound_tool_wrapper(args: str) -> str:
    try:
        # Nếu là JSON string
        if args.strip().startswith("{"):
            data = json.loads(args)
            sku = data["sku"]
            qty = int(data["qty"])
            wh = data["wh"]
            by = data["by"]
            note = data.get("note", "")
            return add_inbound_transaction(sku, qty, wh, by, note)

        # Nếu là CSV string
        parts = [p.strip() for p in args.split(",")]
        if len(parts) >= 4:
            sku, qty, wh, by = parts[:4]
            note = parts[4] if len(parts) > 4 else ""
            return add_outbound_transaction(sku, int(qty), wh, by, note)

        # Nếu là tiếng Việt tự nhiên → regex parse
        match = re.search(r"(Xuất kho\s+(\d+)\s+cái\s+SKU\s+(\w+)\s+vào\s+kho\s+(\w+)\s+bởi\s+(\w+)(?:,\s*ghi chú\s*(.*))?", args, re.IGNORECASE)
        if match:
            qty, sku, wh, by, note = match.groups()
            return add_outbound_transaction(sku, int(qty), wh, by, note or "")

        return "❌ Không hiểu dữ liệu nhập kho."
    except Exception as e:
        return f"❌ Lỗi xử lý inbound: {e}"

# ============================================================
# Tool 7: Tìm kiếm transactions
# ============================================================
def search_transactions(by: str = None, wh: str = None, sku: str = None, limit: int = 10) -> str:
    query = {}
    if by: query["by"] = by
    if wh: query["wh"] = wh
    if sku: query["sku"] = sku
    cursor = transactions.find(query).sort("at", -1).limit(limit)
    logs = []
    for t in cursor:
        logs.append(f"{t['at'].strftime('%Y-%m-%d %H:%M:%S')} - {t['sku']} - {t['type']} {t['qty']} "
                    f"(by {t['by']}, wh: {t['wh']}, note: {t.get('note','')})")
    return "\n".join(logs) if logs else "❌ Không tìm thấy giao dịch phù hợp."

def search_transactions_tool(args: str) -> str:
    try:
        params = json.loads(args)
    except Exception as e:
        return f"❌ Lỗi parse input: {e}"
    return search_transactions(by=params.get("by"),
                               wh=params.get("wh"),
                               sku=params.get("sku"),
                               limit=int(params.get("limit", 10)))

# ============================================================
# Tool 8: Rebuild inventory toàn bộ (update inventories)
# ============================================================
def rebuild_inventory() -> str:
    skus = transactions.distinct("sku")
    updated = 0
    for sku in skus:
        pipeline = [
            {"$match": {"sku": sku}},
            {"$group": {"_id": "$sku",
                        "inbound": {"$sum": {"$cond": [{"$eq": ["$type", "inbound"]}, "$qty", 0]}},
                        "outbound": {"$sum": {"$cond": [{"$eq": ["$type", "outbound"]}, "$qty", 0]}}
                        }},
            {"$project": {"sku": "$_id", "stock": {"$subtract": ["$inbound", "$outbound"]}}}
        ]
        result = list(transactions.aggregate(pipeline))
        if result:
            stock = result[0]["stock"]
            item = inventories.find_one({"sku": sku})
            if item:
                inventories.update_one({"sku": sku}, {"$set": {"qty": stock, "updatedAt": datetime.utcnow()}})
            else:
                inventories.insert_one({"sku": sku, "name": sku, "qty": stock, "uom": "EA",
                                        "wh": "UNKNOWN", "location": "UNKNOWN", "exp": None,
                                        "imageUrl": "", "updatedAt": datetime.utcnow()})
            updated += 1
    return f"✅ Đã cập nhật tồn kho cho {updated} SKU dựa trên transaction log."

# ============================================================
# Tool 9: Rebuild & Sync nâng cao (toàn bộ inventories)
# ============================================================
def rebuild_and_sync_inventory() -> str:
    skus = transactions.distinct("sku")
    updated = 0
    for sku in skus:
        pipeline = [
            {"$match": {"sku": sku}},
            {"$group": {"_id": "$sku",
                        "inbound": {"$sum": {"$cond": [{"$eq": ["$type", "inbound"]}, "$qty", 0]}},
                        "outbound": {"$sum": {"$cond": [{"$eq": ["$type", "outbound"]}, "$qty", 0]}}
                        }},
            {"$project": {"sku": "$_id", "stock": {"$subtract": ["$inbound", "$outbound"]}}}
        ]
        result = list(transactions.aggregate(pipeline))
        if not result: 
            continue
        stock = result[0]["stock"]
        item = inventories.find_one({"sku": sku})
        if item:
            inventories.update_one({"sku": sku}, {"$set": {"qty": stock, "updatedAt": datetime.utcnow()}})
        else:
            inventories.insert_one({"sku": sku, "name": sku, "qty": stock, "uom": "EA",
                                    "wh": "UNKNOWN", "location": "UNKNOWN", "exp": None,
                                    "imageUrl": "", "updatedAt": datetime.utcnow()})
        updated += 1
    return f"✅ Đã đồng bộ và cập nhật tồn kho cho {updated} SKU."

# ============================================================
# Wrapper cho các Tool
# ============================================================
def stock_tool(args: str) -> str:
    sku = args.strip()
    if not sku:
        return " Bạn muốn kiểm tra tồn kho của sản phẩm nào? Vui lòng cung cấp mã SKU."
    return get_stock_by_sku(sku)

def transaction_history_tool(args: str) -> str:
    sku = args.strip()
    if not sku:
        return " Bạn muốn xem lịch sử giao dịch của sản phẩm nào? Vui lòng cung cấp mã SKU."
    return get_transaction_history(sku)

def search_transactions_tool(args: str) -> str:
    if not args.strip():
        return " Bạn muốn tìm giao dịch theo SKU nào hoặc tiêu chí nào? Hãy cung cấp JSON filter."
    try:
        params = json.loads(args)
    except Exception as e:
        return f" Lỗi parse input: {e}"
    return search_transactions(by=params.get("by"),
                               wh=params.get("wh"),
                               sku=params.get("sku"),
                               limit=int(params.get("limit", 10)))
def rebuild_inventory_wrapper(args: str = "") -> str:
    confirm = args.strip().lower()
    if confirm not in ["yes", "y", "ok", "đồng ý", "xác nhận"]:
        return "⚠️ Bạn có chắc muốn rebuild tồn kho toàn bộ từ transaction log không? Trả lời 'yes' để tiếp tục."
    return rebuild_inventory()

def rebuild_and_sync_inventory_wrapper(args: str = "") -> str:
    confirm = args.strip().lower()
    if confirm not in ["yes", "y", "ok", "đồng ý", "xác nhận"]:
        return "⚠️ Bạn có chắc muốn đồng bộ inventory toàn bộ từ transaction log không? Trả lời 'yes' để tiếp tục."
    return rebuild_and_sync_inventory()

# ============================================================
# Khởi tạo danh sách Tools
# ============================================================
tools = [
    #Tinh tồn kho
    Tool(name="MongoDBStockChecker", func=get_stock_by_sku,
         description="Tính tồn kho theo SKU."),
    #Tính tồn kho theo tên sản phẩm
    Tool(name="MongoDBStockByName", func=get_stock_by_name,
         description="Tính tồn kho theo tên sản phẩm."),
    #Lịch sử giao dịch
    Tool(name="MongoDBTransactionHistory", func=get_transaction_history,
         description="Xem lịch sử giao dịch theo SKU."),
    #Nhập kho
    Tool(
        name="MongoDBInboundRecorder",
        func=inbound_tool_wrapper,
        description="Ghi nhận nhập kho (hỗ trợ CSV, JSON hoặc tiếng Việt)."
    ),
    #Xuất kho
    Tool(
       name="MongoDBInboundRecorder",
       func=outbound_tool_wrapper,
       description="Ghi nhận xuất kho (hỗ trợ CSV, JSON hoặc tiếng Việt)."
    ),
    Tool(name="MongoDBTransactionSearcher", func=search_transactions_tool,
         description="Tìm kiếm transaction theo filter JSON."),
    Tool(name="MongoDBRebuildInventory", func=rebuild_inventory,
         description="Rebuild tồn kho từ transaction log."),
    Tool(name="MongoDBRebuildAndSyncInventory", func=rebuild_and_sync_inventory,
         description="Đồng bộ tồn kho toàn bộ."),
    # Wrapper Tools để hỏi lại khi user thiếu input
    Tool(name="MongoDBStockCheckerWrapper", func=stock_tool,
         description="Kiểm tra tồn kho. Nếu thiếu SKU thì hỏi lại."),
    Tool(name="MongoDBTransactionHistoryWrapper", func=transaction_history_tool,
         description="Xem lịch sử giao dịch. Nếu thiếu SKU thì hỏi lại."),
    Tool(name="MongoDBSearchTransactionsWrapper", func=search_transactions_tool,
         description="Tìm giao dịch. Nếu thiếu JSON filter thì hỏi lại."),
    Tool(name="MongoDBInboundRecorderWrapper", func=inbound_tool_wrapper,
         description="Ghi nhận nhập kho. Nếu thiếu tham số thì hỏi lại."),
    Tool(name="MongoDBOutboundRecorderWrapper", func=outbound_tool_wrapper,
         description="Ghi nhận xuất kho. Nếu thiếu tham số thì hỏi lại."),
    Tool(name="MongoDBRebuildInventoryWrapper", func=rebuild_inventory_wrapper,
         description="Rebuild tồn kho. Nếu user chưa xác nhận thì hỏi lại."),
    Tool(name="MongoDBRebuildAndSyncInventoryWrapper", func=rebuild_and_sync_inventory_wrapper,
         description="Đồng bộ tồn kho. Nếu user chưa xác nhận thì hỏi lại."),
]

# ============================================================
# Khởi tạo LLM & Agent
# ============================================================
llm = ChatGroq(model=GROQ_MODEL, groq_api_key=GROQ_API_KEY, temperature=0)

agent = initialize_agent(
    tools,
    llm,
    agent="zero-shot-react-description",
    verbose=True,
    handle_parsing_errors=True,   # tránh crash
    return_intermediate_steps=False
)


print("✅ Agent đã khởi tạo thành công"),
