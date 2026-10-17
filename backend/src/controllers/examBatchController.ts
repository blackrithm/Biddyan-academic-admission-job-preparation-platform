import { Request, Response } from 'express';
import { pool } from '../config/db';
import { AuthenticatedRequest } from '../middleware/auth';

const paymentProviders = ['bkash', 'nagad', 'rocket'];
const paymentReceiver = '01301051585';

function normalizedPaymentNumber(value: unknown) {
  return String(value ?? '').replace(/[\s-]/g, '').replace(/^\+?88/, '');
}

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

      const userId = (req as AuthenticatedRequest).auth?.userId;
      const payment = userId
        ? await pool.query(`
            SELECT id, provider, amount, status, review_note, created_at
            FROM exam_batch_payment_requests
            WHERE batch_id = $1 AND user_id = $2
            ORDER BY created_at DESC
            LIMIT 1
          `, [req.params.batchId, userId])
        : { rows: [] };

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
      return res.status(200).json({
        ...batch.rows[0],
        payment_request: payment.rows[0] ?? null,
        exams: exams.rows,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async create(req: Request, res: Response) {
    const { name, examType, description = '', imageUrl = null, exams, price = 0, demoExamIds = [] } = req.body;
    if (!String(name ?? '').trim() || !String(examType ?? '').trim() || !Array.isArray(exams) || exams.length === 0) {
      return res.status(400).json({ error: 'name, examType and at least one scheduled exam are required' });
    }
    const batchPrice = Number(price);
    if (!Number.isFinite(batchPrice) || batchPrice < 0 || !Array.isArray(demoExamIds)) {
      return res.status(400).json({ error: 'price must be non-negative and demoExamIds must be an array' });
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
    if (demoExamIds.some((id: unknown) => typeof id !== 'string' || !schedules.some((schedule: any) => schedule.examId === id))) {
      return res.status(400).json({ error: 'Demo exams must be selected from the exams scheduled in this batch' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('LOCK TABLE exam_batches IN EXCLUSIVE MODE');
      const order = await client.query('SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exam_batches');
      const createdBy = (req as AuthenticatedRequest).auth!.userId;
      const batchResult = await client.query(`
        INSERT INTO exam_batches (name, exam_type, description, image_url, price, demo_exam_ids, sort_order, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `, [String(name).trim(), String(examType).trim(), String(description).trim(), imageUrl, batchPrice, demoExamIds, order.rows[0].next_order, createdBy]);
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
    const { name, examType, description = '', imageUrl = null, exams, price = 0, demoExamIds = [] } = req.body;
    if (!String(name ?? '').trim() || !String(examType ?? '').trim() || !Array.isArray(exams) || exams.length === 0) {
      return res.status(400).json({ error: 'name, examType and at least one scheduled exam are required' });
    }
    const batchPrice = Number(price);
    if (!Number.isFinite(batchPrice) || batchPrice < 0 || !Array.isArray(demoExamIds)) {
      return res.status(400).json({ error: 'price must be non-negative and demoExamIds must be an array' });
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
    if (demoExamIds.some((id: unknown) => typeof id !== 'string' || !schedules.some((schedule: any) => schedule.examId === id))) {
      return res.status(400).json({ error: 'Demo exams must be selected from the exams scheduled in this batch' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const updated = await client.query(`
        UPDATE exam_batches
        SET name = $1, exam_type = $2, description = $3, image_url = $4,
            price = $5, demo_exam_ids = $6
        WHERE id = $7
        RETURNING *
      `, [String(name).trim(), String(examType).trim(), String(description).trim(), imageUrl, batchPrice, demoExamIds, req.params.batchId]);
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
      const batch = await pool.query(
        'SELECT price FROM exam_batches WHERE id = $1 AND is_published = TRUE',
        [req.params.batchId],
      );
      if (batch.rows.length === 0) return res.status(404).json({ error: 'Exam batch not found' });
      if (Number(batch.rows[0].price) > 0) {
        return res.status(402).json({
          error: 'Payment is required to join this batch. Online payment is not configured yet.',
          price: Number(batch.rows[0].price),
        });
      }
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

  static async submitPayment(req: Request, res: Response) {
    const userId = (req as AuthenticatedRequest).auth!.userId;
    const provider = String(req.body.provider ?? '').toLowerCase();
    const paidFromNumber = normalizedPaymentNumber(req.body.paidFromNumber);
    const transactionId = String(req.body.transactionId ?? '').trim().toUpperCase();

    if (!paymentProviders.includes(provider)) {
      return res.status(400).json({ error: 'Choose bKash, Nagad, or Rocket' });
    }
    if (!/^01[3-9]\d{8}$/.test(paidFromNumber)) {
      return res.status(400).json({ error: 'Enter a valid Bangladeshi mobile number' });
    }
    if (!/^[A-Z0-9-]{5,64}$/.test(transactionId)) {
      return res.status(400).json({ error: 'Enter a valid transaction ID' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const batch = await client.query(`
        SELECT price FROM exam_batches
        WHERE id = $1 AND is_published = TRUE
        FOR SHARE
      `, [req.params.batchId]);
      if (batch.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Exam batch not found' });
      }
      const amount = Number(batch.rows[0].price);
      if (amount <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'This batch is free; use free enrollment instead' });
      }

      const enrollment = await client.query(
        'SELECT 1 FROM exam_batch_enrollments WHERE batch_id = $1 AND user_id = $2',
        [req.params.batchId, userId],
      );
      if (enrollment.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ error: 'You are already enrolled in this batch' });
      }

      const inserted = await client.query(`
        INSERT INTO exam_batch_payment_requests (
          batch_id, user_id, provider, receiver_number, pay_type, amount,
          paid_from_number, transaction_id
        ) VALUES ($1, $2, $3, $4, 'send_money', $5, $6, $7)
        RETURNING id, batch_id, provider, receiver_number, pay_type, amount,
                  paid_from_number, transaction_id, status, created_at
      `, [req.params.batchId, userId, provider, paymentReceiver, amount, paidFromNumber, transactionId]);

      await client.query('COMMIT');
      return res.status(201).json(inserted.rows[0]);
    } catch (error: any) {
      await client.query('ROLLBACK');
      if (error.code === '23505') {
        return res.status(409).json({ error: 'This transaction ID or pending payment request already exists' });
      }
      console.error('Error submitting batch payment:', error);
      return res.status(500).json({ error: 'Could not submit payment details' });
    } finally {
      client.release();
    }
  }

  static async listPayments(_req: Request, res: Response) {
    try {
      const result = await pool.query(`
        SELECT p.*, b.name AS batch_name,
               COALESCE(u.display_name, 'শিক্ষার্থী') AS student_name,
               u.phone_number AS student_phone,
               COALESCE(reviewer.display_name, '') AS reviewer_name
        FROM exam_batch_payment_requests p
        JOIN exam_batches b ON b.id = p.batch_id
        JOIN users u ON u.id = p.user_id
        LEFT JOIN users reviewer ON reviewer.id = p.reviewed_by
        ORDER BY CASE WHEN p.status = 'pending' THEN 0 ELSE 1 END,
                 p.created_at DESC
      `);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async updatePayment(req: Request, res: Response) {
    const { provider, paidFromNumber, transactionId, status, reviewNote } = req.body;
    const normalizedProvider = provider === undefined
      ? undefined
      : String(provider).toLowerCase();
    const normalizedNumber = paidFromNumber === undefined
      ? undefined
      : normalizedPaymentNumber(paidFromNumber);
    const normalizedTransactionId = transactionId === undefined
      ? undefined
      : String(transactionId).trim().toUpperCase();

    if (normalizedProvider !== undefined && !paymentProviders.includes(normalizedProvider)) {
      return res.status(400).json({ error: 'Choose bKash, Nagad, or Rocket' });
    }
    if (normalizedNumber !== undefined && !/^01[3-9]\d{8}$/.test(normalizedNumber)) {
      return res.status(400).json({ error: 'Enter a valid Bangladeshi mobile number' });
    }
    if (normalizedTransactionId !== undefined && !/^[A-Z0-9-]{5,64}$/.test(normalizedTransactionId)) {
      return res.status(400).json({ error: 'Enter a valid transaction ID' });
    }
    if (status !== undefined && !['approved', 'failed'].includes(status)) {
      return res.status(400).json({ error: 'Payment status must be approved or failed' });
    }
    if (status === 'failed' && !String(reviewNote ?? '').trim()) {
      return res.status(400).json({ error: 'Add a reason when marking payment failed' });
    }
    if (status === 'approved' && String(reviewNote ?? '').trim()) {
      return res.status(400).json({ error: 'Remove the failure reason before approving' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const existing = await client.query(
        'SELECT * FROM exam_batch_payment_requests WHERE id = $1 FOR UPDATE',
        [req.params.paymentId],
      );
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Payment request not found' });
      }
      if (existing.rows[0].status !== 'pending') {
        await client.query('ROLLBACK');
        return res.status(409).json({ error: 'Only pending payments can be edited or reviewed' });
      }

      const newStatus = status ?? 'pending';
      const updated = await client.query(`
        UPDATE exam_batch_payment_requests
        SET provider = COALESCE($1, provider),
            paid_from_number = COALESCE($2, paid_from_number),
            transaction_id = COALESCE($3, transaction_id),
            status = $4::VARCHAR,
            review_note = CASE WHEN $4::VARCHAR = 'failed' THEN $5 ELSE NULL END,
            reviewed_by = CASE WHEN $4::VARCHAR = 'pending' THEN NULL::UUID ELSE $6::UUID END,
            reviewed_at = CASE WHEN $4::VARCHAR = 'pending' THEN NULL ELSE NOW() END
        WHERE id = $7
        RETURNING *
      `, [normalizedProvider ?? null, normalizedNumber ?? null, normalizedTransactionId ?? null,
        newStatus, String(reviewNote ?? '').trim() || null,
        (req as AuthenticatedRequest).auth!.userId, req.params.paymentId]);

      if (newStatus === 'approved') {
        await client.query(`
          INSERT INTO exam_batch_enrollments (batch_id, user_id)
          VALUES ($1, $2)
          ON CONFLICT (batch_id, user_id) DO NOTHING
        `, [existing.rows[0].batch_id, existing.rows[0].user_id]);
      }

      await client.query('COMMIT');
      return res.status(200).json(updated.rows[0]);
    } catch (error: any) {
      await client.query('ROLLBACK');
      if (error.code === '23505') {
        return res.status(409).json({ error: 'This transaction ID is already recorded' });
      }
      console.error('Error updating batch payment:', error);
      return res.status(500).json({ error: 'Could not update payment request' });
    } finally {
      client.release();
    }
  }
}