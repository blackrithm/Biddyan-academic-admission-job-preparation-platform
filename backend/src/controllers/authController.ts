import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { redisClient } from '../config/redis';

const JWT_SECRET = process.env.JWT_SECRET || 'biddyan_jwt_secret_high_entropy_2026_super_key';

export class AuthController {
  /**
   * Request OTP
   * Generates a 6-digit random code, saves to Redis with a 5-minute expiry, and returns it.
   */
  static async requestOtp(req: Request, res: Response) {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    try {
      // 1. Generate standard 6-digit OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // 2. Cache inside Redis with 300 seconds TTL (5 minutes)
      const redisKey = `phone:otp:${phoneNumber}`;
      await redisClient.setex(redisKey, 300, otp);

      console.log(`[MOCK OTP SERVICE] Sent OTP "${otp}" to phone ${phoneNumber}`);

      return res.status(200).json({
        message: 'OTP sent successfully',
        phoneNumber,
        otp // Returning OTP in response for development simulation and automated testing
      });
    } catch (error: any) {
      console.error('Error in requestOtp:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Verify OTP and Login
   */
  static async verifyOtp(req: Request, res: Response) {
    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || !otp) {
      return res.status(400).json({ error: 'Phone number and OTP code are required' });
    }

    try {
      const redisKey = `phone:otp:${phoneNumber}`;
      const cachedOtp = await redisClient.get(redisKey);

      if (!cachedOtp) {
        return res.status(400).json({ error: 'OTP code has expired or was not requested' });
      }

      if (cachedOtp !== otp) {
        return res.status(400).json({ error: 'Invalid OTP code' });
      }

      // Valid OTP. Delete cached copy to prevent reuse
      await redisClient.del(redisKey);

      // Generate a deterministic fake userId based on phone for simulation or insert dynamic users
      // To satisfy cross-platform, we generate a mock standard UUID format
      const userId = 'b1dd1a11-0000-4000-8000-' + phoneNumber.substring(phoneNumber.length - 12).padStart(12, '0');

      // Sign JWT payload
      const token = jwt.sign({ userId, phoneNumber, role: 'user' }, JWT_SECRET, { expiresIn: '30d' });

      return res.status(200).json({
        message: 'Authentication successful',
        userId,
        token,
        user: {
          phoneNumber,
          displayName: `User ${phoneNumber.substring(phoneNumber.length - 4)}`
        }
      });
    } catch (error: any) {
      console.error('Error in verifyOtp:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Mock Social Login (Google / Facebook / Apple)
   */
  static async socialLogin(req: Request, res: Response) {
    const { provider, accessToken, email, name, providerId } = req.body;

    if (!provider || !providerId) {
      return res.status(400).json({ error: 'provider and providerId are required' });
    }

    try {
      // Mock generation of userId
      const userId = '50c1a110-0000-4000-8000-' + providerId.substring(providerId.length - 12).padStart(12, '0');
      const token = jwt.sign({ userId, email, role: 'user' }, JWT_SECRET, { expiresIn: '30d' });

      return res.status(200).json({
        message: `Authentication through ${provider} successful`,
        userId,
        token,
        user: {
          email: email || `${providerId}@biddyan-social.com`,
          displayName: name || `${provider} User`
        }
      });
    } catch (error: any) {
      console.error('Error in socialLogin:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}
