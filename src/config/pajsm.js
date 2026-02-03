const VULNERABILITIES = {
  MENTAL_HEALTH_DISORDER: 'mental_health_disorder',
  INTELLECTUAL_DISABILITY: 'intellectual_disability',
  ASD: 'asd',
  SUBSTANCE_USE_DISORDER: 'substance_use_disorder',
  TRAUMATIC_BRAIN_INJURY: 'traumatic_brain_injury',
};

const VULNERABILITY_LABELS = {
  [VULNERABILITIES.MENTAL_HEALTH_DISORDER]: 'Mental health disorder (DSM-5)',
  [VULNERABILITIES.INTELLECTUAL_DISABILITY]: 'Intellectual disability (DI)',
  [VULNERABILITIES.ASD]: 'Autism spectrum disorder (TSA)',
  [VULNERABILITIES.SUBSTANCE_USE_DISORDER]: 'Substance use disorder',
  [VULNERABILITIES.TRAUMATIC_BRAIN_INJURY]: 'Traumatic brain injury (TCC)',
};

const EXCLUSIONS = [
  'death_resulting_offences',
  'attempted_or_conspired_death_offences',
  'superior_court_jurisdiction',
  'sexual_offences_against_minors',
  'domestic_violence',
  'sexual_violence',
  'elder_abuse',
  'transport_offences_causing_injury',
  'terrorism',
  'criminal_organization',
  'firearms_weapons_by_indictment',
];

const ABSOLUTE_EXCLUSIONS = [
  'death_resulting_offences',
  'attempted_or_conspired_death_offences',
  'superior_court_jurisdiction',
  'sexual_offences_against_minors',
  'transport_offences_causing_injury',
  'terrorism',
  'criminal_organization',
  'firearms_weapons_by_indictment',
];

const SUMMARY_ELIGIBLE_EXCEPTIONS = [
  'domestic_violence',
  'sexual_violence',
  'elder_abuse',
];

const ELIGIBILITY_CRITERIA = [
  'admissible_offence',
  'accepts_responsibility',
  'voluntary_participation',
  'capacity_to_learn',
  'waives_delay_rights',
  'criminally_fit_and_responsible',
];

const PROGRAM_STAGE_KEYS = {
  REFERRAL: 'referral',
  PROSECUTOR_EVALUATION: 'prosecutor_evaluation',
  CLINICAL_ELIGIBILITY: 'clinical_eligibility',
  INTERVENTION_PLAN: 'intervention_plan',
  HEARING_FOLLOWUPS: 'hearing_followups',
  PROGRAM_OUTCOME: 'program_outcome',
};

const PROGRAM_STAGES = [
  PROGRAM_STAGE_KEYS.REFERRAL,
  PROGRAM_STAGE_KEYS.PROSECUTOR_EVALUATION,
  PROGRAM_STAGE_KEYS.CLINICAL_ELIGIBILITY,
  PROGRAM_STAGE_KEYS.INTERVENTION_PLAN,
  PROGRAM_STAGE_KEYS.HEARING_FOLLOWUPS,
  PROGRAM_STAGE_KEYS.PROGRAM_OUTCOME,
];

module.exports = {
  VULNERABILITIES,
  VULNERABILITY_LABELS,
  EXCLUSIONS,
  ABSOLUTE_EXCLUSIONS,
  SUMMARY_ELIGIBLE_EXCEPTIONS,
  ELIGIBILITY_CRITERIA,
  PROGRAM_STAGE_KEYS,
  PROGRAM_STAGES,
};
