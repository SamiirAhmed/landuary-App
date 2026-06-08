const express = require('express');
const {
  registerStaff,
  getStaffDashboard,
  getStaffOrders,
  getCustomerBalances,
  getStaffList,
  updateStaffStatus,
  updateStaff,
  deleteStaff
} = require('../controllers/staffController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/register', registerStaff);
router.get('/dashboard', authMiddleware, getStaffDashboard);
router.get('/orders', authMiddleware, getStaffOrders);
router.get('/customer-balances', authMiddleware, getCustomerBalances);
router.get('/list', authMiddleware, getStaffList);
router.put('/status', authMiddleware, updateStaffStatus);
router.put('/update', authMiddleware, updateStaff);
router.delete('/delete', authMiddleware, deleteStaff);

module.exports = router;
