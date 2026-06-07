const db = require('../config/db');

const getOrderByIdQuery = `SELECT
  o.order_id,
  o.customer_id,
  p.full_name AS customer_name,
  p.phone AS customer_phone,
  o.pickup_address,
  o.pickup_date,
  o.total_amount,
  COALESCE(payments.paid_total, 0) AS paid_total,
  GREATEST(o.total_amount - COALESCE(payments.paid_total, 0), 0) AS balance,
  o.order_status,
  o.payment_status,
  o.special_notes,
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
WHERE o.order_id = ?`;

const getOrderItemsQuery = `SELECT
  oi.order_item_id,
  oi.service_id,
  s.service_name,
  oi.cloth_type_id,
  ct.cloth_name,
  oi.quantity,
  oi.weight,
  oi.unit_price,
  oi.subtotal,
  oi.notes
FROM order_items oi
INNER JOIN services s ON s.service_id = oi.service_id
INNER JOIN cloth_types ct ON ct.cloth_type_id = oi.cloth_type_id
WHERE oi.order_id = ?
ORDER BY oi.order_item_id`;

const formatOrder = (orderRows, itemRows) => {
  if (orderRows.length === 0) {
    return null;
  }

  return {
    ...orderRows[0],
    items: itemRows
  };
};

const validateOrderItems = (items) => {
  if (!Array.isArray(items) || items.length === 0) {
    return 'items must be a non-empty JSON array';
  }

  for (const item of items) {
    if (!item.service_id || !item.cloth_type_id) {
      return 'Each item must include service_id and cloth_type_id';
    }

    if (
      (item.quantity === undefined || item.quantity === null) &&
      (item.weight === undefined || item.weight === null)
    ) {
      return 'Each item must include quantity or weight';
    }
  }

  return null;
};

const createOrder = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const {
      customer_id,
      pickup_address,
      pickup_date,
      special_notes,
      items
    } = req.body;

    if (!customer_id || !pickup_address || !pickup_date || items === undefined) {
      return res.status(400).json({
        success: false,
        message: 'customer_id, pickup_address, pickup_date, and items are required'
      });
    }

    const itemValidationError = validateOrderItems(items);

    if (itemValidationError) {
      return res.status(400).json({
        success: false,
        message: itemValidationError
      });
    }

    await connection.query('SET @created_order_id = NULL');
    await connection.query(
      'CALL sp_create_order_with_items(?, ?, ?, ?, ?, @created_order_id)',
      [
        customer_id,
        pickup_address,
        pickup_date,
        special_notes || null,
        JSON.stringify(items)
      ]
    );

    const [orderIdRows] = await connection.query('SELECT @created_order_id AS order_id');
    const orderId = orderIdRows[0].order_id;

    const [orderRows] = await connection.execute(getOrderByIdQuery, [orderId]);
    const [itemRows] = await connection.execute(getOrderItemsQuery, [orderId]);

    return res.status(201).json({
      success: true,
      message: 'Order created successfully',
      order: formatOrder(orderRows, itemRows)
    });
  } catch (error) {
    const statusCode = error.sqlState === '45000' ? 400 : 500;

    return res.status(statusCode).json({
      success: false,
      message: error.sqlMessage || 'Order creation failed',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

const getOrdersByCustomer = async (req, res) => {
  try {
    const { customer_id } = req.params;

    if (!customer_id) {
      return res.status(400).json({
        success: false,
        message: 'customer_id is required'
      });
    }

    const [orders] = await db.execute(
      `SELECT
        o.order_id,
        o.customer_id,
        o.pickup_address,
        o.pickup_date,
        o.total_amount,
        COALESCE(payments.paid_total, 0) AS paid_total,
        GREATEST(o.total_amount - COALESCE(payments.paid_total, 0), 0) AS balance,
        o.order_status,
        o.payment_status,
        o.special_notes,
        o.created_at
      FROM orders o
      LEFT JOIN (
        SELECT order_id, SUM(amount_paid) AS paid_total
        FROM payments
        GROUP BY order_id
      ) payments ON payments.order_id = o.order_id
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC`,
      [customer_id]
    );

    return res.status(200).json({
      success: true,
      message: 'Customer orders fetched successfully',
      count: orders.length,
      orders
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch customer orders',
      error: error.message
    });
  }
};

const getOrderById = async (req, res) => {
  try {
    const { order_id } = req.params;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: 'order_id is required'
      });
    }

    const [orderRows] = await db.execute(getOrderByIdQuery, [order_id]);

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const [itemRows] = await db.execute(getOrderItemsQuery, [order_id]);

    return res.status(200).json({
      success: true,
      message: 'Order fetched successfully',
      order: formatOrder(orderRows, itemRows)
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch order',
      error: error.message
    });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    const { order_id, new_status, changed_by, remarks } = req.body;
    const validStatuses = [
      'Pending',
      'Accepted',
      'Picked Up',
      'Washing',
      'Ironing',
      'Ready',
      'Delivered',
      'Cancelled'
    ];

    if (!order_id || !new_status) {
      return res.status(400).json({
        success: false,
        message: 'order_id and new_status are required'
      });
    }

    if (!validStatuses.includes(new_status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order status'
      });
    }

    const [existingRows] = await db.execute(
      'SELECT order_status FROM orders WHERE order_id = ? LIMIT 1',
      [order_id]
    );

    if (existingRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    const oldStatus = existingRows[0].order_status;

    await db.execute(
      'UPDATE orders SET order_status = ? WHERE order_id = ?',
      [new_status, order_id]
    );

    await db.execute(
      `INSERT INTO order_tracking (order_id, old_status, new_status, changed_by, remarks)
      VALUES (?, ?, ?, ?, ?)`,
      [order_id, oldStatus, new_status, changed_by || null, remarks || null]
    );

    return res.status(200).json({
      success: true,
      message: 'Order status updated successfully'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update order status',
      error: error.message
    });
  }
};

module.exports = {
  createOrder,
  getOrdersByCustomer,
  getOrderById,
  updateOrderStatus
};
