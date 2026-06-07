const bcrypt = require('bcryptjs');
const db = require('../config/db');

const registerCustomer = async (req, res) => {
  try {
    const {
      full_name,
      phone,
      sex,
      email,
      city_id,
      district_id,
      password,
      confirm_password
    } = req.body;

    if (!full_name || !sex || !phone || !email || !city_id || !district_id || !password || !confirm_password) {
      return res.status(400).json({
        success: false,
        message: 'full_name, phone, sex, email, city_id, district_id, password, and confirm_password are required'
      });
    }

    if (!['Male', 'Female'].includes(sex)) {
      return res.status(400).json({
        success: false,
        message: 'sex must be Male or Female'
      });
    }

    if (password !== confirm_password) {
      return res.status(400).json({
        success: false,
        message: 'Password and confirm password do not match'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.execute(
      'CALL sp_register_customer(?, ?, ?, ?, ?, ?, ?, ?)',
      [
        full_name,
        phone,
        sex,
        email,
        city_id,
        district_id,
        hashedPassword,
        hashedPassword
      ]
    );

    const [rows] = await db.execute(
      `SELECT
        c.customer_id,
        u.user_id,
        p.person_id,
        p.full_name,
        p.sex,
        p.phone,
        p.email,
        c.city_id,
        c.district_id,
        c.register_date
      FROM customers c
      INNER JOIN users u ON u.user_id = c.user_id
      INNER JOIN people p ON p.person_id = u.person_id
      WHERE p.phone = ?
      LIMIT 1`,
      [phone]
    );

    return res.status(201).json({
      success: true,
      message: 'Customer registered successfully',
      customer: rows[0] || null
    });
  } catch (error) {
    const statusCode = error.sqlState === '45000' ? 400 : 500;

    return res.status(statusCode).json({
      success: false,
      message: error.sqlMessage || 'Customer registration failed',
      error: error.message
    });
  }
};

module.exports = {
  registerCustomer
};
