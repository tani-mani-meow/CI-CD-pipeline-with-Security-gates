const request = require('supertest');
const app = require('../../src/app');

describe('Express App', () => {
  describe('Error Handling', () => {
    it('should return 404 JSON for unknown routes', async () => {
      const res = await request(app).get('/unknown-route-xyz');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error', 'Not Found');
      expect(res.body).toHaveProperty('message');
      expect(res.body).toHaveProperty('status', 404);
    });

    it('should return JSON content-type for 404s', async () => {
      const res = await request(app).get('/does-not-exist');

      expect(res.headers['content-type']).toMatch(/application\/json/);
    });
  });

  describe('Root Route', () => {
    it('should return app info at GET /', async () => {
      const res = await request(app).get('/');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name', 'cicd-pipeline');
      expect(res.body).toHaveProperty('description');
    });
  });
});

describe('Logger Middleware', () => {
  const { requestLogger } = require('../../src/middleware/logger');

  it('should call next() immediately in test environment', () => {
    const req = { method: 'GET', originalUrl: '/test', get: jest.fn(), ip: '127.0.0.1' };
    const res = {
      on: jest.fn(),
      statusCode: 200,
      get: jest.fn(() => '42'),
    };
    const next = jest.fn();

    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'test';

    requestLogger(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);

    process.env.NODE_ENV = originalEnv;
  });

  it('should attach a finish listener in non-test environment', () => {
    const req = { method: 'GET', originalUrl: '/test', get: jest.fn(() => 'test-agent'), ip: '127.0.0.1' };
    const res = {
      on: jest.fn(),
      statusCode: 200,
      get: jest.fn(() => '100'),
    };
    const next = jest.fn();

    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    requestLogger(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.on).toHaveBeenCalledWith('finish', expect.any(Function));

    process.env.NODE_ENV = originalEnv;
  });

  it('should log on response finish with correct format', () => {
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
    const req = { method: 'GET', originalUrl: '/test', get: jest.fn(() => 'test-agent'), ip: '127.0.0.1' };
    const res = {
      on: jest.fn(),
      statusCode: 200,
      get: jest.fn(() => '42'),
    };
    const next = jest.fn();

    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    requestLogger(req, res, next);

    const finishCallback = res.on.mock.calls[0][1];
    finishCallback();

    expect(consoleSpy).toHaveBeenCalledTimes(1);
    const logOutput = JSON.parse(consoleSpy.mock.calls[0][0]);
    expect(logOutput).toHaveProperty('method', 'GET');
    expect(logOutput).toHaveProperty('path', '/test');
    expect(logOutput).toHaveProperty('status', 200);
    expect(logOutput).toHaveProperty('timestamp');

    consoleSpy.mockRestore();
    process.env.NODE_ENV = originalEnv;
  });

  it('should use console.error for 5xx status codes', () => {
    const errorSpy = jest.spyOn(console, 'error').mockImplementation();
    const req = { method: 'POST', originalUrl: '/fail', get: jest.fn(() => 'agent'), ip: '127.0.0.1' };
    const res = {
      on: jest.fn(),
      statusCode: 500,
      get: jest.fn(() => '0'),
    };
    const next = jest.fn();

    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    requestLogger(req, res, next);

    const finishCallback = res.on.mock.calls[0][1];
    finishCallback();

    expect(errorSpy).toHaveBeenCalledTimes(1);

    errorSpy.mockRestore();
    process.env.NODE_ENV = originalEnv;
  });

  it('should use console.warn for 4xx status codes', () => {
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation();
    const req = { method: 'GET', originalUrl: '/missing', get: jest.fn(() => 'agent'), ip: '127.0.0.1' };
    const res = {
      on: jest.fn(),
      statusCode: 404,
      get: jest.fn(() => '0'),
    };
    const next = jest.fn();

    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    requestLogger(req, res, next);

    const finishCallback = res.on.mock.calls[0][1];
    finishCallback();

    expect(warnSpy).toHaveBeenCalledTimes(1);

    warnSpy.mockRestore();
    process.env.NODE_ENV = originalEnv;
  });

});
