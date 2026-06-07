const express = require('express');
const {
  createOrder,
  getOrdersByCustomer,
  getOrderById,
  updateOrderStatus
} = require('../controllers/orderController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/create', authMiddleware, createOrder);
router.put('/status', authMiddleware, updateOrderStatus);
router.get('/customer/:customer_id', authMiddleware, getOrdersByCustomer);
router.get('/:order_id', authMiddleware, getOrderById);

module.exports = router;
