const {
  VULNERABILITIES,
  VULNERABILITY_LABELS,
  EXCLUSIONS,
  ABSOLUTE_EXCLUSIONS,
  SUMMARY_ELIGIBLE_EXCEPTIONS,
} = require('../config/pajsm');

const VALID_VULNERABILITIES = Object.values(VULNERABILITIES);

function checkEligibility(data) {
  const reasons = [];

  // 1. At least one recognized vulnerability
  const hasVulnerability =
    Array.isArray(data.vulnerabilities) &&
    data.vulnerabilities.some((v) => VALID_VULNERABILITIES.includes(v));
  if (!hasVulnerability) {
    reasons.push('At least one recognized vulnerability is required');
  }

  // 2. Offence not in absolute exclusion list
  if (ABSOLUTE_EXCLUSIONS.includes(data.offence_category)) {
    reasons.push(`Offence category "${data.offence_category}" is absolutely excluded from PAJ-SM+`);
  }

  // 3. If conditionally-excluded (summary eligible exception), check prosecution mode and victim consent
  if (SUMMARY_ELIGIBLE_EXCEPTIONS.includes(data.offence_category)) {
    if (data.prosecution_mode !== 'summary') {
      reasons.push(
        `Offence category "${data.offence_category}" requires summary prosecution mode`
      );
    }
    if (data.victim_consent !== true) {
      reasons.push(
        `Offence category "${data.offence_category}" requires victim consent`
      );
    }
  }

  // 4. Accused accepts responsibility
  if (!data.accepts_responsibility) {
    reasons.push('Accused must accept responsibility');
  }

  // 5. Voluntary participation
  if (!data.is_voluntary) {
    reasons.push('Participation must be voluntary');
  }

  // 6. Waives delay rights
  if (!data.waives_delay) {
    reasons.push('Accused must waive delay rights');
  }

  // 7. Criminally fit and responsible
  if (!data.criminally_fit) {
    reasons.push('Accused must be criminally fit and responsible');
  }

  return {
    eligible: reasons.length === 0,
    reasons,
  };
}

function getExclusions() {
  return EXCLUSIONS;
}

function getVulnerabilityTypes() {
  return VALID_VULNERABILITIES.map((key) => ({
    key,
    label: VULNERABILITY_LABELS[key],
  }));
}

module.exports = { checkEligibility, getExclusions, getVulnerabilityTypes };
