const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/app');

beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI_TEST || 'mongodb://localhost:27017/billqube_test');
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

describe('POST /api/v1/auth/register', () => {
  const validUser = {
    fullName: 'Test User',
    email: 'test@billqube.in',
    mobile: '9876543210',
    password: 'Test@1234',
    confirmPassword: 'Test@1234',
    acceptTerms: true,
  };

  it('should register a new user successfully', async () => {
    const res = await request(app).post('/api/v1/auth/register').send(validUser);
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.userId).toBeDefined();
  });

  it('should reject duplicate email', async () => {
    const res = await request(app).post('/api/v1/auth/register').send(validUser);
    expect(res.statusCode).toBe(409);
  });

  it('should reject weak password', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      ...validUser,
      email: 'new@test.com',
      mobile: '9000000001',
      password: 'weakpass',
      confirmPassword: 'weakpass',
    });
    expect(res.statusCode).toBe(422);
  });

  it('should reject mismatched passwords', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      ...validUser,
      email: 'another@test.com',
      mobile: '9000000002',
      confirmPassword: 'Different@1234',
    });
    expect(res.statusCode).toBe(422);
  });
});

describe('POST /api/v1/auth/login', () => {
  it('should return 401 for wrong credentials', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'test@billqube.in',
      password: 'WrongPass@123',
    });
    expect(res.statusCode).toBe(401);
  });
});
