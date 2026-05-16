const request = require('supertest');
const app = require('../../src/app');

describe('Health Endpoints', () => {
  describe('GET /health', () => {
    it('should return 200 with health status', async () => {
      const res = await request(app).get('/health');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'ok');
      expect(res.body).toHaveProperty('uptime');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('version');
    });

    it('should return valid ISO timestamp', async () => {
      const res = await request(app).get('/health');
      const date = new Date(res.body.timestamp);

      expect(date.toISOString()).toBe(res.body.timestamp);
    });

    it('should return JSON content type', async () => {
      const res = await request(app).get('/health');

      expect(res.headers['content-type']).toMatch(/application\/json/);
    });
  });

  describe('GET /ready', () => {
    it('should return 200 when service is ready', async () => {
      const res = await request(app).get('/ready');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'ready');
      expect(res.body).toHaveProperty('checks');
      expect(res.body.checks).toHaveProperty('server', true);
      expect(res.body.checks).toHaveProperty('memory');
    });

    it('should include timestamp', async () => {
      const res = await request(app).get('/ready');

      expect(res.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/info', () => {
    it('should return 200 with application metadata', async () => {
      const res = await request(app).get('/api/info');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name', 'cicd-pipeline');
      expect(res.body).toHaveProperty('version');
      expect(res.body).toHaveProperty('environment');
      expect(res.body).toHaveProperty('commit');
      expect(res.body).toHaveProperty('buildDate');
      expect(res.body).toHaveProperty('nodeVersion');
    });

    it('should include the Node.js version', async () => {
      const res = await request(app).get('/api/info');

      expect(res.body.nodeVersion).toMatch(/^v\d+/);
    });
  });

  describe('GET /api/metrics', () => {
    it('should return 200 with runtime metrics', async () => {
      const res = await request(app).get('/api/metrics');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('uptime');
      expect(res.body).toHaveProperty('memory');
      expect(res.body.memory).toHaveProperty('rss');
      expect(res.body.memory).toHaveProperty('heapUsed');
      expect(res.body).toHaveProperty('pid');
    });
  });
});


