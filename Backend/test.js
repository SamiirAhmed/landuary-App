const db = require('./src/config/db.js');
const getAdminDashboard = async () => {
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
    const [[paidRow]] = await db.execute(
      "SELECT COUNT(*) AS paid_orders FROM orders WHERE payment_status = 'Paid'"
    );
    const [[unpaidRow]] = await db.execute(
      "SELECT COUNT(*) AS unpaid_orders FROM orders WHERE payment_status = 'Unpaid'"
    );
    const totalPayments = Number(paymentsRow.total_payments);
    const totalExpenses = Number(expensesRow.total_expenses);

    console.log({
        total_orders: ordersRow.total_orders,
        total_customers: customersRow.total_customers,
        total_staff: staffRow.total_staff,
        total_services: servicesRow.total_services,
        total_payments: paymentsRow.total_payments,
        total_expenses: expensesRow.total_expenses,
        net_income: totalPayments - totalExpenses,
        pending_orders: pendingRow.pending_orders,
        paid_orders: paidRow.paid_orders,
        unpaid_orders: unpaidRow.unpaid_orders
      });
      process.exit(0);
  } catch (error) {
    console.error(error);
      process.exit(1);
  }
};
getAdminDashboard();
