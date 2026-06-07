const express = require('express');
const {
  getAdminDashboard,
  getServices,
  addService,
  updateService,
  getReports,
  addExpense,
  getExpenses
} = require('../controllers/adminController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/dashboard', authMiddleware, getAdminDashboard);
router.get('/services', authMiddleware, getServices);
router.post('/services', authMiddleware, addService);
router.put('/services', authMiddleware, updateService);
router.get('/reports', authMiddleware, getReports);
router.get('/expenses', authMiddleware, getExpenses);
router.post('/expenses', authMiddleware, addExpense);

module.exports = router;
