const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function create(data, user) {
  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO assessments (id, referral_id, assessed_by, findings, recommendation, risk_level)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [id, data.referralId, user.id, data.findings, data.recommendation, data.riskLevel]
  );
  return rows[0];
}

async function list(user) {
  const { rows } = await pool.query('SELECT * FROM assessments ORDER BY created_at DESC');
  return rows;
}

async function getById(id, user) {
  const { rows } = await pool.query('SELECT * FROM assessments WHERE id = $1', [id]);
  if (!rows[0]) {
    const err = new Error('Assessment not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

module.exports = { create, list, getById };
