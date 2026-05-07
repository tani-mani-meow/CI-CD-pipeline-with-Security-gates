const app = require('./app');

const PORT = parseInt(process.env.PORT, 10) || 3000;
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT} [${process.env.NODE_ENV || 'development'}]`);
});

const SHUTDOWN_TIMEOUT_MS = 10_000;

function gracefulShutdown(signal) {
  console.log(`\n[SHUTDOWN] Received ${signal}. Closing server gracefully…`);

  server.close((err) => {
    if (err) {
      console.error('[SHUTDOWN] Error during shutdown:', err);
      process.exit(1);
    }
    console.log('[SHUTDOWN] All connections closed.');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('[SHUTDOWN] Forcefully terminating — timeout exceeded');
    process.exit(1);
  }, SHUTDOWN_TIMEOUT_MS);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = server;
