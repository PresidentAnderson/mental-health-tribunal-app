const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { auditLog } = require('../middleware/auditLog');
const { ROLES } = require('../config/roles');
const pajsmService = require('../services/pajsmService');
const eligibilityService = require('../services/eligibilityService');

router.use(authenticate);

// Reference endpoints
router.get('/reference/vulnerabilities', auditLog('LIST_VULNERABILITIES'), async (req, res, next) => {
  try {
    res.json(eligibilityService.getVulnerabilityTypes());
  } catch (err) {
    next(err);
  }
});

router.get('/reference/exclusions', auditLog('LIST_EXCLUSIONS'), async (req, res, next) => {
  try {
    res.json(eligibilityService.getExclusions());
  } catch (err) {
    next(err);
  }
});

// Eligibility check
router.post('/eligibility/check', auditLog('CHECK_ELIGIBILITY'), async (req, res, next) => {
  try {
    const result = eligibilityService.checkEligibility(req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// Enroll
router.post(
  '/enroll',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.PROSECUTOR, ROLES.ADMIN),
  auditLog('PAJSM_ENROLL'),
  async (req, res, next) => {
    try {
      const participant = await pajsmService.enroll(req.body, req.user);
      res.status(201).json(participant);
    } catch (err) {
      next(err);
    }
  }
);

// List participants
router.get('/', auditLog('PAJSM_LIST'), async (req, res, next) => {
  try {
    const participants = await pajsmService.list(req.user);
    res.json(participants);
  } catch (err) {
    next(err);
  }
});

// Get participant by ID
router.get('/:id', auditLog('PAJSM_VIEW'), async (req, res, next) => {
  try {
    const participant = await pajsmService.getById(req.params.id, req.user);
    res.json(participant);
  } catch (err) {
    next(err);
  }
});

// Advance stage
router.patch(
  '/:id/advance',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.PROSECUTOR, ROLES.TRIBUNAL_MEMBER, ROLES.ADMIN),
  auditLog('PAJSM_ADVANCE_STAGE'),
  async (req, res, next) => {
    try {
      const participant = await pajsmService.advanceStage(req.params.id, req.user);
      res.json(participant);
    } catch (err) {
      next(err);
    }
  }
);

// Withdraw
router.patch(
  '/:id/withdraw',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.PROSECUTOR, ROLES.TRIBUNAL_MEMBER, ROLES.ADMIN),
  auditLog('PAJSM_WITHDRAW'),
  async (req, res, next) => {
    try {
      const participant = await pajsmService.withdraw(req.params.id, req.body.reason, req.user);
      res.json(participant);
    } catch (err) {
      next(err);
    }
  }
);

// Revoke victim consent
router.patch(
  '/:id/revoke-consent',
  authorize(ROLES.ADMIN),
  auditLog('PAJSM_REVOKE_CONSENT'),
  async (req, res, next) => {
    try {
      const participant = await pajsmService.revokeVictimConsent(req.params.id, req.user);
      res.json(participant);
    } catch (err) {
      next(err);
    }
  }
);

// Create intervention plan
router.post(
  '/:id/intervention-plan',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.ADMIN),
  auditLog('PAJSM_CREATE_INTERVENTION_PLAN'),
  async (req, res, next) => {
    try {
      const plan = await pajsmService.createInterventionPlan(req.params.id, req.body, req.user);
      res.status(201).json(plan);
    } catch (err) {
      next(err);
    }
  }
);

// Add follow-up
router.post(
  '/:id/follow-ups',
  authorize(ROLES.TRIBUNAL_MEMBER, ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.ADMIN),
  auditLog('PAJSM_ADD_FOLLOW_UP'),
  async (req, res, next) => {
    try {
      const followUp = await pajsmService.addFollowUp(req.params.id, req.body, req.user);
      res.status(201).json(followUp);
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
