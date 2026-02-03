const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function create(data, user) {
  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO referrals (id, patient_name, incident_summary, urgency, referred_by, status)
     VALUES ($1, $2, $3, $4, $5, 'pending')
     RETURNING *`,
    [id, data.patientName, data.incidentSummary, data.urgency, user.id]
  );
  return rows[0];
}

async function list(user) {
  const { rows } = await pool.query('SELECT * FROM referrals ORDER BY created_at DESC');
  return rows;
}

async function getById(id, user) {
  const { rows } = await pool.query('SELECT * FROM referrals WHERE id = $1', [id]);
  if (!rows[0]) {
    const err = new Error('Referral not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

async function updateStatus(id, status, user) {
  const { rows } = await pool.query(
    'UPDATE referrals SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
    [status, id]
  );
  if (!rows[0]) {
    const err = new Error('Referral not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

module.exports = { create, list, getById, updateStatus };
