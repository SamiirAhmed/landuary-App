const bcrypt = require('bcryptjs');
const db = require('../config/db');

const registerStaff = async (req, res) => {
  try {
    const {
      full_name,
      phone,
      sex,
      email,
      has_login,
      password,
      confirm_password,
      role,
      position,
      salary,
      hire_date
    } = req.body;

    const hasLogin = has_login === true || has_login === 1 || has_login === '1';

    if (!full_name || !sex || !phone || !email || has_login === undefined || !position || salary === undefined || !hire_date) {
      return res.status(400).json({
        success: false,
        message: 'full_name, phone, sex, email, has_login, position, salary, and hire_date are required'
      });
    }

    if (!['Male', 'Female'].includes(sex)) {
      return res.status(400).json({
        success: false,
        message: 'sex must be Male or Female'
      });
    }

    if (hasLogin && (!password || !confirm_password || !role)) {
      return res.status(400).json({
        success: false,
        message: 'password, confirm_password, and role are required when has_login is true'
      });
    }

    if (hasLogin && !['Staff', 'Delivery'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'role must be Staff or Delivery'
      });
    }

    if (hasLogin && password !== confirm_password) {
      return res.status(400).json({
        success: false,
        message: 'Password and confirm password do not match'
      });
    }

    const hashedPassword = hasLogin ? await bcrypt.hash(password, 10) : null;

    await db.execute(
      'CALL sp_register_staff(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        full_name,
        phone,
        sex,
        email,
        hasLogin ? 1 : 0,
        hashedPassword,
        hashedPassword, // same hash — JS already verified password === confirm_password
        hasLogin ? role : null,
        position,
        salary,
        hire_date
      ]
    );

    const [rows] = await db.execute(
      `SELECT
        s.staff_id,
        s.person_id,
        s.user_id,
        p.full_name,
        p.sex,
        p.phone,
        p.email,
        u.role,
        s.position,
        s.salary,
        s.hire_date,
        s.status
      FROM staff s
      INNER JOIN people p ON p.person_id = s.person_id
      LEFT JOIN users u ON u.user_id = s.user_id
      WHERE p.phone = ?
      LIMIT 1`,
      [phone]
    );

    return res.status(201).json({
      success: true,
      message: 'Staff registered successfully',
      staff: rows[0] || null
    });
  } catch (error) {
    const statusCode = error.sqlState === '45000' ? 400 : 500;

    return res.status(statusCode).json({
      success: false,
      message: error.sqlMessage || 'Staff registration failed',
      error: error.message
    });
  }
};

const getStaffDashboard = async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT order_status, COUNT(*) AS total
      FROM orders
      WHERE order_status IN ('Pending', 'Accepted', 'Washing', 'Ironing', 'Ready')
      GROUP BY order_status`
    );

    const dashboard = {
      new_orders: 0,
      accepted_orders: 0,
      washing_orders: 0,
      ironing_orders: 0,
      ready_orders: 0
    };

    rows.forEach((row) => {
      if (row.order_status === 'Pending') dashboard.new_orders = row.total;
      if (row.order_status === 'Accepted') dashboard.accepted_orders = row.total;
      if (row.order_status === 'Washing') dashboard.washing_orders = row.total;
      if (row.order_status === 'Ironing') dashboard.ironing_orders = row.total;
      if (row.order_status === 'Ready') dashboard.ready_orders = row.total;
    });

    return res.status(200).json({
      success: true,
      dashboard
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch staff dashboard',
      error: error.message
    });
  }
};

const getStaffOrders = async (req, res) => {
  try {
    const [orders] = await db.execute(
      `SELECT
        o.order_id,
        p.full_name AS customer_name,
        p.phone,
        o.pickup_address,
        o.total_amount,
        COALESCE(payments.paid_total, 0) AS paid_total,
        GREATEST(o.total_amount - COALESCE(payments.paid_total, 0), 0) AS balance,
        o.order_status,
        o.payment_status,
        o.pickup_date,
        o.created_at
      FROM orders o
      INNER JOIN customers c ON c.customer_id = o.customer_id
      INNER JOIN users u ON u.user_id = c.user_id
      INNER JOIN people p ON p.person_id = u.person_id
      LEFT JOIN (
        SELECT order_id, SUM(amount_paid) AS paid_total
        FROM payments
        GROUP BY order_id
      ) payments ON payments.order_id = o.order_id
      ORDER BY o.created_at DESC`
    );

    return res.status(200).json({
      success: true,
      orders
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch staff orders',
      error: error.message
    });
  }
};

const getCustomerBalances = async (req, res) => {
  try {
    const [customers] = await db.execute(
      `SELECT
        c.customer_id,
        p.full_name AS customer_name,
        p.phone,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_amount,
        COALESCE(SUM(payments.paid_total), 0) AS paid_total,
        GREATEST(
          COALESCE(SUM(o.total_amount), 0) - COALESCE(SUM(payments.paid_total), 0),
          0
        ) AS balance
      FROM customers c
      INNER JOIN users u ON u.user_id = c.user_id
      INNER JOIN people p ON p.person_id = u.person_id
      LEFT JOIN orders o ON o.customer_id = c.customer_id
      LEFT JOIN (
        SELECT order_id, SUM(amount_paid) AS paid_total
        FROM payments
        GROUP BY order_id
      ) payments ON payments.order_id = o.order_id
      GROUP BY c.customer_id, p.full_name, p.phone
      ORDER BY balance DESC, p.full_name ASC`
    );

    return res.status(200).json({
      success: true,
      customers
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch customer balances',
      error: error.message
    });
  }
};

const getStaffList = async (req, res) => {
  try {
    const [staff] = await db.execute(
      `SELECT
        s.staff_id,
        s.person_id,
        s.user_id,
        p.full_name,
        p.sex,
        p.phone,
        p.email,
        u.role,
        s.position,
        s.salary,
        s.hire_date,
        s.status
      FROM staff s
      INNER JOIN people p ON p.person_id = s.person_id
      LEFT JOIN users u ON u.user_id = s.user_id
      ORDER BY s.staff_id DESC`
    );

    return res.status(200).json({
      success: true,
      staff
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch staff list',
      error: error.message
    });
  }
};

const updateStaffStatus = async (req, res) => {
  try {
    const { staff_id, status } = req.body;

    if (!staff_id || !['Active', 'Inactive'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'staff_id and valid status are required'
      });
    }

    await db.execute('UPDATE staff SET status = ? WHERE staff_id = ?', [status, staff_id]);
    await db.execute(
      `UPDATE users u
      INNER JOIN staff s ON s.user_id = u.user_id
      SET u.status = ?
      WHERE s.staff_id = ?`,
      [status, staff_id]
    );

    return res.status(200).json({
      success: true,
      message: 'Staff status updated'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update staff status',
      error: error.message
    });
  }
};

module.exports = {
  registerStaff,
  getStaffDashboard,
  getStaffOrders,
  getCustomerBalances,
  getStaffList,
  updateStaffStatus
};
