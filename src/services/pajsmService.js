const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { PROGRAM_STAGES, PROGRAM_STAGE_KEYS } = require('../config/pajsm');
const { checkEligibility } = require('./eligibilityService');

async function enroll(data, user) {
  const result = checkEligibility(data);
  if (!result.eligible) {
    const err = new Error('Participant is not eligible for PAJ-SM+');
    err.statusCode = 400;
    err.reasons = result.reasons;
    throw err;
  }

  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO pajsm_participants
      (id, referral_id, accused_name, district, vulnerabilities, diagnosed,
       offence_description, offence_category, prosecution_mode,
       accepts_responsibility, is_voluntary, waives_delay, criminally_fit,
       victim_consent, victim_consent_mode, stage)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
     RETURNING *`,
    [
      id,
      data.referral_id || null,
      data.accused_name,
      data.district || null,
      data.vulnerabilities,
      data.diagnosed || false,
      data.offence_description || null,
      data.offence_category || null,
      data.prosecution_mode || null,
      data.accepts_responsibility,
      data.is_voluntary,
      data.waives_delay,
      data.criminally_fit,
      data.victim_consent || null,
      data.victim_consent_mode || null,
      PROGRAM_STAGE_KEYS.REFERRAL,
    ]
  );
  return rows[0];
}

async function getById(id, user) {
  const { rows } = await pool.query(
    'SELECT * FROM pajsm_participants WHERE id = $1',
    [id]
  );
  if (!rows[0]) {
    const err = new Error('PAJ-SM+ participant not found');
    err.statusCode = 404;
    throw err;
  }
  return rows[0];
}

async function list(user) {
  const { rows } = await pool.query(
    'SELECT * FROM pajsm_participants ORDER BY created_at DESC'
  );
  return rows;
}

async function advanceStage(id, user) {
  const participant = await getById(id, user);
  const currentIndex = PROGRAM_STAGES.indexOf(participant.stage);

  if (currentIndex === -1 || currentIndex >= PROGRAM_STAGES.length - 1) {
    const err = new Error('Cannot advance beyond the final stage');
    err.statusCode = 400;
    throw err;
  }

  const nextStage = PROGRAM_STAGES[currentIndex + 1];
  const updates = ['stage = $1', 'updated_at = NOW()'];
  const params = [nextStage];
  let paramIndex = 2;

  // Set enrolled_at when moving past referral into prosecutor evaluation
  if (
    nextStage === PROGRAM_STAGE_KEYS.PROSECUTOR_EVALUATION &&
    !participant.enrolled_at
  ) {
    updates.push(`enrolled_at = $${paramIndex++}`);
    params.push(new Date().toISOString());
  }

  // Set completed_at when reaching program outcome
  if (nextStage === PROGRAM_STAGE_KEYS.PROGRAM_OUTCOME) {
    updates.push(`completed_at = $${paramIndex++}`);
    params.push(new Date().toISOString());
    updates.push(`outcome = $${paramIndex++}`);
    params.push('completed');
  }

  params.push(id);
  const { rows } = await pool.query(
    `UPDATE pajsm_participants SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
    params
  );
  return rows[0];
}

async function withdraw(id, reason, user) {
  const participant = await getById(id, user);
  if (participant.outcome) {
    const err = new Error('Participant already has a final outcome');
    err.statusCode = 400;
    throw err;
  }

  const { rows } = await pool.query(
    `UPDATE pajsm_participants
     SET outcome = 'withdrawn', completed_at = NOW(), updated_at = NOW()
     WHERE id = $1 RETURNING *`,
    [id]
  );
  return rows[0];
}

async function revokeVictimConsent(id, user) {
  const participant = await getById(id, user);
  if (participant.outcome) {
    const err = new Error('Participant already has a final outcome');
    err.statusCode = 400;
    throw err;
  }

  const { rows } = await pool.query(
    `UPDATE pajsm_participants
     SET victim_consent = false, outcome = 'returned_to_court',
         completed_at = NOW(), updated_at = NOW()
     WHERE id = $1 RETURNING *`,
    [id]
  );
  return rows[0];
}

async function createInterventionPlan(participantId, data, user) {
  const participant = await getById(participantId, user);
  if (participant.stage !== PROGRAM_STAGE_KEYS.INTERVENTION_PLAN) {
    const err = new Error(
      'Intervention plans can only be created during the intervention_plan stage'
    );
    err.statusCode = 400;
    throw err;
  }

  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO pajsm_intervention_plans
      (id, participant_id, plan_details, objectives, created_by)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [id, participantId, data.plan_details || null, data.objectives || null, user.id]
  );
  return rows[0];
}

async function addFollowUp(participantId, data, user) {
  const participant = await getById(participantId, user);
  if (participant.stage !== PROGRAM_STAGE_KEYS.HEARING_FOLLOWUPS) {
    const err = new Error(
      'Follow-ups can only be added during the hearing_followups stage'
    );
    err.statusCode = 400;
    throw err;
  }

  const id = uuidv4();
  const { rows } = await pool.query(
    `INSERT INTO pajsm_follow_ups
      (id, participant_id, follow_up_date, notes, recorded_by)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [id, participantId, data.follow_up_date, data.notes || null, user.id]
  );
  return rows[0];
}

module.exports = {
  enroll,
  getById,
  list,
  advanceStage,
  withdraw,
  revokeVictimConsent,
  createInterventionPlan,
  addFollowUp,
};
