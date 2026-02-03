const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { auditLog } = require('../middleware/auditLog');
const { ROLES } = require('../config/roles');
const referralService = require('../services/referralService');

router.use(authenticate);

router.post(
  '/',
  authorize(ROLES.POLICE_OFFICER, ROLES.REQUESTING_PARTY, ROLES.ADMIN),
  auditLog('CREATE_REFERRAL'),
  async (req, res, next) => {
    try {
      const referral = await referralService.create(req.body, req.user);
      res.status(201).json(referral);
    } catch (err) {
      next(err);
    }
  }
);

router.get('/', auditLog('LIST_REFERRALS'), async (req, res, next) => {
  try {
    const referrals = await referralService.list(req.user);
    res.json(referrals);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', auditLog('VIEW_REFERRAL'), async (req, res, next) => {
  try {
    const referral = await referralService.getById(req.params.id, req.user);
    res.json(referral);
  } catch (err) {
    next(err);
  }
});

router.patch(
  '/:id/status',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.PHYSICIAN, ROLES.ADMIN),
  auditLog('UPDATE_REFERRAL_STATUS'),
  async (req, res, next) => {
    try {
      const referral = await referralService.updateStatus(req.params.id, req.body.status, req.user);
      res.json(referral);
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
