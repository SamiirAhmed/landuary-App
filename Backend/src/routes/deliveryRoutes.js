const express = require('express');
const {
  getPickupOrders,
  markPickedUp,
  markDelivered
} = require('../controllers/deliveryController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/orders', authMiddleware, getPickupOrders);
router.put('/picked-up', authMiddleware, markPickedUp);
router.put('/delivered', authMiddleware, markDelivered);

module.exports = router;
