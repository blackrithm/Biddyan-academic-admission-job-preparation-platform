import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import apiRoutes from './routes/api';
import { pool } from './config/db';
import { redisClient } from './config/redis';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS for all requests (crucial for Flutter Web client access)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// Application API routes
app.use('/api', apiRoutes);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Check Postgres Connection
    await pool.query('SELECT 1');
    // Check Redis Connection
    const redisPing = await redisClient.ping();
    
    return res.status(200).json({
      status: 'healthy',
      postgres: 'connected',
      redis: redisPing === 'PONG' ? 'connected' : 'error',
      timestamp: new Date()
    });
  } catch (error: any) {
    return res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date()
    });
  }
});

// Start listening
app.listen(PORT, () => {
  console.log(`===============================================`);
  console.log(`🚀 Biddyan Core Backend running on port ${PORT}`);
  console.log(`🔌 Database Pool initialized`);
  console.log(`⚡ Redis client online`);
  console.log(`===============================================`);
});
