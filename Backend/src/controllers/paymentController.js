const db = require('../config/db');

const makePayment = async (req, res) => {
  try {
    const { order_id, amount_paid, payment_method, payment_note } = req.body;
    const validMethods = ['Cash', 'EVC Plus', 'Zaad', 'Card', 'Bank'];

    if (!order_id || !amount_paid || !payment_method) {
      return res.status(400).json({
        success: false,
        message: 'order_id, amount_paid, and payment_method are required'
      });
    }

    const amount = Number(amount_paid);

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'amount_paid must be a valid amount greater than 0'
      });
    }

    if (!validMethods.includes(payment_method)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment method'
      });
    }

    const [orderRows] = await db.execute(
      'SELECT total_amount FROM orders WHERE order_id = ? LIMIT 1',
      [order_id]
    );

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const [paidRows] = await db.execute(
      'SELECT COALESCE(SUM(amount_paid), 0) AS paid_total FROM payments WHERE order_id = ?',
      [order_id]
    );

    const totalAmount = Number(orderRows[0].total_amount);
    const paidBeforePayment = Number(paidRows[0].paid_total);
    const remainingBalance = totalAmount - paidBeforePayment;

    if (amount > remainingBalance) {
      return res.status(400).json({
        success: false,
        message: `Payment exceeds remaining balance of ${remainingBalance.toFixed(2)}`
      });
    }

    await db.execute(
      `INSERT INTO payments (order_id, amount_paid, payment_method, payment_note)
      VALUES (?, ?, ?, ?)`,
      [order_id, amount_paid, payment_method, payment_note || null]
    );

    const paidTotal = paidBeforePayment + amount;
    const paymentStatus = paidTotal >= totalAmount ? 'Paid' : paidTotal > 0 ? 'Partial' : 'Unpaid';

    await db.execute(
      'UPDATE orders SET payment_status = ? WHERE order_id = ?',
      [paymentStatus, order_id]
    );

    return res.status(201).json({
      success: true,
      message: 'Payment saved successfully',
      payment_status: paymentStatus
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Payment failed',
      error: error.message
    });
  }
};

const getPaymentsByOrder = async (req, res) => {
  try {
    const { order_id } = req.params;

    const [payments] = await db.execute(
      `SELECT payment_id, order_id, amount_paid, payment_method, payment_date, payment_note
      FROM payments
      WHERE order_id = ?
      ORDER BY payment_date DESC`,
      [order_id]
    );

    return res.status(200).json({
      success: true,
      payments
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch payment history',
      error: error.message
    });
  }
};

module.exports = {
  makePayment,
  getPaymentsByOrder
};
