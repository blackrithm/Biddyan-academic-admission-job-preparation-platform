import { Request, Response } from 'express';
import { pool } from '../config/db';
import { AuthenticatedRequest } from '../middleware/auth';

export class RoutineController {
  static async list(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `SELECT id, title, category, subject, duration_minutes,
                scheduled_date, note, completed
         FROM study_plans
         WHERE user_id = $1
         ORDER BY scheduled_date ASC, created_at ASC`,
        [userId],
      );
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async create(req: Request, res: Response) {
    const { title, category, subject, durationMinutes, scheduledDate, note } = req.body;
    if (!title || !category || !subject || !scheduledDate) {
      return res.status(400).json({ error: 'title, category, subject and scheduledDate are required' });
    }
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `INSERT INTO study_plans
           (user_id, title, category, subject, duration_minutes, scheduled_date, note)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, title, category, subject, duration_minutes,
                   scheduled_date, note, completed`,
        [userId, String(title).trim(), category, subject, durationMinutes ?? 30, scheduledDate, note ?? ''],
      );
      return res.status(201).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async update(req: Request, res: Response) {
    const { id } = req.params;
    const { title, category, subject, durationMinutes, scheduledDate, note, completed } = req.body;
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `UPDATE study_plans
         SET title = COALESCE($3, title), category = COALESCE($4, category),
             subject = COALESCE($5, subject), duration_minutes = COALESCE($6, duration_minutes),
             scheduled_date = COALESCE($7, scheduled_date), note = COALESCE($8, note),
             completed = COALESCE($9, completed), updated_at = NOW()
         WHERE id = $1 AND user_id = $2
         RETURNING id, title, category, subject, duration_minutes,
                   scheduled_date, note, completed`,
        [id, userId, title, category, subject, durationMinutes, scheduledDate, note, completed],
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Study plan not found' });
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async remove(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query('DELETE FROM study_plans WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      if (result.rowCount === 0) return res.status(404).json({ error: 'Study plan not found' });
      return res.status(204).send();
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}