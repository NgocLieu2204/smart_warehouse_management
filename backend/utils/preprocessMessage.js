function preprocessMessage(message, sessionId) {
  const skuMatch = message.match(/SP\d{3}/i);
  const whMatch = message.match(/WH\d{2}/i);
  const qtyMatch = message.match(/(\d+)\s*(cái|EA|pcs)/i);
  const byMatch = message.match(/student\d{2}/i);

  // JSON chuẩn
  const result = {
    meta: {
      sessionId: sessionId || null,
      rawMessage: message || null,
    },
    inventory: {
      sku: null,
      wh: null
    },
    transactions: {
      sku: null,
      qty: null,
      wh: null,
      by: null,
      at: null
    },
    tasks: {
      type: null,
      status: null,
      created_at: null,
      sku: null,
      wh: null
    }
  };

  // Nếu có nhắc tới tồn kho → fill inventory
  if (/tồn kho|inventory/i.test(message)) {
    if (skuMatch) result.inventory.sku = skuMatch[0];
    if (whMatch) result.inventory.wh = whMatch[0];
  }

  // Nếu có nhắc tới nhập/xuất/giao → fill transactions
  if (/nhập kho|xuất kho|giao/i.test(message)) {
    result.transactions.at = new Date().toISOString();
    if (skuMatch) result.transactions.sku = skuMatch[0];
    if (qtyMatch) result.transactions.qty = parseInt(qtyMatch[1]);
    if (whMatch) result.transactions.wh = whMatch[0];
    if (byMatch) result.transactions.by = byMatch[0];
  }

  // Nếu có nhắc tới kiểm kê → fill tasks
  if (/kiểm kê|cycle_count/i.test(message)) {
    result.tasks.type = "cycle_count";
    result.tasks.status = "open";
    result.tasks.created_at = new Date().toISOString();
    if (skuMatch) result.tasks.sku = skuMatch[0];
    if (whMatch) result.tasks.wh = whMatch[0];
  }

  return result;
}

module.exports = preprocessMessage;
