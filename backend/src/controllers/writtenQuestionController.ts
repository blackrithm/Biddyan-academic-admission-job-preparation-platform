import { Request, Response } from 'express';
import { pool } from '../config/db';

export class WrittenQuestionController {
  static async createSet(req: Request, res: Response) {
    const {
      topic_id,
      format = 'written',
      title = '',
      stimulus = '',
      questions,
      exam_type,
      question_set,
      previous_years = [],
      difficulty_level = 'medium',
      source = 'admin',
    } = req.body;
    if (!topic_id || !['cq', 'written'].includes(format)) {
      return res.status(400).json({ error: 'topic_id and a valid format (cq or written) are required' });
    }
    if (format === 'cq' && !String(stimulus).trim()) {
      return res.status(400).json({ error: 'A CQ set requires a stimulus' });
    }
    if (!Array.isArray(questions) || questions.length === 0 || questions.length > 500) {
      return res.status(400).json({ error: 'Provide between 1 and 500 questions' });
    }
    if (!Array.isArray(previous_years)) {
      return res.status(400).json({ error: 'previous_years must be an array' });
    }
    for (const question of questions) {
      const marks = Number(question?.marks ?? 10);
      if (!String(question?.question_text ?? '').trim() ||
          !Number.isFinite(marks) || marks <= 0 || marks > 1000) {
        return res.status(400).json({ error: 'Each question needs text and marks between 0 and 1000' });
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const topic = await client.query(
        'SELECT question_type FROM topics WHERE id = $1 FOR UPDATE;',
        [topic_id],
      );
      if (topic.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Topic not found' });
      }
      if (topic.rows[0].question_type !== 'written') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Choose a Written topic before adding written questions' });
      }

      const setResult = await client.query(`
        INSERT INTO written_question_sets (
          topic_id, format, title, stimulus, exam_type, question_set,
          previous_years, difficulty_level, source
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        RETURNING *;
      `, [
        topic_id,
        format,
        String(title).trim(),
        String(stimulus),
        exam_type || null,
        question_set || null,
        previous_years.map((year: unknown) => String(year)),
        difficulty_level,
        source,
      ]);
      const set = setResult.rows[0];
      const insertedQuestions = [];
      for (const [index, question] of questions.entries()) {
        const result = await client.query(`
          INSERT INTO written_questions (
            topic_id, set_id, item_order, question_text, model_answer, marks,
            previous_years, difficulty_level, exam_type, question_set, source
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
          RETURNING *;
        `, [
          topic_id,
          set.id,
          index + 1,
          String(question.question_text).trim(),
          String(question.model_answer ?? ''),
          Number(question.marks ?? 10),
          previous_years.map((year: unknown) => String(year)),
          difficulty_level,
          exam_type || null,
          question_set || null,
          source,
        ]);
        insertedQuestions.push(result.rows[0]);
      }
      await client.query('COMMIT');
      return res.status(201).json({ ...set, questions: insertedQuestions });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error creating written question set:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async create(req: Request, res: Response) {
    const {
      topic_id,
      question_text,
      model_answer = '',
      marks = 10,
      previous_years = [],
      difficulty_level = 'medium',
      exam_type,
      question_set,
      source = 'admin',
    } = req.body;
    const markValue = Number(marks);
    if (!topic_id || !question_text?.trim()) {
      return res.status(400).json({ error: 'topic_id and question_text are required' });
    }
    if (!Number.isFinite(markValue) || markValue <= 0 || markValue > 1000) {
      return res.status(400).json({ error: 'marks must be between 0 and 1000' });
    }
    if (!Array.isArray(previous_years)) {
      return res.status(400).json({ error: 'previous_years must be an array' });
    }

    try {
      const topic = await pool.query(
        'SELECT question_type FROM topics WHERE id = $1;',
        [topic_id],
      );
      if (topic.rows.length === 0) return res.status(404).json({ error: 'Topic not found' });
      if (topic.rows[0].question_type !== 'written') {
        return res.status(400).json({ error: 'Choose a Written topic before adding a written question' });
      }
      const result = await pool.query(`
        INSERT INTO written_questions (
          topic_id, question_text, model_answer, marks, previous_years,
          difficulty_level, exam_type, question_set, source
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *;
      `, [
        topic_id,
        question_text.trim(),
        String(model_answer),
        markValue,
        previous_years.map((year: unknown) => String(year)),
        difficulty_level,
        exam_type || null,
        question_set || null,
        source,
      ]);
      return res.status(201).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error creating written question:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  static async list(req: Request, res: Response) {
    const topicId = req.query.topicId as string | undefined;
    const setId = req.query.setId as string | undefined;
    const includeChildren = req.query.includeChildren === 'true';
    try {
      const result = setId
        ? await pool.query(`
            SELECT question.*, topic.name AS topic_name,
                   COALESCE(question_set.format, 'written') AS format,
                   question_set.id AS set_id,
                   question_set.title AS set_title,
                   question_set.stimulus
            FROM written_questions question
            JOIN topics topic ON topic.id = question.topic_id
            LEFT JOIN written_question_sets question_set ON question_set.id = question.set_id
            WHERE question.set_id = $1
            ORDER BY question.item_order, question.id;
          `, [setId])
        : topicId
        ? await pool.query(`
            WITH RECURSIVE topic_tree AS (
              SELECT id FROM topics WHERE id = $1
              UNION ALL
              SELECT child.id
              FROM topics child
              INNER JOIN topic_tree parent ON child.parent_id = parent.id
              WHERE $2::boolean = TRUE
            )
                 SELECT question.*, topic.name AS topic_name,
                   COALESCE(question_set.format, 'written') AS format,
                   question_set.id AS set_id,
                   question_set.title AS set_title,
                   question_set.stimulus
            FROM written_questions question
            JOIN topics topic ON topic.id = question.topic_id
                 LEFT JOIN written_question_sets question_set ON question_set.id = question.set_id
            WHERE question.topic_id IN (SELECT id FROM topic_tree)
                 ORDER BY COALESCE(question_set.created_at, question.created_at),
                question_set.id NULLS LAST, question.item_order, question.id;
          `, [topicId, includeChildren])
        : await pool.query(`
                 SELECT question.*, topic.name AS topic_name,
                   COALESCE(question_set.format, 'written') AS format,
                   question_set.id AS set_id,
                   question_set.title AS set_title,
                   question_set.stimulus
            FROM written_questions question
            JOIN topics topic ON topic.id = question.topic_id
                 LEFT JOIN written_question_sets question_set ON question_set.id = question.set_id
                 ORDER BY COALESCE(question_set.created_at, question.created_at),
                question_set.id NULLS LAST, question.item_order, question.id;
          `);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async submit(req: Request, res: Response) {
    const { topicId } = req.params;
    const { userId, answers } = req.body;
    if (!userId || !Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ error: 'userId and a non-empty answers array are required' });
    }
    if (answers.some((answer: any) =>
      typeof answer.questionId !== 'string' ||
      typeof answer.response !== 'string' ||
      answer.response.length > 20000,
    )) {
      return res.status(400).json({ error: 'Each answer requires questionId and a response under 20000 characters' });
    }
    const questionIds = answers.map((answer: any) => answer.questionId);
    if (new Set(questionIds).size !== questionIds.length) {
      return res.status(400).json({ error: 'Duplicate question answers are not allowed' });
    }

    try {
      const result = await pool.query(`
        WITH RECURSIVE topic_tree AS (
          SELECT id FROM topics WHERE id = $1
          UNION ALL
          SELECT child.id
          FROM topics child
          INNER JOIN topic_tree parent ON child.parent_id = parent.id
        )
        SELECT COUNT(*)::int AS valid_count
        FROM written_questions
        WHERE id = ANY($2::uuid[])
          AND topic_id IN (SELECT id FROM topic_tree);
      `, [topicId, questionIds]);
      if (Number(result.rows[0].valid_count) !== questionIds.length) {
        return res.status(400).json({ error: 'Answers must belong to Written questions in this topic' });
      }

      const submission = await pool.query(`
        INSERT INTO written_exam_submissions (user_id, topic_id, answers)
        VALUES ($1, $2, $3::jsonb)
        RETURNING id, review_status, submitted_at;
      `, [userId, topicId, JSON.stringify(answers)]);
      return res.status(201).json(submission.rows[0]);
    } catch (error: any) {
      console.error('Error submitting written exam:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}