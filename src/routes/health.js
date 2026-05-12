const express = require('express');
const router = express.Router();

const startTime = Date.now();
function getUptime() {
  return Math.floor((Date.now() - startTime) / 1000);
}

router.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    uptime: getUptime(),
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
  });
});

router.get('/ready', (_req, res) => {
  const checks = {
    server: true,
    memory: process.memoryUsage().heapUsed < 500 * 1024 * 1024,
  };

  const allHealthy = Object.values(checks).every(Boolean);

  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ready' : 'not_ready',
    checks,
    timestamp: new Date().toISOString(),
  });
});

router.get('/api/info', (_req, res) => {
  res.status(200).json({
    name: 'cicd-pipeline',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    commit: process.env.COMMIT_SHA || 'unknown',
    buildDate: process.env.BUILD_DATE || 'unknown',
    nodeVersion: process.version,
  });
});

router.get('/api/metrics', (_req, res) => {
  const mem = process.memoryUsage();

  res.status(200).json({
    uptime: getUptime(),
    memory: {
      rss: `${(mem.rss / 1024 / 1024).toFixed(2)} MB`,
      heapTotal: `${(mem.heapTotal / 1024 / 1024).toFixed(2)} MB`,
      heapUsed: `${(mem.heapUsed / 1024 / 1024).toFixed(2)} MB`,
      external: `${(mem.external / 1024 / 1024).toFixed(2)} MB`,
    },
    cpu: process.cpuUsage(),
    pid: process.pid,
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
