import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../config/db';
import { AuthenticatedRequest } from '../middleware/auth';

export class ProfileController {
  static async getRecentActivity(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `SELECT * FROM (
           SELECT 'exam' AS activity_type,
                  a.id::text AS activity_id,
                  e.id::text AS related_id,
                  e.title,
                  a.submitted_at AS activity_at,
                  a.correct_count,
                  a.wrong_count,
                  e.total_marks,
                  e.is_live,
                  NULL::int AS question_count
           FROM user_exam_attempts a
           JOIN exams e ON e.id = a.exam_id
           WHERE a.user_id = $1

           UNION ALL

           SELECT 'topic' AS activity_type,
                  CONCAT('topic-', t.id)::text AS activity_id,
                  t.id::text AS related_id,
                  t.name AS title,
                  MAX(a.submitted_at) AS activity_at,
                  NULL::int AS correct_count,
                  NULL::int AS wrong_count,
                  NULL::numeric AS total_marks,
                  NULL::boolean AS is_live,
                  COUNT(DISTINCT ua.question_id)::int AS question_count
           FROM user_exam_attempts a
           JOIN user_answers ua ON ua.attempt_id = a.id
           JOIN questions q ON q.id = ua.question_id
           JOIN topics t ON t.id = q.topic_id
           WHERE a.user_id = $1
           GROUP BY t.id, t.name
         ) activity
         ORDER BY activity_at DESC
         LIMIT 6`,
        [userId],
      );
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async getStats(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
          `WITH attempt_stats AS (
            SELECT a.id, a.user_id, a.exam_id, a.score, a.correct_count,
                a.wrong_count, a.submitted_at, e.is_live, e.total_marks,
                e.duration_minutes,
                COUNT(eq.question_id)::int AS question_count,
                  COUNT(DISTINCT ua.question_id)::int AS answered_count
            FROM user_exam_attempts a
            JOIN exams e ON e.id = a.exam_id
            LEFT JOIN exam_questions eq ON eq.exam_id = a.exam_id
            LEFT JOIN user_answers ua ON ua.attempt_id = a.id
            WHERE a.user_id = $1
            GROUP BY a.id, e.is_live, e.total_marks, e.duration_minutes
          ), scores AS (
           SELECT user_id, SUM(score) AS total_score
           FROM user_exam_attempts
           GROUP BY user_id
         ), ranked AS (
           SELECT user_id, RANK() OVER (ORDER BY total_score DESC) AS overall_rank
           FROM scores
         )
         SELECT
           (SELECT COUNT(*)::int FROM attempt_stats) AS total_exams,
           (SELECT COUNT(DISTINCT ua.question_id)::int
              FROM user_answers ua
              JOIN user_exam_attempts a ON a.id = ua.attempt_id
             WHERE a.user_id = $1) AS total_questions_read,
           (SELECT COUNT(*)::int FROM attempt_stats WHERE NOT is_live) AS total_practice_exams,
           (SELECT COUNT(*)::int FROM attempt_stats WHERE is_live) AS total_live_exams,
           (SELECT COUNT(*)::int FROM attempt_stats
             WHERE score >= total_marks * 0.4) AS total_passed_exams,
           (SELECT COUNT(*)::int FROM attempt_stats
             WHERE score < total_marks * 0.4) AS failed_or_incomplete_exams,
           (SELECT COALESCE(SUM(correct_count), 0)::int FROM attempt_stats) AS total_right_answers,
           (SELECT COALESCE(SUM(wrong_count), 0)::int FROM attempt_stats) AS total_wrong_answers,
           (SELECT COALESCE(SUM(GREATEST(question_count - answered_count, 0)), 0)::int FROM attempt_stats) AS total_skipped_answers,
           (SELECT COALESCE(SUM(duration_minutes), 0)::int FROM attempt_stats) AS total_study_minutes,
           (SELECT COALESCE(SUM(answered_count), 0)::int FROM attempt_stats) AS total_contribution,
           (SELECT overall_rank::int FROM ranked WHERE user_id = $1) AS overall_rank`,
        [userId],
      );
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `SELECT id, phone_number, email, display_name, role,
                profile_image_url, preparation_categories,
                notifications_enabled, preferred_language
         FROM users WHERE id = $1`,
        [userId],
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async updateProfile(req: Request, res: Response) {
    const {
      displayName,
      profileImageUrl,
      preparationCategories,
      notificationsEnabled,
      preferredLanguage,
    } = req.body;
    if (profileImageUrl != null && String(profileImageUrl).length > 8_000_000) {
      return res.status(413).json({ error: 'Profile picture must be 6 MB or smaller' });
    }
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(
        `UPDATE users SET
           display_name = COALESCE($2, display_name),
           profile_image_url = COALESCE($3, profile_image_url),
           preparation_categories = COALESCE($4, preparation_categories),
           notifications_enabled = COALESCE($5, notifications_enabled),
           preferred_language = COALESCE($6, preferred_language)
         WHERE id = $1
         RETURNING id, phone_number, email, display_name, role,
                   profile_image_url, preparation_categories,
                   notifications_enabled, preferred_language`,
        [
          userId,
          displayName?.toString().trim() || null,
          profileImageUrl ?? null,
          Array.isArray(preparationCategories) ? preparationCategories : null,
          typeof notificationsEnabled === 'boolean' ? notificationsEnabled : null,
          preferredLanguage?.toString() || null,
        ],
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async changePassword(req: Request, res: Response) {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword || String(newPassword).length < 4) {
      return res.status(400).json({ error: 'Current password and a 4+ character new password are required' });
    }
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
      const hash = result.rows[0]?.password_hash;
      if (!hash || !(await bcrypt.compare(currentPassword, hash))) {
        return res.status(401).json({ error: 'বর্তমান password সঠিক নয়' });
      }
      const nextHash = await bcrypt.hash(newPassword, 12);
      await pool.query('UPDATE users SET password_hash = $2 WHERE id = $1', [userId, nextHash]);
      return res.status(200).json({ message: 'Password updated successfully' });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}