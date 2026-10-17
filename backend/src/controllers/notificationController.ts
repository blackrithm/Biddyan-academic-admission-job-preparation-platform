import { Request, Response } from 'express';
import { pool } from '../config/db';

export class NotificationController {
  static async list(_req: Request, res: Response) {
    try {
      const result = await pool.query(
        `SELECT id, title, message, category, created_at AS "createdAt"
         FROM notifications
         ORDER BY created_at DESC;`,
      );
      return res.status(200).json(result.rows);
    } catch (error: any) {
      console.error('Error listing notifications:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  static async create(req: Request, res: Response) {
    const title = typeof req.body.title === 'string' ? req.body.title.trim() : '';
    const message = typeof req.body.message === 'string' ? req.body.message.trim() : '';
    if (!title || !message) {
      return res.status(400).json({ error: 'Title and message are required' });
    }

    try {
      const result = await pool.query(
        `INSERT INTO notifications (title, message)
         VALUES ($1, $2)
         RETURNING id, title, message, category, created_at AS "createdAt";`,
        [title, message],
      );
      return res.status(201).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error creating notification:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  static async remove(req: Request, res: Response) {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(req.params.id)) {
      return res.status(400).json({ error: 'Invalid notification id' });
    }

    try {
      const result = await pool.query('DELETE FROM notifications WHERE id = $1 RETURNING id;', [req.params.id]);
      if (result.rowCount === 0) {
        return res.status(404).json({ error: 'Notification not found' });
      }
      return res.status(200).json({ message: 'Notification deleted' });
    } catch (error: any) {
      console.error('Error deleting notification:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}