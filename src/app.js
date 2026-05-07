const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const healthRoutes = require('./routes/health');
const { requestLogger } = require('./middleware/logger');

const app = express();

app.use(helmet());

app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));
app.use(requestLogger);

app.use('/', healthRoutes);

app.get('/', (_req, res) => {
  res.json({
    name: 'cicd-pipeline',
    version: process.env.npm_package_version || '1.0.0',
    description: 'End-to-end CI/CD pipeline with security gates',
  });
});

app.use((_req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource does not exist',
    status: 404,
  });
});

app.use((err, _req, res, _next) => {
  const status = err.status || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal Server Error'
    : err.message;

  console.error(`[ERROR] ${err.message}`, {
    status,
    stack: err.stack,
    timestamp: new Date().toISOString(),
  });

  res.status(status).json({
    error: err.name || 'Error',
    message,
    status,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

module.exports = app;
