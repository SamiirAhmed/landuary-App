const express = require('express');
const {
  getCities,
  getDistrictsByCity,
  getServices,
  getClothTypes
} = require('../controllers/lookupController');

const router = express.Router();

router.get('/cities', getCities);
router.get('/districts/:city_id', getDistrictsByCity);
router.get('/services', getServices);
router.get('/cloth-types', getClothTypes);

module.exports = router;
