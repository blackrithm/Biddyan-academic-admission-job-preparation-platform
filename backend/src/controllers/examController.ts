import { Request, Response } from 'express';
import { pool } from '../config/db';
import { LeaderboardService } from '../services/leaderboardService';
import { AuthenticatedRequest } from '../middleware/auth';

export class ExamController {
  static async getAdminResults(req: Request, res: Response) {
    const examId = req.query.examId as string | undefined;
    try {
      const result = await pool.query(`
        SELECT a.id, a.exam_id, a.user_id, a.score, a.correct_count,
               a.wrong_count, a.rank, a.submitted_at,
               e.title AS exam_title, u.display_name, u.phone_number
        FROM user_exam_attempts a
        JOIN exams e ON e.id = a.exam_id
        LEFT JOIN users u ON u.id = a.user_id
        ${examId ? 'WHERE a.exam_id = $1' : ''}
        ORDER BY a.submitted_at DESC
        LIMIT 200;
      `, examId ? [examId] : []);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  static async updateAdminResult(req: Request, res: Response) {
    const { attemptId } = req.params;
    const { score, correctCount, wrongCount } = req.body;
    if (score == null || correctCount == null || wrongCount == null) {
      return res.status(400).json({ error: 'score, correctCount and wrongCount are required' });
    }
    try {
      const result = await pool.query(`
        UPDATE user_exam_attempts
        SET score = $1, correct_count = $2, wrong_count = $3
        WHERE id = $4
        RETURNING *;
      `, [score, correctCount, wrongCount, attemptId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Result not found' });
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
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
      topicQuestions,
      perQuestionMark = 1,
      passMark,
      negativeMarking = 0.25,
    } = req.body;

    const selections = Array.isArray(topicQuestions) && topicQuestions.length > 0
      ? topicQuestions
      : topicId
        ? [{ topicId, questionCount }]
        : [];
    if (selections.length === 0) {
      return res.status(400).json({ error: 'At least one topic and question count are required' });
    }
    const resolvedPerQuestionMark = Number(perQuestionMark);
    if (!Number.isFinite(resolvedPerQuestionMark) || resolvedPerQuestionMark < 0.01 || resolvedPerQuestionMark > 100) {
      return res.status(400).json({ error: 'perQuestionMark must be between 0.01 and 100' });
    }

    try {
      const creatorId = (req as AuthenticatedRequest).auth?.userId ?? null;
      const selectedQuestions = new Map<string, any>();
      for (const selection of selections) {
        const selectedTopicId = String(selection.topicId || '');
        const selectedCount = Math.max(1, Math.min(200, Number(selection.questionCount) || 0));
        if (!selectedTopicId || selectedCount <= 0) continue;
        const topicTreeResult = await pool.query(`
          WITH RECURSIVE subtopics AS (
            SELECT id FROM topics WHERE id = $1::uuid
            UNION ALL
            SELECT t.id FROM topics t
            INNER JOIN subtopics s ON t.parent_id = s.id
          )
          SELECT id FROM subtopics;
        `, [selectedTopicId]);
        const topicIds = topicTreeResult.rows.map(row => row.id);
        if (topicIds.length === 0) continue;
        const questionsResult = await pool.query(`
          SELECT id, topic_id, question_text, option_a, option_b, option_c, option_d,
                 previous_years, difficulty_level
          FROM questions
          WHERE topic_id = ANY($1::uuid[])
          ORDER BY RANDOM()
          LIMIT $2;
        `, [topicIds, selectedCount]);
        for (const question of questionsResult.rows) selectedQuestions.set(question.id, question);
      }

      const questions = [...selectedQuestions.values()];
      if (questions.length === 0) {
        return res.status(404).json({ error: 'No questions found for the selected topic tree' });
      }

      const totalMarks = Number((questions.length * resolvedPerQuestionMark).toFixed(2));
      if (totalMarks > 9999.99) {
        return res.status(400).json({ error: 'Exam total marks cannot exceed 9999.99' });
      }
      const resolvedPassMark = passMark == null ? totalMarks * 0.4 : Number(passMark);
      const newExamQuery = `
        INSERT INTO exams (title, topic_id, total_marks, pass_mark, negative_marking_per_wrong, duration_minutes, is_live)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *;
      `;
      const examResult = await pool.query(newExamQuery, [
        title,
        selections[0]?.topicId || null,
        totalMarks,
        resolvedPassMark,
        Number(negativeMarking),
        Number(durationMinutes) || totalMarks,
        false,
      ]);

      if (creatorId) {
        await pool.query('UPDATE exams SET created_by = $2 WHERE id = $1', [examResult.rows[0].id, creatorId]);
      }

      const exam = examResult.rows[0];

      // 4. Map questions to exam
      const junctionValues = questions.map((_, i) => `($1, $${i + 2})`).join(', ');
      const junctionQuery = `
        INSERT INTO exam_questions (exam_id, question_id)
        VALUES ${junctionValues};
      `;
      await pool.query(junctionQuery, [exam.id, ...questions.map(q => q.id)]);

      return res.status(201).json({
        exam,
        questions,
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

  static async getMyExams(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(`
        SELECT e.*, t.name AS topic_name,
               COUNT(eq.question_id)::int AS question_count
        FROM exams e
        LEFT JOIN topics t ON e.topic_id = t.id
        LEFT JOIN exam_questions eq ON eq.exam_id = e.id
        WHERE e.created_by = $1
        GROUP BY e.id, t.name
        ORDER BY e.created_at DESC;
      `, [userId]);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * AUTOMATIC ANSWER EVALUATION & SUBMISSION
   * Calculates scores, applies negative marks, saves DB record, updates live leaderboards.
   */
  static async submitExam(req: Request, res: Response) {
    const { examId: requestedExamId } = req.params;
    const { userId, answers } = req.body; // answers structure: Array<{ questionId: string, selectedOption: 'A' | 'B' | 'C' | 'D' }>

    if (!userId || !answers || !Array.isArray(answers)) {
      return res.status(400).json({ error: 'userId and an array of answers are required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let examId = requestedExamId;
      if (requestedExamId === 'mock-exam-id') {
        const fallback = await client.query(
          'SELECT id FROM exams ORDER BY created_at DESC LIMIT 1;'
        );
        if (fallback.rows.length === 0) {
          throw new Error('Exam target not found');
        }
        examId = fallback.rows[0].id;
      }

      // 1. Fetch Exam rules
      const examQuery = 'SELECT * FROM exams WHERE id = $1;';
      const examRes = await client.query(examQuery, [examId]);
      if (examRes.rows.length === 0) {
        throw new Error('Exam target not found');
      }
      const exam = examRes.rows[0];

      const batchAccess = await client.query(`
        SELECT EXISTS (
          SELECT 1 FROM exam_batch_exams be
          JOIN exam_batch_enrollments en ON en.batch_id = be.batch_id
          WHERE be.exam_id = $1 AND en.user_id = $2
            AND NOW() >= be.starts_at AND NOW() < be.ends_at
        ) AS has_access,
        EXISTS (
          SELECT 1 FROM exam_batch_exams be WHERE be.exam_id = $1
        ) AS is_batch_exam
      `, [examId, (req as AuthenticatedRequest).auth?.userId ?? null]);
      const batchStatus = batchAccess.rows[0];
      if (batchStatus.is_batch_exam && !batchStatus.has_access) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'Batch exam শুধু enrolled শিক্ষার্থীরা নির্ধারিত সময়ে দিতে পারবেন' });
      }
      const effectiveUserId = (req as AuthenticatedRequest).auth?.userId ?? userId;

      // 2. Fetch correct options of questions
      const questionIds = answers.map(a => a.questionId);
      if (questionIds.length === 0) {
        throw new Error('Empty answers list provided');
      }
      const correctAnswersQuery = `
        SELECT q.id, q.correct_option, q.explanation
        FROM questions q
        JOIN exam_questions eq ON eq.question_id = q.id
        WHERE eq.exam_id = $1 AND q.id = ANY($2::uuid[]);
      `;
      const correctAnswersRes = await client.query(correctAnswersQuery, [examId, questionIds]);
      const examQuestionCountRes = await client.query(
        'SELECT COUNT(*)::int AS question_count FROM exam_questions WHERE exam_id = $1;',
        [examId],
      );
      const examQuestionCount = Number(examQuestionCountRes.rows[0]?.question_count ?? 0);
      if (examQuestionCount === 0) throw new Error('Exam has no questions');
      const answerKey = new Map<string, { correct_option: string, explanation: string }>();
      correctAnswersRes.rows.forEach(row => {
        answerKey.set(row.id, { correct_option: row.correct_option, explanation: row.explanation });
      });

      // 3. Compute marking evaluation
      let correctCount = 0;
      let wrongCount = 0;
      const questionWeight = Number(exam.total_marks) / examQuestionCount;
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
      const attemptRes = await client.query(attemptQuery, [effectiveUserId, examId, finalScore, correctCount, wrongCount]);
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
      await LeaderboardService.submitScore(examId, effectiveUserId, finalScore);

      // 7. Get current live statistics
      const { rank } = await LeaderboardService.getUserRankAndScore(examId, effectiveUserId);
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

  static async getExamParticipants(req: Request, res: Response) {
    try {
      const userId = (req as AuthenticatedRequest).auth!.userId;
      const result = await pool.query(`
        SELECT a.id AS attempt_id, a.user_id, COALESCE(u.display_name, 'শিক্ষার্থী') AS display_name,
               a.score, a.correct_count, a.wrong_count, a.submitted_at,
               RANK() OVER (ORDER BY a.score DESC, a.submitted_at ASC)::int AS rank
        FROM user_exam_attempts a
        LEFT JOIN users u ON u.id = a.user_id
        JOIN exams e ON e.id = a.exam_id
        WHERE a.exam_id = $1 AND e.created_by = $2
        ORDER BY rank ASC, a.submitted_at ASC`,
        [req.params.examId, userId],
      );
      return res.status(200).json(result.rows);
    } catch (error: any) {
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

    const scheduledStart = startsAt || (isLive ? new Date().toISOString() : null);
    const scheduledEnd = endsAt || (
      isLive && scheduledStart
        ? new Date(new Date(scheduledStart).getTime() + Number(duration) * 60000).toISOString()
        : null
    );

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
        scheduledStart,
        scheduledEnd
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
      let examId = id;
      if (id === 'mock-exam-id') {
        const fallback = await pool.query(
          'SELECT id FROM exams ORDER BY created_at DESC LIMIT 1;'
        );
        if (fallback.rows.length === 0) {
          return res.status(404).json({ error: 'Exam not found' });
        }
        examId = fallback.rows[0].id;
      }

      const examQuery = `SELECT * FROM exams WHERE id = $1;`;
      const examRes = await pool.query(examQuery, [examId]);
      if (examRes.rows.length === 0) {
        return res.status(404).json({ error: 'Exam not found' });
      }

      const batchAccess = await pool.query(`
        SELECT EXISTS (
          SELECT 1 FROM exam_batch_exams be
          JOIN exam_batch_enrollments en ON en.batch_id = be.batch_id
          WHERE be.exam_id = $1 AND en.user_id = $2
            AND NOW() >= be.starts_at AND NOW() < be.ends_at
        ) AS has_access,
        EXISTS (
          SELECT 1 FROM exam_batch_exams be WHERE be.exam_id = $1
        ) AS is_batch_exam
      `, [examId, (req as AuthenticatedRequest).auth?.userId ?? null]);
      const batchStatus = batchAccess.rows[0];
      if (batchStatus.is_batch_exam && !batchStatus.has_access) {
        return res.status(403).json({ error: 'Batch exam শুধু enrolled শিক্ষার্থীরা নির্ধারিত সময়ে খুলতে পারবেন' });
      }

      const questionsQuery = `
         SELECT q.id, q.topic_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d,
           CASE WHEN $2::boolean THEN NULL ELSE q.correct_option END AS correct_option,
           q.explanation, q.previous_years, q.difficulty_level,
           q.exam_type, q.question_set, q.source
        FROM exam_questions eq
        JOIN questions q ON eq.question_id = q.id
        WHERE eq.exam_id = $1;
      `;
      const questionsRes = await pool.query(questionsQuery, [examId, batchStatus.is_batch_exam]);

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
