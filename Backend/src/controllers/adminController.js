const db = require('../config/db');

const getAdminDashboard = async (req, res) => {
  try {
    const [[ordersRow]] = await db.execute('SELECT COUNT(*) AS total_orders FROM orders');
    const [[customersRow]] = await db.execute('SELECT COUNT(*) AS total_customers FROM customers');
    const [[staffRow]] = await db.execute(
      'SELECT COUNT(*) AS total_staff FROM staff'
    );
    const [[servicesRow]] = await db.execute(
      'SELECT COUNT(*) AS total_services FROM services'
    );
    const [[paymentsRow]] = await db.execute(
      'SELECT COALESCE(SUM(amount_paid), 0) AS total_payments FROM payments'
    );
    const [[expensesRow]] = await db.execute(
      'SELECT COALESCE(SUM(amount), 0) AS total_expenses FROM expenses'
    );
    const [[pendingRow]] = await db.execute(
      "SELECT COUNT(*) AS pending_orders FROM orders WHERE order_status = 'Pending'"
    );
    const [[inProgressRow]] = await db.execute(
      "SELECT COUNT(*) AS in_progress_orders FROM orders WHERE order_status IN ('Accepted', 'Washing', 'Ironing')"
    );
    const [[outForDeliveryRow]] = await db.execute(
      "SELECT COUNT(*) AS out_for_delivery_orders FROM orders WHERE order_status = 'Ready'"
    );
    const [[paidRow]] = await db.execute(
      "SELECT COUNT(*) AS paid_orders FROM orders WHERE payment_status = 'Paid'"
    );
    const [[unpaidRow]] = await db.execute(
      "SELECT COUNT(*) AS unpaid_orders FROM orders WHERE payment_status = 'Unpaid'"
    );
    const totalPayments = Number(paymentsRow.total_payments);
    const totalExpenses = Number(expensesRow.total_expenses);

    return res.status(200).json({
      success: true,
      dashboard: {
        total_orders: ordersRow.total_orders,
        total_customers: customersRow.total_customers,
        total_staff: staffRow.total_staff,
        total_services: servicesRow.total_services,
        total_payments: paymentsRow.total_payments,
        total_expenses: expensesRow.total_expenses,
        net_income: totalPayments - totalExpenses,
        pending_orders: pendingRow.pending_orders,
        paid_orders: paidRow.paid_orders,
        unpaid_orders: unpaidRow.unpaid_orders,
        new_orders: pendingRow.pending_orders,
        in_progress_orders: inProgressRow.in_progress_orders,
        out_for_delivery_orders: outForDeliveryRow.out_for_delivery_orders
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch admin dashboard',
      error: error.message
    });
  }
};

const addService = async (req, res) => {
  try {
    const { service_name, price_type, price, description } = req.body;

    if (!service_name || !price_type || price === undefined) {
      return res.status(400).json({
        success: false,
        message: 'service_name, price_type, and price are required'
      });
    }

    await db.execute(
      `INSERT INTO services (service_name, price_type, price, description, status)
      VALUES (?, ?, ?, ?, 'Active')`,
      [service_name, price_type, price, description || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Service added'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to add service',
      error: error.message
    });
  }
};

const getServices = async (req, res) => {
  try {
    const [services] = await db.execute(
      `SELECT service_id, service_name, price_type, price, description, status
      FROM services
      ORDER BY service_name`
    );

    return res.status(200).json({
      success: true,
      services
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch services',
      error: error.message
    });
  }
};

const updateService = async (req, res) => {
  try {
    const { service_id, service_name, price_type, price, description, status } = req.body;

    if (!service_id) {
      return res.status(400).json({
        success: false,
        message: 'service_id is required'
      });
    }

    await db.execute(
      `UPDATE services
      SET service_name = COALESCE(?, service_name),
          price_type = COALESCE(?, price_type),
          price = COALESCE(?, price),
          description = COALESCE(?, description),
          status = COALESCE(?, status)
      WHERE service_id = ?`,
      [service_name || null, price_type || null, price ?? null, description || null, status || null, service_id]
    );

    return res.status(200).json({
      success: true,
      message: 'Service updated'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update service',
      error: error.message
    });
  }
};

const deleteService = async (req, res) => {
  try {
    const { service_id } = req.body;
    if (!service_id) {
      return res.status(400).json({ success: false, message: 'service_id is required' });
    }
    await db.execute('DELETE FROM services WHERE service_id = ?', [service_id]);
    return res.status(200).json({ success: true, message: 'Service deleted' });
  } catch (error) {
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ success: false, message: 'Cannot delete service because it is used in orders. Try changing its status to Inactive instead.' });
    }
    return res.status(500).json({
      success: false,
      message: 'Failed to delete service',
      error: error.message
    });
  }
};

