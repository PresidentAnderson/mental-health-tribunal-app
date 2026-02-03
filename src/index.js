require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { logger } = require('./utils/logger');
const authRoutes = require('./routes/auth');
const referralRoutes = require('./routes/referrals');
const tribunalRoutes = require('./routes/tribunals');
const assessmentRoutes = require('./routes/assessments');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/referrals', referralRoutes);
app.use('/api/v1/tribunals', tribunalRoutes);
app.use('/api/v1/assessments', assessmentRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use(errorHandler);

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});

module.exports = app;
