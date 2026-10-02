import { Request, Response } from 'express';
import { pool } from '../config/db';
import { AuthenticatedRequest } from '../middleware/auth';

export class ExamBatchController {
  static async list(_req: Request, res: Response) {
    try {
      const result = await pool.query(`
        SELECT b.*, COUNT(DISTINCT be.exam_id)::int AS exam_count,
           COUNT(DISTINCT en.user_id)::int AS enrolled_count,
           COALESCE(
             ARRAY_AGG(DISTINCT t.question_type) FILTER (WHERE t.question_type IS NOT NULL),
             ARRAY[]::VARCHAR[]
           ) AS question_types
        FROM exam_batches b
        LEFT JOIN exam_batch_exams be ON be.batch_id = b.id
         LEFT JOIN exams e ON e.id = be.exam_id
         LEFT JOIN topics t ON t.id = e.topic_id
        LEFT JOIN exam_batch_enrollments en ON en.batch_id = b.id
        WHERE b.is_published = TRUE
        GROUP BY b.id
        ORDER BY b.sort_order ASC, b.created_at DESC
      `);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async mine(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(`
        SELECT b.*, COUNT(DISTINCT be.exam_id)::int AS exam_count,
               COUNT(DISTINCT en.user_id)::int AS enrolled_count
        FROM exam_batch_enrollments mine
        JOIN exam_batches b ON b.id = mine.batch_id
        LEFT JOIN exam_batch_exams be ON be.batch_id = b.id
        LEFT JOIN exam_batch_enrollments en ON en.batch_id = b.id
        WHERE mine.user_id = $1
        GROUP BY b.id
        ORDER BY mine.enrolled_at DESC
      `, [userId]);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const batch = await pool.query(`
        SELECT b.*, COUNT(DISTINCT en.user_id)::int AS enrolled_count,
               EXISTS (
                 SELECT 1 FROM exam_batch_enrollments mine
                 WHERE mine.batch_id = b.id AND mine.user_id = $2
               ) AS is_enrolled
        FROM exam_batches b
        LEFT JOIN exam_batch_enrollments en ON en.batch_id = b.id
        WHERE b.id = $1 AND b.is_published = TRUE
        GROUP BY b.id
      `, [req.params.batchId, (req as AuthenticatedRequest).auth?.userId ?? null]);
      if (batch.rows.length === 0) return res.status(404).json({ error: 'Exam batch not found' });

      const exams = await pool.query(`
        SELECT e.id, e.title, e.total_marks, e.pass_mark, e.negative_marking_per_wrong,
               e.duration_minutes, e.topic_id, t.name AS topic_name,
               be.starts_at, be.ends_at,
               (SELECT COUNT(*)::int FROM exam_questions eq WHERE eq.exam_id = e.id) AS question_count
        FROM exam_batch_exams be
        JOIN exams e ON e.id = be.exam_id
        LEFT JOIN topics t ON t.id = e.topic_id
        WHERE be.batch_id = $1
        ORDER BY be.starts_at ASC
      `, [req.params.batchId]);
      return res.status(200).json({ ...batch.rows[0], exams: exams.rows });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async create(req: Request, res: Response) {
    const { name, examType, description = '', imageUrl = null, exams } = req.body;
    if (!String(name ?? '').trim() || !String(examType ?? '').trim() || !Array.isArray(exams) || exams.length === 0) {
      return res.status(400).json({ error: 'name, examType and at least one scheduled exam are required' });
    }
    const schedules = exams.map((item: any) => ({
      examId: String(item.examId ?? ''),
      startsAt: new Date(item.startsAt),
    }));
    if (schedules.some((item: any) => !item.examId || Number.isNaN(item.startsAt.getTime()))) {
      return res.status(400).json({ error: 'Every exam needs a valid examId and startsAt' });
    }
    if (new Set(schedules.map((item: any) => item.examId)).size !== schedules.length) {
      return res.status(400).json({ error: 'An exam can only be added once to a batch' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('LOCK TABLE exam_batches IN EXCLUSIVE MODE');
      const order = await client.query('SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exam_batches');
      const createdBy = (req as AuthenticatedRequest).auth!.userId;
      const batchResult = await client.query(`
        INSERT INTO exam_batches (name, exam_type, description, image_url, sort_order, created_by)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `, [String(name).trim(), String(examType).trim(), String(description).trim(), imageUrl, order.rows[0].next_order, createdBy]);
      const batch = batchResult.rows[0];

      for (const schedule of schedules) {
        const examResult = await client.query(
          'SELECT duration_minutes FROM exams WHERE id = $1',
          [schedule.examId],
        );
        if (examResult.rows.length === 0) throw new Error('One or more selected exams do not exist');
        const endsAt = new Date(schedule.startsAt.getTime() + Number(examResult.rows[0].duration_minutes) * 60000);
        await client.query(`
          INSERT INTO exam_batch_exams (batch_id, exam_id, starts_at, ends_at)
          VALUES ($1, $2, $3, $4)
        `, [batch.id, schedule.examId, schedule.startsAt.toISOString(), endsAt.toISOString()]);
      }

      await client.query('COMMIT');
      return res.status(201).json(batch);
    } catch (error: any) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async update(req: Request, res: Response) {
    const { name, examType, description = '', imageUrl = null, exams } = req.body;
    if (!String(name ?? '').trim() || !String(examType ?? '').trim() || !Array.isArray(exams) || exams.length === 0) {
      return res.status(400).json({ error: 'name, examType and at least one scheduled exam are required' });
    }
    const schedules = exams.map((item: any) => ({
      examId: String(item.examId ?? ''),
      startsAt: new Date(item.startsAt),
    }));
    if (schedules.some((item: any) => !item.examId || Number.isNaN(item.startsAt.getTime()))) {
      return res.status(400).json({ error: 'Every exam needs a valid examId and startsAt' });
    }
    if (new Set(schedules.map((item: any) => item.examId)).size !== schedules.length) {
      return res.status(400).json({ error: 'An exam can only be added once to a batch' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const updated = await client.query(`
        UPDATE exam_batches
        SET name = $1, exam_type = $2, description = $3, image_url = $4
        WHERE id = $5
        RETURNING *
      `, [String(name).trim(), String(examType).trim(), String(description).trim(), imageUrl, req.params.batchId]);
      if (updated.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Exam batch not found' });
      }

      await client.query('DELETE FROM exam_batch_exams WHERE batch_id = $1', [req.params.batchId]);
      for (const schedule of schedules) {
        const examResult = await client.query(
          'SELECT duration_minutes FROM exams WHERE id = $1',
          [schedule.examId],
        );
        if (examResult.rows.length === 0) throw new Error('One or more selected exams do not exist');
        const endsAt = new Date(schedule.startsAt.getTime() + Number(examResult.rows[0].duration_minutes) * 60000);
        await client.query(`
          INSERT INTO exam_batch_exams (batch_id, exam_id, starts_at, ends_at)
          VALUES ($1, $2, $3, $4)
        `, [req.params.batchId, schedule.examId, schedule.startsAt.toISOString(), endsAt.toISOString()]);
      }

      await client.query('COMMIT');
      return res.status(200).json(updated.rows[0]);
    } catch (error: any) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async reorder(req: Request, res: Response) {
    const { batchIds } = req.body;
    if (!Array.isArray(batchIds) || batchIds.some((id: unknown) => typeof id !== 'string') || new Set(batchIds).size !== batchIds.length) {
      return res.status(400).json({ error: 'batchIds must be a unique array of IDs' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (const [position, batchId] of batchIds.entries()) {
        const result = await client.query(
          'UPDATE exam_batches SET sort_order = $1 WHERE id = $2',
          [position, batchId],
        );
        if (result.rowCount !== 1) throw new Error('One or more exam batches do not exist');
      }
      await client.query('COMMIT');
      return res.status(200).json({ reordered: true });
    } catch (error: any) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async enroll(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(`
        INSERT INTO exam_batch_enrollments (batch_id, user_id)
        SELECT id, $2 FROM exam_batches WHERE id = $1 AND is_published = TRUE
        ON CONFLICT (batch_id, user_id) DO NOTHING
        RETURNING batch_id
      `, [req.params.batchId, userId]);
      if (result.rows.length === 0) {
        const exists = await pool.query(
          'SELECT 1 FROM exam_batches WHERE id = $1 AND is_published = TRUE',
          [req.params.batchId],
        );
        if (exists.rows.length === 0) return res.status(404).json({ error: 'Exam batch not found' });
      }
      return res.status(200).json({ enrolled: true });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}