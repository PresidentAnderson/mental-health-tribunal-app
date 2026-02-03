const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function schedule(data, user) {
  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO hearings (id, referral_id, scheduled_date, location, panel_members, status)
     VALUES ($1, $2, $3, $4, $5, 'scheduled')
     RETURNING *`,
    [id, data.referralId, data.scheduledDate, data.location, JSON.stringify(data.panelMembers)]
  );
  return rows[0];
}

async function list(user) {
  const { rows } = await pool.query('SELECT * FROM hearings ORDER BY scheduled_date DESC');
  return rows;
}

async function getById(id, user) {
  const { rows } = await pool.query('SELECT * FROM hearings WHERE id = $1', [id]);
  if (!rows[0]) {
    const err = new Error('Hearing not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

async function recordDecision(id, data, user) {
  const { rows } = await pool.query(
    `UPDATE hearings SET decision = $1, decision_notes = $2, decided_by = $3,
     status = 'decided', updated_at = NOW() WHERE id = $4 RETURNING *`,
    [data.decision, data.notes, user.id, id]
  );
  if (!rows[0]) {
    const err = new Error('Hearing not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

module.exports = { schedule, list, getById, recordDecision };
