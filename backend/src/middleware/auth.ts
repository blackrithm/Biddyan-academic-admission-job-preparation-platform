import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'biddyan_jwt_secret_high_entropy_2026_super_key';

export type AuthenticatedRequest = Request & {
  auth?: { userId: string; role: string };
};

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const header = req.header('Authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Authentication required' });

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId?: string; role?: string };
    if (!payload.userId || payload.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    (req as AuthenticatedRequest).auth = {
      userId: payload.userId,
      role: payload.role,
    };
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired authentication token' });
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.header('Authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Authentication required' });

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId?: string; role?: string };
    if (!payload.userId) return res.status(401).json({ error: 'Invalid authentication token' });
    (req as AuthenticatedRequest).auth = {
      userId: payload.userId,
      role: payload.role || 'student',
    };
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired authentication token' });
  }
}

export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.header('Authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (token) {
    try {
      const payload = jwt.verify(token, JWT_SECRET) as { userId?: string; role?: string };
      if (payload.userId) {
        (req as AuthenticatedRequest).auth = {
          userId: payload.userId,
          role: payload.role || 'student',
        };
      }
    } catch (_) {}
  }
  return next();
}