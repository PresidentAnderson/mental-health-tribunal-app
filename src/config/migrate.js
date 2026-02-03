require('dotenv').config();
const { pool } = require('./db');

const migration = `
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('police_officer', 'mental_health_professional', 'physician', 'tribunal_member', 'requesting_party', 'respondent', 'admin')),
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
