const express = require('express');
const {
  makePayment,
  getPaymentsByOrder
} = require('../controllers/paymentController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/make', authMiddleware, makePayment);
router.get('/order/:order_id', authMiddleware, getPaymentsByOrder);

module.exports = router;
