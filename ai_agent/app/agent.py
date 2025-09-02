from datetime import datetime
from langchain.agents import initialize_agent, Tool
from langchain_groq import ChatGroq
from dotenv import load_dotenv
import os
import json
from .database import db
from .config import GROQ_API_KEY, GROQ_MODEL
import re
from bson.objectid import ObjectId

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
        else:
            # Nếu là tiếng Việt tự nhiên → regex parse (ưu tiên trước)
            match = re.search(
                r"Nhập kho\s+(\d+)\s+(?:cái|đơn vị|sản phẩm)?\s*SKU\s+(\w+)\s+(?:vào|tại)\s+kho\s+(\w+)\s+bởi\s+(\w+)(?:,\s*ghi chú\s*(.*))?",
                args,
                re.IGNORECASE,
            )
            if match:
                qty, sku, wh, by, note = match.groups()
                data = {
                    "sku": sku,
                    "quantity": int(qty),
                    "warehouse": wh,
                    "by": by,
                    "note": note or ""
                }
            else:
                # Nếu không khớp regex → thử CSV
                parts = [p.strip() for p in args.split(",")]
                if len(parts) >= 4:
                    data = {
                        "quantity": int(parts[0]),
                        "sku": parts[1],
                        "warehouse": parts[2],
                        "by": parts[3],
                        "note": parts[4] if len(parts) > 4 else ""
                    }
                else:
                    return "❌ Không hiểu dữ liệu nhập kho."

        # Chuẩn hóa và lưu
        return add_inbound_transaction(
            data["sku"], int(data["quantity"]), data["warehouse"], data["by"], data.get("note", "")
        )

    except Exception as e:
        return f"❌ Lỗi xử lý inbound: {e}"


def outbound_tool_wrapper(args: str) -> str:
    try:
        # Nếu là JSON string
        if args.strip().startswith("{"):
            data = json.loads(args)
        else:
            # Nếu là tiếng Việt tự nhiên → regex parse (ưu tiên trước)
            match = re.search(
                r"Xuất kho\s+(\d+)\s+(?:cái|đơn vị|sản phẩm)?\s*SKU\s+(\w+)\s+(?:ra|từ|tại)\s+kho\s+(\w+)\s+bởi\s+(?:nhân viên\s+)?(\w+)(?:,\s*ghi chú\s*(.*))?",
                args,
                re.IGNORECASE,
            )
            if match:
                qty, sku, wh, by, note = match.groups()
                data = {
                    "sku": sku,
                    "quantity": int(qty),
                    "warehouse": wh,
                    "by": by,
                    "note": note or ""
                }
            else:
                # Nếu không khớp regex → thử CSV
                parts = [p.strip() for p in args.split(",")]
                if len(parts) >= 4:
                    data = {
                        "quantity": int(parts[0]),
                        "sku": parts[1],
                        "warehouse": parts[2],
                        "by": parts[3],
                        "note": parts[4] if len(parts) > 4 else ""
                    }
                else:
                    return "❌ Không hiểu dữ liệu xuất kho."

        # Chuẩn hóa và lưu
        return add_outbound_transaction(
            data["sku"], int(data["quantity"]), data["warehouse"], data["by"], data.get("note", "")
        )

    except Exception as e:
        return f"❌ Lỗi xử lý outbound: {e}"

# ============================================================
# Tool 7: Tìm kiếm transactions
# ============================================================

def search_transactions(user: str = None, wh: str = None, sku: str = None, limit: int = 10):
    q = {}
    if user:
        q["by"] = {"$regex": f"^{user}$", "$options": "i"}  # so khớp không phân biệt hoa/thường
    if wh:
        q["wh"] = wh
    if sku:
        q["sku"] = sku

    cursor = transactions.find(q).sort("at", -1).limit(limit)
    results = []
    for tx in cursor:
        results.append(
            f"{tx['at'].strftime('%Y-%m-%d %H:%M:%S')} | {tx['type']} {tx['qty']} "
            f"(SKU {tx['sku']}, Kho: {tx['wh']}, By: {tx['by']}, Note: {tx.get('note','')})"
        )

    return "\n".join(results) if results else "❌ Không tìm thấy giao dịch phù hợp."

# ============================================================
# Tool 10: Tìm kiếm sản phẩm trong inventories (có hình ảnh)
# ============================================================
def search_inventories(query: str = "", wh: str = None, sku: str = None, limit: int = 20) -> str:
    q = {}
    if wh:
        q["wh"] = wh
    if sku:
        q["sku"] = sku
    if query:
        # Tìm kiếm theo tên gần đúng (case-insensitive)
        q["name"] = {"$regex": query, "$options": "i"}

    cursor = inventories.find(q).limit(limit)
    results = []
    for item in cursor:
        line = (
            f"📦 {item.get('name','(no name)')} (SKU: {item.get('sku')})\n"
            f"   ➡ Số lượng: {item.get('qty',0)} {item.get('uom','EA')}\n"
            f"   ➡ Kho: {item.get('wh','?')} - Vị trí: {item.get('location','?')}\n"
        )
        # Nếu có imageUrl thì hiển thị
        if item.get("imageUrl"):
            line += f"   🖼 Ảnh: {item['imageUrl']}\n"
        results.append(line)

    return "\n".join(results) if results else "❌ Không tìm thấy sản phẩm phù hợp."
