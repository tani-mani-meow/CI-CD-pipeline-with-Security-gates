function requestLogger(req, res, next) {
  if (process.env.NODE_ENV === 'test') {
    return next();
  }

  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const log = {
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('user-agent') || 'unknown',
      ip: req.ip,
      contentLength: res.get('content-length') || 0,
    };

    if (res.statusCode >= 500) {
      console.error(JSON.stringify(log));
    } else if (res.statusCode >= 400) {
      console.warn(JSON.stringify(log));
    } else {
      console.log(JSON.stringify(log));
    }
  });

  next();
}

module.exports = { requestLogger };
