const express = require('express');
const {
  login,
  verifyForgotPassword,
  resetForgotPassword,
  changePassword
} = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/login', login);
router.post('/forgot-password/verify', verifyForgotPassword);
router.post('/forgot-password/reset', resetForgotPassword);
router.post('/change-password', authMiddleware, changePassword);

module.exports = router;
