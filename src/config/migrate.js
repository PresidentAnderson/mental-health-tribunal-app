require('dotenv').config();
const { pool } = require('./db');

const migration = `
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('police_officer', 'mental_health_professional', 'physician', 'tribunal_member', 'requesting_party', 'respondent', 'prosecutor', 'admin')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY,
    patient_name VARCHAR(255) NOT NULL,
    incident_summary TEXT NOT NULL,
    urgency VARCHAR(20) NOT NULL CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
    referred_by UUID REFERENCES users(id),
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_assessment', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE TABLE IF NOT EXISTS assessments (
    id UUID PRIMARY KEY,
    referral_id UUID REFERENCES referrals(id),
    assessed_by UUID REFERENCES users(id),
    findings TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'moderate', 'high', 'very_high')),
    created_at TIMESTAMP DEFAULT NOW()
  );

  CREATE TABLE IF NOT EXISTS hearings (
    id UUID PRIMARY KEY,
    referral_id UUID REFERENCES referrals(id),
    scheduled_date TIMESTAMP NOT NULL,
    location VARCHAR(255),
    panel_members JSONB,
    status VARCHAR(30) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'decided', 'adjourned', 'cancelled')),
    decision VARCHAR(50),
    decision_notes TEXT,
    decided_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
  CREATE INDEX IF NOT EXISTS idx_hearings_date ON hearings(scheduled_date);
  CREATE INDEX IF NOT EXISTS idx_assessments_referral ON assessments(referral_id);

  CREATE TABLE IF NOT EXISTS pajsm_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID REFERENCES referrals(id),
    accused_name VARCHAR(255) NOT NULL,
    district VARCHAR(255),
    vulnerabilities TEXT[] NOT NULL,
    diagnosed BOOLEAN DEFAULT false,
    offence_description TEXT,
    offence_category VARCHAR(100),
    prosecution_mode VARCHAR(20) CHECK (prosecution_mode IN ('summary', 'indictment')),
    accepts_responsibility BOOLEAN DEFAULT false,
    is_voluntary BOOLEAN DEFAULT false,
    waives_delay BOOLEAN DEFAULT false,
    criminally_fit BOOLEAN DEFAULT true,
    victim_consent BOOLEAN,
    victim_consent_mode VARCHAR(10) CHECK (victim_consent_mode IN ('written', 'verbal')),
    stage VARCHAR(50) NOT NULL DEFAULT 'referral',
    enrolled_at TIMESTAMP,
    completed_at TIMESTAMP,
    outcome VARCHAR(50) CHECK (outcome IN ('completed', 'withdrawn', 'returned_to_court')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE TABLE IF NOT EXISTS pajsm_intervention_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_id UUID NOT NULL REFERENCES pajsm_participants(id),
    plan_details TEXT,
    objectives JSONB,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE TABLE IF NOT EXISTS pajsm_follow_ups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_id UUID NOT NULL REFERENCES pajsm_participants(id),
    follow_up_date TIMESTAMP NOT NULL,
    notes TEXT,
    recorded_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
  );

  CREATE INDEX IF NOT EXISTS idx_pajsm_participants_referral ON pajsm_participants(referral_id);
  CREATE INDEX IF NOT EXISTS idx_pajsm_participants_stage ON pajsm_participants(stage);
  CREATE INDEX IF NOT EXISTS idx_pajsm_intervention_plans_participant ON pajsm_intervention_plans(participant_id);
  CREATE INDEX IF NOT EXISTS idx_pajsm_follow_ups_participant ON pajsm_follow_ups(participant_id);
`;

async function run() {
  try {
    await pool.query(migration);
    console.log('Migration completed successfully');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

run();
