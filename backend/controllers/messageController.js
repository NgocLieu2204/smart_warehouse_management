const axios = require("axios");
const preprocessMessage = require("../utils/preprocessMessage");

const MessageController = {
  async handleMessage(req, res) {
    const { message, sessionId } = req.body;

    if (!message) {
      return res.status(400).json({ status: "error", message: "Message is required" });
    }

    // 1️⃣ Preprocess message → tạo JSON chuẩn
    const processedData = preprocessMessage(message, sessionId);

    try {
      // 2️⃣ Gửi JSON đã chuẩn hóa đến webhook n8n và lấy phản hồi
      const webhookUrl = "https://haha23123.app.n8n.cloud/webhook-test/2454f903-5896-4fdc-bca4-c042c578cf1d";
      const response = await axios.post(webhookUrl, processedData, {
        headers: { "Content-Type": "application/json" }
      });

      // 3️⃣ Trả về kết quả từ webhook cho Flutter (có field "output")
      res.json(response.data);
    } catch (error) {
      console.error("Webhook error:", error.message);
      res.status(500).json({ status: "error", message: "Cannot send webhook" });
    }
  }
};

module.exports = MessageController;
