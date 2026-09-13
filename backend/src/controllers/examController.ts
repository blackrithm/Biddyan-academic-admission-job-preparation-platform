import { Request, Response } from 'express';
import { pool } from '../config/db';
import { LeaderboardService } from '../services/leaderboardService';

export class ExamController {
  /**
   * DYNAMIC EXAM GENERATION API
   * Fetches random questions across hierarchical categories (Topic + Children Sub-topics)
   */
  static async generateDynamicExam(req: Request, res: Response) {
    const {
      topicId,
      questionCount = 10,
      durationMinutes,
      title = 'Instant Practice Exam',
    } = req.body;

    if (!topicId) {
      return res.status(400).json({ error: 'topicId parameter is required' });
    }

    try {
      // 1. Fetch children topics recursively (Recursive CTE)
      const topicTreeQuery = `
        WITH RECURSIVE subtopics AS (
          SELECT id FROM topics WHERE id = $1
          UNION ALL
          SELECT t.id FROM topics t
          INNER JOIN subtopics s ON t.parent_id = s.id
        )
        SELECT id FROM subtopics;
      `;
      const topicTreeResult = await pool.query(topicTreeQuery, [topicId]);
      const topicIds = topicTreeResult.rows.map(row => row.id);

      if (topicIds.length === 0) {
        return res.status(404).json({ error: 'Category topic not found' });
      }

      // 2. Fetch random questions using dynamic arrays ORDER BY RANDOM()
      const questionsQuery = `
        SELECT id, question_text, option_a, option_b, option_c, option_d, previous_years, difficulty_level
        FROM questions
        WHERE topic_id = ANY($1::uuid[])
        ORDER BY RANDOM()
        LIMIT $2;
      `;
      const questionsResult = await pool.query(questionsQuery, [topicIds, questionCount]);

      if (questionsResult.rows.length === 0) {
        return res.status(404).json({ error: 'No questions found for the selected topic tree' });
      }

      // 3. Insert temporary generated exam
      const newExamQuery = `
        INSERT INTO exams (title, topic_id, total_marks, negative_marking_per_wrong, duration_minutes, is_live)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
      `;
      const examResult = await pool.query(newExamQuery, [
        title,
        topicId,
        questionsResult.rows.length, // 1 mark per question
        0.25,                        // Default negative marking
        durationMinutes || questionsResult.rows.length, // User-selected duration, or 1 minute per question
        false
      ]);

      const exam = examResult.rows[0];

      // 4. Map questions to exam
      const junctionValues = questionsResult.rows.map((_, i) => `($1, $${i + 2})`).join(', ');
      const junctionQuery = `
        INSERT INTO exam_questions (exam_id, question_id)
        VALUES ${junctionValues};
      `;
      await pool.query(junctionQuery, [exam.id, ...questionsResult.rows.map(q => q.id)]);

      return res.status(201).json({
        exam,
        questions: questionsResult.rows
      });
    } catch (error: any) {
      console.error('Error generating dynamic exam:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * LIST ALL EXAMS
   */
  static async getExams(req: Request, res: Response) {
    try {
      const query = `
        SELECT e.*, t.name as topic_name,
               COUNT(eq.question_id)::int as question_count
        FROM exams e
        LEFT JOIN topics t ON e.topic_id = t.id
        LEFT JOIN exam_questions eq ON eq.exam_id = e.id
        GROUP BY e.id, t.name
        ORDER BY e.created_at DESC;
      `;
      const result = await pool.query(query);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      console.error('Error listing exams:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * AUTOMATIC ANSWER EVALUATION & SUBMISSION
   * Calculates scores, applies negative marks, saves DB record, updates live leaderboards.
   */
  static async submitExam(req: Request, res: Response) {
    const { examId } = req.params;
    const { userId, answers } = req.body; // answers structure: Array<{ questionId: string, selectedOption: 'A' | 'B' | 'C' | 'D' }>

    if (!userId || !answers || !Array.isArray(answers)) {
      return res.status(400).json({ error: 'userId and an array of answers are required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Fetch Exam rules
      const examQuery = 'SELECT * FROM exams WHERE id = $1;';
      const examRes = await client.query(examQuery, [examId]);
      if (examRes.rows.length === 0) {
        throw new Error('Exam target not found');
      }
      const exam = examRes.rows[0];

      // 2. Fetch correct options of questions
      const questionIds = answers.map(a => a.questionId);
      if (questionIds.length === 0) {
        throw new Error('Empty answers list provided');
      }
      const correctAnswersQuery = `
        SELECT id, correct_option, explanation FROM questions
        WHERE id = ANY($1::uuid[]);
      `;
      const correctAnswersRes = await client.query(correctAnswersQuery, [questionIds]);
      const answerKey = new Map<string, { correct_option: string, explanation: string }>();
      correctAnswersRes.rows.forEach(row => {
        answerKey.set(row.id, { correct_option: row.correct_option, explanation: row.explanation });
      });

      // 3. Compute marking evaluation
      let correctCount = 0;
      let wrongCount = 0;
      const questionWeight = Number(exam.total_marks) / Math.max(1, questionIds.length); // Dynamic dynamic split
      const negMarkFactor = Number(exam.negative_marking_per_wrong);

      const resolvedAnswers: Array<{ questionId: string, selectedOption: string, isCorrect: boolean, explanation: string }> = [];

      for (const item of answers) {
        const key = answerKey.get(item.questionId);
        if (!key) continue;

        const isCorrect = key.correct_option === item.selectedOption;
        if (isCorrect) {
          correctCount++;
        } else {
          wrongCount++;
        }

        resolvedAnswers.push({
          questionId: item.questionId,
          selectedOption: item.selectedOption,
          isCorrect,
          explanation: key.explanation || ''
        });
      }

      const totalDeduction = wrongCount * negMarkFactor * questionWeight;
      const rawScore = (correctCount * questionWeight) - totalDeduction;
      const finalScore = Math.max(0, parseFloat(rawScore.toFixed(2))); // Prevent scores from dropping below 0

      // 4. Save User Attempt Header
      const attemptQuery = `
        INSERT INTO user_exam_attempts (user_id, exam_id, score, correct_count, wrong_count)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
      `;
      const attemptRes = await client.query(attemptQuery, [userId, examId, finalScore, correctCount, wrongCount]);
      const attemptId = attemptRes.rows[0].id;

      // 5. Bulk Insert Individual Answers
      const answerInsertValues: string[] = [];
      const queryParams: any[] = [];
      resolvedAnswers.forEach((ans, idx) => {
        const offset = idx * 4;
        answerInsertValues.push(`($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4})`);
        queryParams.push(attemptId, ans.questionId, ans.selectedOption, ans.isCorrect);
      });

      const bulkAnswersQuery = `
        INSERT INTO user_answers (attempt_id, question_id, selected_option, is_correct)
        VALUES ${answerInsertValues.join(', ')};
      `;
      await client.query(bulkAnswersQuery, queryParams);

      await client.query('COMMIT');

      // 6. Real-time Redis ranking synchronization (Non-blocking background push)
      await LeaderboardService.submitScore(examId, userId, finalScore);

      // 7. Get current live statistics
      const { rank } = await LeaderboardService.getUserRankAndScore(examId, userId);
      const totalExaminees = await LeaderboardService.getParticipantCount(examId);

      return res.status(200).json({
        attemptId,
        score: finalScore,
        correctCount,
        wrongCount,
        rank,
        totalExaminees,
        breakdown: resolvedAnswers
      });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Submission transaction failed:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  /**
   * GET LIVE LEADERBOARD
   */
  static async getExamLeaderboard(req: Request, res: Response) {
    const { examId } = req.params;
    const limit = parseInt(req.query.limit as string || '100');

    try {
      const leaderboard = await LeaderboardService.getLeaderboard(examId, limit);
      const totalExaminees = await LeaderboardService.getParticipantCount(examId);

      return res.status(200).json({
        totalExaminees,
        leaderboard
      });
    } catch (error: any) {
      console.error('Error fetching leaderboard:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * CREATE OR SCHEDULE EXAM (Admin API)
   */
  static async createExam(req: Request, res: Response) {
    const { title, topicId, totalMarks, negativeMarking, duration, isLive, startsAt, endsAt, questionIds } = req.body;

    if (!title || !totalMarks || !duration) {
      return res.status(400).json({ error: 'title, totalMarks, and duration are required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const insertQuery = `
        INSERT INTO exams (title, topic_id, total_marks, negative_marking_per_wrong, duration_minutes, is_live, starts_at, ends_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *;
      `;
      const resExam = await client.query(insertQuery, [
        title,
        topicId || null,
        totalMarks,
        negativeMarking !== undefined ? negativeMarking : 0.25,
        duration,
        isLive || false,
        startsAt || null,
        endsAt || null
      ]);
      const exam = resExam.rows[0];

      if (questionIds && Array.isArray(questionIds) && questionIds.length > 0) {
        const valuesString = questionIds.map((_, i) => `($1, $${i + 2})`).join(', ');
        const junctionQuery = `
          INSERT INTO exam_questions (exam_id, question_id)
          VALUES ${valuesString};
        `;
        await client.query(junctionQuery, [exam.id, ...questionIds]);
      }

      await client.query('COMMIT');
      return res.status(201).json(exam);
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error creating exam:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  /**
   * FETCH SPECIFIC EXAM WITH QUESTIONS
   */
  static async getExamById(req: Request, res: Response) {
    const { id } = req.params;
    try {
      const examQuery = `SELECT * FROM exams WHERE id = $1;`;
      const examRes = await pool.query(examQuery, [id]);
      if (examRes.rows.length === 0) {
        return res.status(404).json({ error: 'Exam not found' });
      }

      const questionsQuery = `
         SELECT q.id, q.topic_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d,
           q.correct_option, q.explanation, q.previous_years, q.difficulty_level,
           q.exam_type, q.question_set, q.source
        FROM exam_questions eq
        JOIN questions q ON eq.question_id = q.id
        WHERE eq.exam_id = $1;
      `;
      const questionsRes = await pool.query(questionsQuery, [id]);

      return res.status(200).json({
        ...examRes.rows[0],
        questions: questionsRes.rows
      });
    } catch (error: any) {
      console.error('Error getting exam by id:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}
