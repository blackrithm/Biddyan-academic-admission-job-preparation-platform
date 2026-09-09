import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { redisClient } from '../config/redis';
import { pool } from '../config/db';
import bcrypt from 'bcrypt';

const JWT_SECRET = process.env.JWT_SECRET || 'biddyan_jwt_secret_high_entropy_2026_super_key';

export class AuthController {
  static async register(req: Request, res: Response) {
    const { phoneNumber, password, guestId, role = 'student' } = req.body;
    const accountRole = role === 'admin' ? 'admin' : 'student';
    if (!phoneNumber || !password || password.length < 4) {
      return res.status(400).json({ error: 'Phone number and a 4+ character password are required' });
    }
    try {
      const passwordHash = await bcrypt.hash(password, 12);
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const existing = guestId
          ? await client.query('SELECT id FROM users WHERE id = $1 AND phone_number IS NULL', [guestId])
          : { rows: [] };
        const result = existing.rows.length
          ? await client.query(
              `UPDATE users SET phone_number = $1, password_hash = $2,
               display_name = $3, role = $4 WHERE id = $5
               RETURNING id, phone_number, display_name, role`,
              [phoneNumber, passwordHash, `User ${phoneNumber.slice(-4)}`, accountRole, guestId],
            )
          : await client.query(
              `INSERT INTO users (phone_number, password_hash, display_name, role)
               VALUES ($1, $2, $3, $4)
               RETURNING id, phone_number, display_name, role`,
              [phoneNumber, passwordHash, `User ${phoneNumber.slice(-4)}`, accountRole],
            );
        if (guestId) {
          await client.query('UPDATE user_exam_attempts SET user_id = $1 WHERE user_id = $2', [result.rows[0].id, guestId]);
        }
        await client.query('COMMIT');
        return AuthController.respondWithUser(res, result.rows[0]);
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error: any) {
      if (error.code === '23505') return res.status(409).json({ error: 'এই নম্বরে ইতিমধ্যে account আছে' });
      console.error('Error in register:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  static async login(req: Request, res: Response) {
    const { phoneNumber, password, role = 'student' } = req.body;
    const accountRole = role === 'admin' ? 'admin' : 'student';
    if (!phoneNumber || !password) return res.status(400).json({ error: 'Phone number and password are required' });
    try {
      const result = await pool.query(
        'SELECT id, phone_number, display_name, role, password_hash FROM users WHERE phone_number = $1 AND (role = $2 OR ($2 = \'student\' AND role = \'user\'))',
        [phoneNumber, accountRole],
      );
      const user = result.rows[0];
      if (!user || !user.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
        return res.status(401).json({ error: 'মোবাইল নম্বর বা password সঠিক নয়' });
      }
      return AuthController.respondWithUser(res, user);
    } catch (error: any) {
      console.error('Error in login:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  private static respondWithUser(res: Response, user: any) {
    const token = jwt.sign({ userId: user.id, phoneNumber: user.phone_number, role: user.role }, JWT_SECRET, { expiresIn: '30d' });
    return res.status(200).json({
      message: 'Authentication successful',
      userId: user.id,
      token,
      user: { phoneNumber: user.phone_number, displayName: user.display_name, role: user.role },
    });
  }
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

      const userResult = await pool.query(
        `INSERT INTO users (phone_number, display_name)
         VALUES ($1, $2)
         ON CONFLICT (phone_number)
         DO UPDATE SET display_name = EXCLUDED.display_name
         RETURNING id, phone_number, display_name, role`,
        [phoneNumber, `User ${phoneNumber.substring(phoneNumber.length - 4)}`],
      );
      const user = userResult.rows[0];
      const userId = user.id;

      // Sign JWT payload
      const token = jwt.sign(
        { userId, phoneNumber, role: user.role },
        JWT_SECRET,
        { expiresIn: '30d' },
      );

      return res.status(200).json({
        message: 'Authentication successful',
        userId,
        token,
        user: {
          phoneNumber,
          displayName: user.display_name,
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
      const userResult = await pool.query(
        `INSERT INTO users (email, display_name)
         VALUES ($1, $2)
         ON CONFLICT (email)
         DO UPDATE SET display_name = EXCLUDED.display_name
         RETURNING id, email, display_name, role`,
        [email || `${providerId}@biddyan-social.com`, name || `${provider} User`],
      );
      const user = userResult.rows[0];
      const userId = user.id;
      const token = jwt.sign({ userId, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '30d' });

      return res.status(200).json({
        message: `Authentication through ${provider} successful`,
        userId,
        token,
        user: {
          email: user.email,
          displayName: user.display_name
        }
      });
    } catch (error: any) {
      console.error('Error in socialLogin:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}
