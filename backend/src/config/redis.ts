import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

const redisHost = process.env.REDIS_HOST || 'localhost';
const redisPort = parseInt(process.env.REDIS_PORT || '6379');

export const redisClient = new Redis({
  host: redisHost,
  port: redisPort,
  maxRetriesPerRequest: null,
  reconnectOnError: (err) => {
    console.error('Redis reconnect error:', err);
    return true;
  }
});

redisClient.on('connect', () => {
  console.log('Successfully connected to Redis instance.');
});

redisClient.on('error', (err) => {
  console.error('Redis client failure:', err);
});
