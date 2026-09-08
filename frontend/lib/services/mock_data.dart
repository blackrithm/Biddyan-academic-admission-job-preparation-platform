import '../models/models.dart';

class MockData {
  static final List<TopicNode> topicTree = [
    TopicNode(id: 'academic', name: 'Academic', children: [
      TopicNode(id: 't3', name: 'SSC'),
      TopicNode(id: 't4', name: 'HSC'),
    ]),
    TopicNode(id: 'admission', name: 'Admission', children: [
      TopicNode(id: 't8', name: 'Varsity'),
      TopicNode(id: 'ta', name: 'Engineering'),
      TopicNode(id: 'tb', name: 'Medical'),
      TopicNode(id: 't7', name: 'Agriculture'),
    ]),
    TopicNode(id: 'job', name: 'Job', children: [
      TopicNode(id: 't5', name: 'BCS'),
      TopicNode(id: 't6', name: 'Bank'),
    ]),
  ];

  static final List<Question> questions = [
    Question(id: 'q1', topicId: 't3', questionText: 'বাংলা ভাষার সর্বোচ্চ রাজধানী শহর কোথায় অবস্থিত?', optionA: 'ঢাকা', optionB: 'চট্টগ্রাম', optionC: 'কোটা', optionD: 'রাজশাহী', correctOption: 'A', explanation: 'বাংলাদেশের রাজধানী ঢাকা।', previousYears: ['43rd BCS', '44th BCS'], difficultyLevel: 'easy'),
    Question(id: 'q2', topicId: 't8', questionText: 'The capital city of Bangladesh is', optionA: 'Chittagong', optionB: 'Dhaka', optionC: 'Rajshahi', optionD: 'Khulna', correctOption: 'B', explanation: 'Dhaka is the capital.', previousYears: ['43rd BCS', 'Primary 2022'], difficultyLevel: 'easy'),
    Question(id: 'q3', topicId: 'ta', questionText: 'যদি x + 3 = 7, তাহলে x কত?', optionA: '4', optionB: '3', optionC: '10', optionD: '7', correctOption: 'A', explanation: 'x = 7 - 3 = 4', previousYears: ['Bank Job 2023'], difficultyLevel: 'medium'),
    Question(id: 'q4', topicId: 'tb', questionText: 'If x² - 5x + 6 = 0, what is the value of x?', optionA: 'x = 2, 3', optionB: 'x = 1, 6', optionC: 'x = -2, -3', optionD: 'x = 5, 6', correctOption: 'A', explanation: '(x-2)(x-3) = 0', previousYears: ['45th BCS'], difficultyLevel: 'hard'),
    Question(id: 'q5', topicId: 't7', questionText: 'She _____ to the store when she saw him.', optionA: 'went', optionB: 'goes', optionC: 'was going', optionD: 'had gone', correctOption: 'C', explanation: 'Past continuous.', previousYears: ['Primary 2022'], difficultyLevel: 'medium'),
    Question(id: 'q6', topicId: 't3', questionText: 'বাংলা ভাষার শাসনবিন্যাস বলতে কি বলে?', optionA: 'ব্যাকরণ', optionB: 'তাল', optionC: 'ছন্দ', optionD: 'বিষয়', correctOption: 'A', explanation: 'ভাষার গঠন ও ব্যাকরণ।', previousYears: ['43rd BCS'], difficultyLevel: 'medium'),
    Question(id: 'q7', topicId: 't8', questionText: 'What is the synonym of "ABANDON"?', optionA: 'Leave behind', optionB: 'Stay', optionC: 'Continue', optionD: 'Remember', correctOption: 'A', explanation: 'Leave permanently.', previousYears: ['Bank Job 2023'], difficultyLevel: 'hard'),
        Question(id: 'q8', topicId: 'ta', questionText: 'What is 25% of 200?', optionA: '50', optionB: '25', optionC: '100', optionD: '75', correctOption: 'A', explanation: '200 × 0.25 = 50.', previousYears: ['44th BCS'], difficultyLevel: 'easy'),
  ];

  static final List<Exam> exams = [
    Exam(id: 'e1', title: 'BCS Preli 2024 (Full Mock)', topicId: 't6', totalMarks: 8.0, negativeMarking: 0.25, durationMinutes: 10, isLive: true, questions: questions),
    Exam(id: 'e2', title: 'Bank Job Mock Test', topicId: 't6', totalMarks: 4.0, negativeMarking: 0.25, durationMinutes: 5, isLive: false, questions: [questions[1], questions[3], questions[5], questions[7]]),
  ];

  static final Exam mockExam = Exam(id: 'mock-exam-id', title: '৪৩তম বিসিএস প্রি-লিমি (মক টেস্ট)', topicId: 't6', totalMarks: 8, negativeMarking: 0.25, durationMinutes: 10, isLive: true, questions: questions);

  static final List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(userId: 'user1', score: 8.0, rank: 1),
    LeaderboardEntry(userId: 'user2', score: 7.5, rank: 2),
    LeaderboardEntry(userId: 'user3', score: 6.75, rank: 3),
    LeaderboardEntry(userId: 'user4', score: 5.5, rank: 4),
    LeaderboardEntry(userId: 'user5', score: 4.25, rank: 5),
  ];
}