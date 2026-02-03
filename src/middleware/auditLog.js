const { logger } = require('../utils/logger');

function auditLog(action) {
  return (req, res, next) => {
    const entry = {
      action,
      userId: req.user?.id || 'anonymous',
      role: req.user?.role || 'unknown',
      path: req.path,
      method: req.method,
      timestamp: new Date().toISOString(),
    };

    logger.info({ audit: entry });
    next();
  };
}

module.exports = { auditLog };
