const db = require('../config/db');

const getCities = async (req, res) => {
  try {
    const [cities] = await db.execute(
      `SELECT city_id, city_name, status
      FROM cities
      WHERE status = 'Active'
      ORDER BY city_name`
    );

    return res.status(200).json({
      success: true,
      cities
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch cities',
      error: error.message
    });
  }
};

const getDistrictsByCity = async (req, res) => {
  try {
    const { city_id } = req.params;

    const [districts] = await db.execute(
      `SELECT district_id, city_id, district_name, status
      FROM districts
      WHERE city_id = ? AND status = 'Active'
      ORDER BY district_name`,
      [city_id]
    );

    return res.status(200).json({
      success: true,
      districts
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch districts',
      error: error.message
    });
  }
};

const getServices = async (req, res) => {
  try {
    const [services] = await db.execute(
      `SELECT service_id, service_name, price_type, price, description, status
      FROM services
      WHERE status = 'Active'
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

const getClothTypes = async (req, res) => {
  try {
    const [clothTypes] = await db.execute(
      `SELECT cloth_type_id, cloth_name, status
      FROM cloth_types
      WHERE status = 'Active'
      ORDER BY cloth_name`
    );

    return res.status(200).json({
      success: true,
      clothTypes
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch cloth types',
      error: error.message
    });
  }
};

module.exports = {
  getCities,
  getDistrictsByCity,
  getServices,
  getClothTypes
};
