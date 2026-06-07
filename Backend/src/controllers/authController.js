const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const login = async (req, res) => {
  try {
    const { login, password } = req.body;

    if (!login || !password) {
      return res.status(400).json({
        success: false,
        message: 'Phone/email and password are required'
      });
    }

    const [rows] = await db.execute(
      `SELECT
        u.user_id,
        u.person_id,
        u.password,
        u.role,
        u.status,
        p.full_name,
        p.sex,
        p.phone,
        p.email,
        c.customer_id,
        s.staff_id
      FROM users u
      INNER JOIN people p ON p.person_id = u.person_id
      LEFT JOIN customers c ON c.user_id = u.user_id
      LEFT JOIN staff s ON s.user_id = u.user_id
      WHERE p.phone = ? OR p.email = ?
      LIMIT 1`,
      [login, login]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid login credentials'
      });
    }

    const user = rows[0];

    if (user.status !== 'Active') {
      return res.status(403).json({
        success: false,
        message: 'This account is inactive'
      });
    }

    const isBcryptHash = /^\$2[aby]\$\d{2}\$/.test(user.password);
    const passwordMatches = isBcryptHash
      ? await bcrypt.compare(password, user.password)
      : password === user.password;

    if (!passwordMatches) {
      return res.status(401).json({
        success: false,
        message: 'Invalid login credentials'
      });
    }

    if (!isBcryptHash) {
      const hashedPassword = await bcrypt.hash(password, 10);
      await db.execute(
        'UPDATE users SET password = ? WHERE user_id = ?',
        [hashedPassword, user.user_id]
      );
    }

    const token = jwt.sign(
      {
        user_id: user.user_id,
        person_id: user.person_id,
        role: user.role,
        customer_id: user.customer_id,
        staff_id: user.staff_id
      },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        user_id: user.user_id,
        person_id: user.person_id,
        full_name: user.full_name,
        sex: user.sex,
        phone: user.phone,
        email: user.email,
        role: user.role,
        status: user.status,
        customer_id: user.customer_id,
        staff_id: user.staff_id
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message
    });
  }
};

const verifyForgotPassword = async (req, res) => {
  try {
    const { login } = req.body;

    if (!login) {
      return res.status(400).json({
        success: false,
        message: 'Phone or email is required'
      });
    }

    const [rows] = await db.execute(
      `SELECT
        u.user_id,
        u.person_id,
        u.role,
        u.status,
        p.full_name,
        p.sex,
        p.phone,
        p.email
      FROM users u
      INNER JOIN people p ON p.person_id = u.person_id
      WHERE p.phone = ? OR p.email = ?
      LIMIT 1`,
      [login, login]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No account found with that phone or email'
      });
    }

    const user = rows[0];

    if (user.status !== 'Active') {
      return res.status(403).json({
        success: false,
        message: 'This account is inactive'
      });
    }

    const resetToken = jwt.sign(
      {
        user_id: user.user_id,
        person_id: user.person_id,
        purpose: 'password_reset'
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    return res.status(200).json({
      success: true,
      message: 'Account verified',
      reset_token: resetToken,
      user: {
        user_id: user.user_id,
        person_id: user.person_id,
        full_name: user.full_name,
        sex: user.sex,
        phone: user.phone,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Password reset verification failed',
      error: error.message
    });
  }
};

const resetForgotPassword = async (req, res) => {
  try {
    const { reset_token, password, confirm_password } = req.body;

    if (!reset_token || !password || !confirm_password) {
      return res.status(400).json({
        success: false,
        message: 'reset_token, password, and confirm_password are required'
      });
    }

    if (password !== confirm_password) {
      return res.status(400).json({
        success: false,
        message: 'Password and confirm password do not match'
      });
    }

    const decoded = jwt.verify(reset_token, process.env.JWT_SECRET);

    if (decoded.purpose !== 'password_reset') {
      return res.status(401).json({
        success: false,
        message: 'Invalid password reset token'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.execute(
      'UPDATE users SET password = ? WHERE user_id = ?',
      [hashedPassword, decoded.user_id]
    );

    return res.status(200).json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired password reset token',
      error: error.message
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const { newPassword } = req.body;
    const userId = req.user.user_id;

    if (!newPassword) {
      return res.status(400).json({
        success: false,
        message: 'New password is required'
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const [result] = await db.execute(
      'UPDATE users SET password = ? WHERE user_id = ?',
      [hashedPassword, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to change password',
      error: error.message
    });
  }
};

module.exports = {
  login,
  verifyForgotPassword,
  resetForgotPassword,
  changePassword
};
