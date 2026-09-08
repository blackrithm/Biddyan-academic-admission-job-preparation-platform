import { redisClient } from '../config/redis';

export class LeaderboardService {
  private static getKey(examId: string): string {
    return `exam:leaderboard:${examId}`;
  }

  /**
   * Fast score submission to Redis Sorted Set
   * O(log N) operations
   */
  static async submitScore(examId: string, userId: string, score: number): Promise<void> {
    await redisClient.zadd(this.getKey(examId), score, userId);
  }

  /**
   * Retrieves user rank & score in O(log N)
   */
  static async getUserRankAndScore(examId: string, userId: string): Promise<{ rank: number | null, score: number | null }> {
    const key = this.getKey(examId);
    // ZREVRANK is 0-indexed ranking descending from the highest score
    const rank = await redisClient.zrevrank(key, userId);
    const score = await redisClient.zscore(key, userId);

    return {
      rank: rank !== null ? rank + 1 : null,
      score: score !== null ? parseFloat(score) : null
    };
  }

  /**
   * Retrieves high scorers with scores and dynamic ranks
   */
  static async getLeaderboard(examId: string, limit: number = 100): Promise<Array<{ userId: string, score: number, rank: number }>> {
    const key = this.getKey(examId);
    const list = await redisClient.zrevrange(key, 0, limit - 1, 'WITHSCORES');
    
    const results: Array<{ userId: string, score: number, rank: number }> = [];
    for (let i = 0; i < list.length; i += 2) {
      results.push({
        userId: list[i],
        score: parseFloat(list[i + 1]),
        rank: (i / 2) + 1
      });
    }
    return results;
  }

  /**
   * Fetches total counts of participants in a live exam
   */
  static async getParticipantCount(examId: string): Promise<number> {
    return await redisClient.zcard(this.getKey(examId));
  }
}