# ============================================================
# Tool 11: Lấy danh sách task đang mở
# ============================================================
def get_open_tasks(recent: bool = False):
    if recent:
        return "📋 Danh sách task đang mở (gần đây)."
    return "📋 Tất cả các task đang mở."
# ============================================================
# Tool 12: Tìm kiếm task theo SKU, kho, nhân viên
# ============================================================
def search_tasks(sku: str = None, warehouse: str = None, assignee: str = None):
    if sku:
        return f"📋 Các task liên quan tới SKU {sku}."
    if warehouse:
        return f"📋 Các task tại kho {warehouse}."
    if assignee:
        return f"📋 Các task được giao cho nhân viên {assignee}."
    return "❓ Bạn muốn tìm task theo SKU, kho hay nhân viên?"
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
    try:
        args = args.strip()
        if not args:
            return "❓ Bạn muốn tìm giao dịch theo user hay theo kho+SKU?"

        # 1. Tìm giao dịch theo user
        match = re.search(r"(?i)giao dịch.*(?:do|bởi)\s+người dùng\s*(\w+)", args)
        if not match:
            match = re.search(r"(?i)giao dịch.*user\s+(\w+)", args)
        if match:
            user = match.group(1).strip()
            return search_transactions(user=user)

        # 2. Tìm giao dịch theo kho + SKU
        match = re.search(r"(?i)giao dịch.*kho\s+(\w+).*sku\s+(\w+)", args)
        if match:
            wh = match.group(1).strip()
            sku = match.group(2).strip()
            return search_transactions(wh=wh, sku=sku)

        return "❌ Không hiểu yêu cầu tìm giao dịch."

    except Exception as e:
        return f"❌ Lỗi xử lý tìm kiếm giao dịch: {e}"
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
def search_inventories_tool(args: str) -> str:
    try:
        args = args.strip()
        if not args:
            return "❓ Bạn muốn tìm sản phẩm theo tên, SKU hay kho nào?"

        # Nếu input là JSON thì parse bình thường
        if args.startswith("{"):
            params = json.loads(args)
            return search_inventories(
                query=params.get("query"),
                wh=params.get("wh"),
                sku=params.get("sku"),
                limit=int(params.get("limit", 20))
            )

        # ================================
        # Regex tiếng Việt
        # ================================

        # 1. Tìm theo kho
        match = re.search(r"(?i)(liệt kê|danh sách).*kho\s+(\w+)", args)
        if match:
            wh = match.group(2)
            return search_inventories(wh=wh)

        # 2. Tìm theo tên sản phẩm chứa ...
        match = re.search(r"(?i)(có sản phẩm nào.*|tìm sản phẩm).*['\"]?([\w\s]+)['\"]?", args)
        if match:
            query = match.group(2).strip()
            return search_inventories(query=query)

        # 3. Tìm theo SKU (form: "mã MS001", "SKU SP123")
        match = re.search(r"(?i)(mã|sku|sản phẩm)\s*([A-Za-z0-9\-]+)", args)
        if match:
            sku = match.group(2).strip()
            return search_inventories(sku=sku, limit=1)

        # 4. Tìm theo tên đầy đủ (form: "thông tin sản phẩm <tên>")
        match = re.search(r"(?i)(thông tin|chi tiết|cho tôi biết).*(sản phẩm)\s+([\w\s]+)", args)
        if match:
            query = match.group(3).strip()
            return search_inventories(query=query, limit=5)

        return "❌ Không hiểu yêu cầu tìm kiếm sản phẩm."

    except Exception as e:
        return f"❌ Lỗi xử lý tìm kiếm sản phẩm: {e}"
def search_transactions_tool(args: str) -> str:
    try:
        args = args.strip()
        if not args:
            return "❓ Bạn muốn tìm giao dịch theo user hay theo kho+SKU?"

        # 1. Tìm giao dịch theo user
        match = re.search(r"(?i)(giao dịch).*user\s+(\w+)", args)
        if match:
            user = match.group(2).strip()
            return search_transactions(user=user)

        # 2. Tìm giao dịch theo kho + SKU
        match = re.search(r"(?i)(giao dịch).*kho\s+(\w+).*sku\s+(\w+)", args)
        if match:
            wh = match.group(2).strip()
            sku = match.group(3).strip()
            return search_transactions(wh=wh, sku=sku)

        return "❌ Không hiểu yêu cầu tìm giao dịch."

    except Exception as e:
        return f"❌ Lỗi xử lý tìm kiếm giao dịch: {e}"
