import { Request, Response } from 'express';
import { pool } from '../config/db';

export class QuestionController {
  /**
   * Create a new MCQ Question
   */
  static async createQuestion(req: Request, res: Response) {
    const {
      topic_id,
      question_text,
      option_a,
      option_b,
      option_c,
      option_d,
      correct_option,
      explanation,
      previous_years,
      difficulty_level
    } = req.body;

    if (!topic_id || !question_text || !option_a || !option_b || !option_c || !option_d || !correct_option) {
      return res.status(400).json({ error: 'Missing mandatory question fields' });
    }

    try {
      const query = `
        INSERT INTO questions (
          topic_id, question_text, option_a, option_b, option_c, option_d, 
          correct_option, explanation, previous_years, difficulty_level
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *;
      `;
      const result = await pool.query(query, [
        topic_id,
        question_text,
        option_a,
        option_b,
        option_c,
        option_d,
        correct_option.toUpperCase(),
        explanation || '',
        previous_years || [],
        difficulty_level || 'medium'
      ]);

      return res.status(201).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error in createQuestion:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * List and filter questions
   */
  static async getQuestions(req: Request, res: Response) {
    const { topicId, search, previousYear, difficulty } = req.query;

    try {
      let query = `
        SELECT q.*, t.name as topic_name
        FROM questions q
        JOIN topics t ON q.topic_id = t.id
        WHERE 1=1
      `;
      const params: any[] = [];

      if (topicId) {
        params.push(topicId);
        query += ` AND q.topic_id = $${params.length}`;
      }

      if (search) {
        params.push(`%${search}%`);
        query += ` AND q.question_text ILIKE $${params.length}`;
      }

      if (previousYear) {
        params.push(previousYear);
        query += ` AND $${params.length} = ANY(q.previous_years)`;
      }

      if (difficulty) {
        params.push(difficulty);
        query += ` AND q.difficulty_level = $${params.length}`;
      }

      query += ` ORDER BY q.created_at DESC;`;

      const result = await pool.query(query, params);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      console.error('Error in getQuestions:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Get specific question
   */
  static async getQuestionById(req: Request, res: Response) {
    const { id } = req.params;

    try {
      const query = `
        SELECT q.*, t.name as topic_name
        FROM questions q
        JOIN topics t ON q.topic_id = t.id
        WHERE q.id = $1;
      `;
      const result = await pool.query(query, [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Question not found' });
      }
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error in getQuestionById:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Edit an existing question
   */
  static async updateQuestion(req: Request, res: Response) {
    const { id } = req.params;
    const {
      topic_id,
      question_text,
      option_a,
      option_b,
      option_c,
      option_d,
      correct_option,
      explanation,
      previous_years,
      difficulty_level
    } = req.body;

    try {
      const query = `
        UPDATE questions
        SET 
          topic_id = COALESCE($1, topic_id),
          question_text = COALESCE($2, question_text),
          option_a = COALESCE($3, option_a),
          option_b = COALESCE($4, option_b),
          option_c = COALESCE($5, option_c),
          option_d = COALESCE($6, option_d),
          correct_option = COALESCE($7, correct_option),
          explanation = COALESCE($8, explanation),
          previous_years = COALESCE($9, previous_years),
          difficulty_level = COALESCE($10, difficulty_level)
        WHERE id = $11
        RETURNING *;
      `;
      const result = await pool.query(query, [
        topic_id || null,
        question_text || null,
        option_a || null,
        option_b || null,
        option_c || null,
        option_d || null,
        correct_option ? correct_option.toUpperCase() : null,
        explanation !== undefined ? explanation : null,
        previous_years || null,
        difficulty_level || null,
        id
      ]);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Question not found' });
      }

      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error in updateQuestion:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Delete a question
   */
  static async deleteQuestion(req: Request, res: Response) {
    const { id } = req.params;

    try {
      const query = `DELETE FROM questions WHERE id = $1 RETURNING *;`;
      const result = await pool.query(query, [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Question not found' });
      }
      return res.status(200).json({ message: 'Question deleted successfully', question: result.rows[0] });
    } catch (error: any) {
      console.error('Error in deleteQuestion:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}
