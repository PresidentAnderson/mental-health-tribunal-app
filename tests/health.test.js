const request = require('supertest');

// Mock pg before requiring app
jest.mock('pg', () => {
  const pool = { query: jest.fn(), end: jest.fn() };
  return { Pool: jest.fn(() => pool) };
});

const app = require('../src/index');

describe('GET /health', () => {
  it('should return status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});
