const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { auditLog } = require('../middleware/auditLog');
const { ROLES } = require('../config/roles');
const assessmentService = require('../services/assessmentService');

router.use(authenticate);

router.post(
  '/',
  authorize(ROLES.MENTAL_HEALTH_PROFESSIONAL, ROLES.PHYSICIAN, ROLES.ADMIN),
  auditLog('CREATE_ASSESSMENT'),
  async (req, res, next) => {
    try {
      const assessment = await assessmentService.create(req.body, req.user);
      res.status(201).json(assessment);
    } catch (err) {
      next(err);
    }
  }
);

router.get('/', auditLog('LIST_ASSESSMENTS'), async (req, res, next) => {
  try {
    const assessments = await assessmentService.list(req.user);
    res.json(assessments);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', auditLog('VIEW_ASSESSMENT'), async (req, res, next) => {
  try {
    const assessment = await assessmentService.getById(req.params.id, req.user);
    res.json(assessment);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
