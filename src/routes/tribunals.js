const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { auditLog } = require('../middleware/auditLog');
const { ROLES } = require('../config/roles');
const tribunalService = require('../services/tribunalService');

router.use(authenticate);

router.post(
  '/',
  authorize(ROLES.TRIBUNAL_MEMBER, ROLES.ADMIN),
  auditLog('SCHEDULE_HEARING'),
  async (req, res, next) => {
    try {
      const hearing = await tribunalService.schedule(req.body, req.user);
      res.status(201).json(hearing);
    } catch (err) {
      next(err);
    }
  }
);

router.get('/', auditLog('LIST_HEARINGS'), async (req, res, next) => {
  try {
    const hearings = await tribunalService.list(req.user);
    res.json(hearings);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', auditLog('VIEW_HEARING'), async (req, res, next) => {
  try {
    const hearing = await tribunalService.getById(req.params.id, req.user);
    res.json(hearing);
  } catch (err) {
    next(err);
  }
});

router.patch(
  '/:id/decision',
  authorize(ROLES.TRIBUNAL_MEMBER),
  auditLog('RECORD_DECISION'),
  async (req, res, next) => {
    try {
      const hearing = await tribunalService.recordDecision(req.params.id, req.body, req.user);
      res.json(hearing);
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
