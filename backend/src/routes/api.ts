import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { TopicController } from '../controllers/topicController';
import { QuestionController } from '../controllers/questionController';
import { ExamController } from '../controllers/examController';
import { requireAdmin } from '../middleware/auth';

const router = Router();

// --- AUTHENTICATION ROUTES ---
router.post('/auth/otp-request', AuthController.requestOtp);
router.post('/auth/otp-verify', AuthController.verifyOtp);
router.post('/auth/social-login', AuthController.socialLogin);
router.post('/auth/register', AuthController.register);
router.post('/auth/login', AuthController.login);

// --- TOPICS (CATEGORIES) ROUTES ---
router.post('/topics', requireAdmin, TopicController.createTopic);
router.get('/topics/tree', TopicController.getTopicsTree);
router.get('/topics/flat', TopicController.getTopicsFlat);
router.put('/topics/:id', requireAdmin, TopicController.updateTopic);
router.delete('/topics/:id', requireAdmin, TopicController.deleteTopic);

// --- QUESTIONS (MCQ) ROUTES ---
router.post('/questions', requireAdmin, QuestionController.createQuestion);
router.post('/questions/bulk', requireAdmin, QuestionController.bulkCreateQuestions);
router.get('/questions', QuestionController.getQuestions);
router.get('/questions/:id', QuestionController.getQuestionById);
router.put('/questions/:id', requireAdmin, QuestionController.updateQuestion);
router.delete('/questions/:id', requireAdmin, QuestionController.deleteQuestion);

// --- EXAMS ENGINE ROUTES ---
router.post('/exams', requireAdmin, ExamController.createExam);
router.get('/exams', ExamController.getExams);
router.get('/exams/:id', ExamController.getExamById);
router.post('/exams/generate-dynamic', ExamController.generateDynamicExam);
router.post('/exams/:examId/submit', ExamController.submitExam);
router.get('/exams/:examId/leaderboard', ExamController.getExamLeaderboard);

export default router;
