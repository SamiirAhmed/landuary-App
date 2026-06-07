const db = require('../config/db');

const getPickupOrders = async (req, res) => {
  try {
    const [orders] = await db.execute(
      `SELECT
        o.order_id,
        p.full_name AS customer_name,
        p.phone,
        o.pickup_address,
        o.pickup_date,
        o.total_amount,
        o.order_status,
        COALESCE(pd.pickup_status, 'Pending') AS pickup_status,
        COALESCE(pd.delivery_status, 'Pending') AS delivery_status
      FROM orders o
      INNER JOIN customers c ON c.customer_id = o.customer_id
      INNER JOIN users u ON u.user_id = c.user_id
      INNER JOIN people p ON p.person_id = u.person_id
      LEFT JOIN pickup_delivery pd ON pd.order_id = o.order_id
      WHERE o.order_status IN ('Pending', 'Accepted', 'Picked Up', 'Ready')
      ORDER BY o.pickup_date ASC, o.created_at DESC`
    );

    return res.status(200).json({
      success: true,
      orders
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch delivery orders',
      error: error.message
    });
  }
};

const markPickedUp = async (req, res) => {
  try {
    const { order_id, delivery_user_id, notes } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: 'order_id is required'
      });
    }

    await db.execute(
      `INSERT INTO pickup_delivery (order_id, delivery_user_id, pickup_status, pickup_date, notes)
      VALUES (?, ?, 'Picked Up', NOW(), ?)
      ON DUPLICATE KEY UPDATE
        delivery_user_id = VALUES(delivery_user_id),
        pickup_status = 'Picked Up',
        pickup_date = NOW(),
        notes = VALUES(notes)`,
      [order_id, delivery_user_id || null, notes || null]
    );

    await db.execute("UPDATE orders SET order_status = 'Picked Up' WHERE order_id = ?", [order_id]);

    return res.status(200).json({
      success: true,
      message: 'Order marked as picked up'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to mark picked up',
      error: error.message
    });
  }
};

const markDelivered = async (req, res) => {
  try {
    const { order_id, delivery_user_id, notes } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: 'order_id is required'
      });
    }

    await db.execute(
      `INSERT INTO pickup_delivery (order_id, delivery_user_id, delivery_status, delivery_date, notes)
      VALUES (?, ?, 'Delivered', NOW(), ?)
      ON DUPLICATE KEY UPDATE
        delivery_user_id = VALUES(delivery_user_id),
        delivery_status = 'Delivered',
        delivery_date = NOW(),
        notes = VALUES(notes)`,
      [order_id, delivery_user_id || null, notes || null]
    );

    await db.execute("UPDATE orders SET order_status = 'Delivered' WHERE order_id = ?", [order_id]);

    return res.status(200).json({
      success: true,
      message: 'Order marked as delivered'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to mark delivered',
      error: error.message
    });
  }
};

module.exports = {
  getPickupOrders,
  markPickedUp,
  markDelivered
};
