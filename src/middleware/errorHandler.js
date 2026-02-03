const { logger } = require('../utils/logger');

function errorHandler(err, req, res, next) {
  logger.error({ message: err.message, stack: err.stack, path: req.path });

  const status = err.statusCode || 500;
  res.status(status).json({
    error: {
      message: status === 500 ? 'Internal server error' : err.message,
    },
  });
}

module.exports = { errorHandler };