const getReports = async (req, res) => {
  try {
    const [[dailyIncome]] = await db.execute(
      'SELECT COALESCE(SUM(amount_paid), 0) AS value FROM payments WHERE DATE(payment_date) = CURDATE()'
    );
    const [[monthlyIncome]] = await db.execute(
      'SELECT COALESCE(SUM(amount_paid), 0) AS value FROM payments WHERE YEAR(payment_date) = YEAR(CURDATE()) AND MONTH(payment_date) = MONTH(CURDATE())'
    );
    const [[totalOrders]] = await db.execute('SELECT COUNT(*) AS value FROM orders');
    const [[unpaidOrders]] = await db.execute("SELECT COUNT(*) AS value FROM orders WHERE payment_status = 'Unpaid'");
    const [[completedOrders]] = await db.execute("SELECT COUNT(*) AS value FROM orders WHERE order_status = 'Delivered'");
    const [[expenses]] = await db.execute('SELECT COALESCE(SUM(amount), 0) AS value FROM expenses');

    const income = Number(monthlyIncome.value);
    const expenseTotal = Number(expenses.value);

    return res.status(200).json({
      success: true,
      reports: {
        daily_income: dailyIncome.value,
        monthly_income: monthlyIncome.value,
        total_orders: totalOrders.value,
        unpaid_orders: unpaidOrders.value,
        completed_orders: completedOrders.value,
        expenses: expenses.value,
        profit: income - expenseTotal
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch reports',
      error: error.message
    });
  }
};

const addExpense = async (req, res) => {
  try {
    const { expense_title, amount, expense_date, description } = req.body;
    const parsedAmount = Number(amount);

    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can manage expenses'
      });
    }

    if (!expense_title || amount === undefined || !expense_date) {
      return res.status(400).json({
        success: false,
        message: 'expense_title, amount, and expense_date are required'
      });
    }

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'amount must be greater than 0'
      });
    }

    await db.execute(
      `INSERT INTO expenses (expense_title, amount, expense_date, description, created_by)
      VALUES (?, ?, ?, ?, ?)`,
      [
        expense_title,
        parsedAmount,
        expense_date,
        description || null,
        req.user?.user_id || null
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Expense added'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to add expense',
      error: error.message
    });
  }
};

const getExpenses = async (req, res) => {
  try {
    if (req.user?.role !== 'Admin') {
      return res.status(403).json({
        success: false,
        message: 'Only admins can view expenses'
      });
    }

    const [expenses] = await db.execute(
      `SELECT
        e.expense_id,
        e.expense_title,
        e.amount,
        e.expense_date,
        e.description,
        e.created_at,
        p.full_name AS created_by_name
      FROM expenses e
      LEFT JOIN users u ON u.user_id = e.created_by
      LEFT JOIN people p ON p.person_id = u.person_id
      ORDER BY e.expense_date DESC, e.expense_id DESC`
    );

    return res.status(200).json({
      success: true,
      expenses
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch expenses',
      error: error.message
    });
  }
};

module.exports = {
  getAdminDashboard,
  getServices,
  addService,
  updateService,
  deleteService,
  getReports,
  addExpense,
  getExpenses
};
