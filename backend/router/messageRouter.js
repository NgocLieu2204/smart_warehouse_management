const express = require("express");
const router = express.Router();
const MessageController = require("../controllers/messageController");

router.post("/", MessageController.handleMessage);

module.exports = router;
