import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { TopicController } from '../controllers/topicController';
import { QuestionController } from '../controllers/questionController';
import { ExamController } from '../controllers/examController';
import { optionalAuth, requireAdmin, requireAuth } from '../middleware/auth';
import { ProfileController } from '../controllers/profileController';
import { RoutineController } from '../controllers/routineController';
import { WrittenQuestionController } from '../controllers/writtenQuestionController';
import { ExamBatchController } from '../controllers/examBatchController';

const router = Router();

// --- AUTHENTICATION ROUTES ---
router.post('/auth/otp-request', AuthController.requestOtp);
router.post('/auth/otp-verify', AuthController.verifyOtp);
router.post('/auth/social-login', AuthController.socialLogin);
router.post('/auth/register', AuthController.register);
router.post('/auth/login', AuthController.login);

// --- STUDENT PROFILE ---
router.get('/profile', requireAuth, ProfileController.getProfile);
router.get('/profile/stats', requireAuth, ProfileController.getStats);
router.get('/profile/recent-activity', requireAuth, ProfileController.getRecentActivity);
router.put('/profile', requireAuth, ProfileController.updateProfile);
router.put('/profile/password', requireAuth, ProfileController.changePassword);

// --- STUDY ROUTINE ---
router.get('/routine', requireAuth, RoutineController.list);
router.post('/routine', requireAuth, RoutineController.create);
router.put('/routine/:id', requireAuth, RoutineController.update);
router.delete('/routine/:id', requireAuth, RoutineController.remove);

// --- TOPICS (CATEGORIES) ROUTES ---
router.post('/topics', requireAdmin, TopicController.createTopic);
router.get('/topics/tree', TopicController.getTopicsTree);
router.get('/topics/flat', TopicController.getTopicsFlat);
router.put('/topics/reorder', requireAdmin, TopicController.reorderTopics);
router.put('/topics/:id/move', requireAdmin, TopicController.moveTopic);
router.post('/topics/:id/copy-subtopics', requireAdmin, TopicController.copyTopicChildren);
router.put('/topics/:id', requireAdmin, TopicController.updateTopic);
router.delete('/topics/:id', requireAdmin, TopicController.deleteTopic);

// --- QUESTIONS (MCQ) ROUTES ---
router.post('/questions', requireAdmin, QuestionController.createQuestion);
router.post('/questions/bulk', requireAdmin, QuestionController.bulkCreateQuestions);
router.get('/questions', QuestionController.getQuestions);
router.get('/questions/:id', QuestionController.getQuestionById);
router.put('/questions/:id', requireAdmin, QuestionController.updateQuestion);
router.delete('/questions/:id', requireAdmin, QuestionController.deleteQuestion);

// --- WRITTEN QUESTIONS ---
router.get('/written-questions', WrittenQuestionController.list);
router.post('/written-questions', requireAdmin, WrittenQuestionController.create);
router.post('/written-question-sets', requireAdmin, WrittenQuestionController.createSet);
router.post('/written-exams/:topicId/submit', WrittenQuestionController.submit);

// --- EXAMS ENGINE ROUTES ---
router.get('/exam-batches', ExamBatchController.list);
router.get('/exam-batches/mine', requireAuth, ExamBatchController.mine);
router.get('/exam-batches/:batchId', optionalAuth, ExamBatchController.getById);
router.post('/exam-batches', requireAdmin, ExamBatchController.create);
router.put('/exam-batches/reorder', requireAdmin, ExamBatchController.reorder);
router.put('/exam-batches/:batchId', requireAdmin, ExamBatchController.update);
router.post('/exam-batches/:batchId/enroll', requireAuth, ExamBatchController.enroll);
router.post('/exams', requireAdmin, ExamController.createExam);
// Practice exams generated from a published question set are available to
// guests as well as signed-in users.
router.post('/exams/from-question-set', ExamController.createExam);
router.get('/admin/exam-results', requireAdmin, ExamController.getAdminResults);
router.put('/admin/exam-results/:attemptId', requireAdmin, ExamController.updateAdminResult);
router.get('/exams', ExamController.getExams);
router.get('/exams/mine', requireAuth, ExamController.getMyExams);
router.get('/exams/:id', optionalAuth, ExamController.getExamById);
router.post('/exams/generate-dynamic', requireAuth, ExamController.generateDynamicExam);
router.post('/exams/:examId/submit', optionalAuth, ExamController.submitExam);
router.get('/exams/:examId/leaderboard', ExamController.getExamLeaderboard);
router.get('/exams/:examId/participants', requireAuth, ExamController.getExamParticipants);

export default router;