def get_open_tasks(recent: bool = False):
    try:
        query = {"status": "open"}
        cursor = tasks.find(query)

        if recent:
            cursor = cursor.sort("created_at", -1).limit(5)

        docs = list(cursor)
        if not docs:
            return "✅ Không có task nào đang mở."

        result = "📋 Danh sách task đang mở:\n"
        for t in docs:
            due = t.get("due_at")
            if isinstance(due, datetime):
                due_str = due.strftime("%d-%m-%Y %H:%M")
            elif isinstance(due, str):
                try:
                    due_str = datetime.fromisoformat(due).strftime("%d-%m-%Y %H:%M")
                except:
                    due_str = due
            else:
                due_str = "N/A"

            result += f"- {t.get('_id')}: {t.get('title','(no title)')} (Hạn: {due_str})\n"

        return result
    except Exception as e:
        return f"❌ Lỗi khi lấy task: {e}"

def search_tasks(sku: str = None, wh: str = None, assignee: str = None):
    try:
        query = {}
        if sku:
            query["sku"] = sku
        if wh:
            query["warehouse"] = wh  # chắc chắn key trùng với Mongo
        if assignee:
            query["assignee"] = assignee

        print("👉 Query Mongo:", query)   # log query
        docs = list(tasks.find(query))
        print("👉 Docs found:", docs)     # log kết quả

        if not docs:
            return "🔎 Không tìm thấy task nào phù hợp."

        result = "🔎 Kết quả tìm kiếm task:\n"
        for t in docs:
            result += f"- {t.get('_id')}: {t.get('title','(no title)')} | Trạng thái: {t.get('status','N/A')}\n"

        return result
    except Exception as e:
        return f"❌ Lỗi khi tìm task: {e}"

def get_task_by_id(task_id: str):
    task = tasks.find_one({"_id": ObjectId(task_id)})
    if not task:
        return f"❌ Không tìm thấy task với id {task_id}"

    return (
        f"📝 Task ID: {task_id}\n"
        f"📌 Tiêu đề: {task.get('title', 'Không có')}\n"
        f"👤 Người phụ trách: {task.get('assignee', 'Không có')}\n"
        f"🏷️ SKU: {task.get('sku', 'Không có')}\n"
        f"📦 Warehouse: {task.get('warehouse', 'Không có')}\n"
        f"⚡ Trạng thái: {task.get('status', 'Không rõ')}\n"
        f"⏰ Ngày tạo: {task.get('created_at', 'Không có')}\n"
    )


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
       name="MongoDBOutboundRecorder",
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
    # Tìm kiếm sản phẩm trong inventories
    Tool(
        name="SearchProductTool",
        func=search_inventories_tool,
        description="Tìm kiếm thông tin sản phẩm theo tên, SKU hoặc kho. "
                    "Ví dụ: 'Cho tôi biết thông tin sản phẩm MS001' hoặc "
                    "'Cho tôi biết thông tin sản phẩm điện thoại thông minh' hoặc "
                    "'Liệt kê sản phẩm trong kho WH01'."
    ),
    # Tìm kiếm giao dịch theo user hoặc kho+SKU
    Tool(
            name="SearchTransactionsTool",
            func=search_transactions_tool,
            description=(
                "Tìm kiếm giao dịch theo user hoặc theo kho + SKU. "
                "Ví dụ: 'Tìm tất cả giao dịch do user An thực hiện.' hoặc "
                "'Liệt kê giao dịch tại kho WH01 của SKU LT001.'"
            )
    ),
    Tool(
        name="GetOpenTasksTool",
        func=get_open_tasks,
        description=(
            "Trả về danh sách các task đang mở hoặc task mở gần đây. "
            "Ví dụ: 'Có những task nào đang mở?' hoặc "
            "'Danh sách task open gần đây.'"
        )
    ),
    Tool(
        name="SearchTasksTool",
        func=lambda query: search_tasks(
            sku=extract_sku(query),
            wh=extract_wh(query),
            assignee=extract_assignee(query)
        ),
        description="Tìm task theo SKU, warehouse hoặc assignee."
    ),
    Tool(
        name="GetTaskByIdTool",
        func=get_task_by_id,
        description="Trả về thông tin chi tiết của một task theo id."
    )

]

# ============================================================
# Helper functions to extract sku, warehouse, assignee from query string
# ============================================================
def extract_sku(query: str):
    match = re.search(r"(sku|mã)\s*([A-Za-z0-9\-]+)", query, re.IGNORECASE)
    if match:
        return match.group(2).strip()
    return None

def extract_wh(query: str):
    match = re.search(r"(kho)\s*([A-Za-z0-9\-]+)", query, re.IGNORECASE)
    if match:
        return match.group(2).strip()
    return None

def extract_assignee(query: str):
    match = re.search(r"(assignee|nhân viên|user)\s*([A-Za-z0-9\-]+)", query, re.IGNORECASE)
    if match:
        return match.group(2).strip()
    return None

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
