const { checkEligibility, getExclusions, getVulnerabilityTypes } = require('../src/services/eligibilityService');

function makeEligibleData(overrides = {}) {
  return {
    vulnerabilities: ['mental_health_disorder'],
    offence_category: 'theft',
    prosecution_mode: 'summary',
    accepts_responsibility: true,
    is_voluntary: true,
    waives_delay: true,
    criminally_fit: true,
    ...overrides,
  };
}

describe('checkEligibility', () => {
  it('should pass for an eligible case with a single vulnerability', () => {
    const result = checkEligibility(makeEligibleData());
    expect(result.eligible).toBe(true);
    expect(result.reasons).toHaveLength(0);
  });

  it('should pass for an eligible case with comorbid vulnerabilities', () => {
    const result = checkEligibility(
      makeEligibleData({
        vulnerabilities: ['mental_health_disorder', 'substance_use_disorder', 'traumatic_brain_injury'],
      })
    );
    expect(result.eligible).toBe(true);
    expect(result.reasons).toHaveLength(0);
  });

  it('should reject death-causing offences', () => {
    const result = checkEligibility(
      makeEligibleData({ offence_category: 'death_resulting_offences' })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([
        expect.stringContaining('death_resulting_offences'),
      ])
    );
  });

  it('should reject terrorism offences', () => {
    const result = checkEligibility(
      makeEligibleData({ offence_category: 'terrorism' })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('terrorism')])
    );
  });

  it('should reject superior court jurisdiction offences', () => {
    const result = checkEligibility(
      makeEligibleData({ offence_category: 'superior_court_jurisdiction' })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('superior_court_jurisdiction')])
    );
  });

  it('should reject sexual offences against minors', () => {
    const result = checkEligibility(
      makeEligibleData({ offence_category: 'sexual_offences_against_minors' })
    );
    expect(result.eligible).toBe(false);
  });

  it('should accept summary domestic violence with victim consent', () => {
    const result = checkEligibility(
      makeEligibleData({
        offence_category: 'domestic_violence',
        prosecution_mode: 'summary',
        victim_consent: true,
      })
    );
    expect(result.eligible).toBe(true);
    expect(result.reasons).toHaveLength(0);
  });

  it('should accept summary sexual violence with victim consent', () => {
    const result = checkEligibility(
      makeEligibleData({
        offence_category: 'sexual_violence',
        prosecution_mode: 'summary',
        victim_consent: true,
      })
    );
    expect(result.eligible).toBe(true);
  });

  it('should accept summary elder abuse with victim consent', () => {
    const result = checkEligibility(
      makeEligibleData({
        offence_category: 'elder_abuse',
        prosecution_mode: 'summary',
        victim_consent: true,
      })
    );
    expect(result.eligible).toBe(true);
  });

  it('should reject summary domestic violence without victim consent', () => {
    const result = checkEligibility(
      makeEligibleData({
        offence_category: 'domestic_violence',
        prosecution_mode: 'summary',
        victim_consent: false,
      })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('victim consent')])
    );
  });

  it('should reject domestic violence prosecuted by indictment even with victim consent', () => {
    const result = checkEligibility(
      makeEligibleData({
        offence_category: 'domestic_violence',
        prosecution_mode: 'indictment',
        victim_consent: true,
      })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('summary prosecution mode')])
    );
  });

  it('should fail when no vulnerability is provided', () => {
    const result = checkEligibility(makeEligibleData({ vulnerabilities: [] }));
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('vulnerability')])
    );
  });

  it('should fail when vulnerability list contains only invalid types', () => {
    const result = checkEligibility(
      makeEligibleData({ vulnerabilities: ['not_a_real_type'] })
    );
    expect(result.eligible).toBe(false);
  });

  it('should fail when accepts_responsibility is false', () => {
    const result = checkEligibility(
      makeEligibleData({ accepts_responsibility: false })
    );
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('accept responsibility')])
    );
  });

  it('should fail when is_voluntary is false', () => {
    const result = checkEligibility(makeEligibleData({ is_voluntary: false }));
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('voluntary')])
    );
  });

  it('should fail when waives_delay is false', () => {
    const result = checkEligibility(makeEligibleData({ waives_delay: false }));
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('waive delay')])
    );
  });

  it('should fail when criminally_fit is false', () => {
    const result = checkEligibility(makeEligibleData({ criminally_fit: false }));
    expect(result.eligible).toBe(false);
    expect(result.reasons).toEqual(
      expect.arrayContaining([expect.stringContaining('criminally fit')])
    );
  });

  it('should return all failing reasons together (not short-circuit)', () => {
    const result = checkEligibility({
      vulnerabilities: [],
      offence_category: 'terrorism',
      prosecution_mode: 'indictment',
      accepts_responsibility: false,
      is_voluntary: false,
      waives_delay: false,
      criminally_fit: false,
    });
    expect(result.eligible).toBe(false);
    expect(result.reasons.length).toBeGreaterThanOrEqual(5);
  });
});

describe('getExclusions', () => {
  it('should return the full exclusion list', () => {
    const exclusions = getExclusions();
    expect(Array.isArray(exclusions)).toBe(true);
    expect(exclusions).toContain('terrorism');
    expect(exclusions).toContain('death_resulting_offences');
    expect(exclusions).toContain('domestic_violence');
  });
});

describe('getVulnerabilityTypes', () => {
  it('should return vulnerability types with keys and labels', () => {
    const types = getVulnerabilityTypes();
    expect(Array.isArray(types)).toBe(true);
    expect(types.length).toBe(5);
    types.forEach((t) => {
      expect(t).toHaveProperty('key');
      expect(t).toHaveProperty('label');
    });
  });
});
