const express = require('express');
const { connectDB } = require('./configs/db');
const dotenv = require('dotenv');
const cors = require('cors');
const inventoryRouter = require('./router/InventoryRouter');
const taskRouter = require('./router/taskRouter'); // 1. Thêm import cho taskRouter

dotenv.config();

const app = express();
app.use(cors()); // Enable CORS for all routes
app.use(express.json());
app.use('/api/inventory', inventoryRouter);
app.use('/api/tasks', taskRouter); // 2. Thêm route cho tasks

const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Failed to connect to the database:', error.message);
    process.exit(1); // Exit process with failure
  });