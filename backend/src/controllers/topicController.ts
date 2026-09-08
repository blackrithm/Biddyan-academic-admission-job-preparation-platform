import { Request, Response } from 'express';
import { pool } from '../config/db';

export class TopicController {
  /**
   * Create category or hierarchical subtopic
   */
  static async createTopic(req: Request, res: Response) {
    const { name, parent_id } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Topic name is required' });
    }

    try {
      const query = `
        INSERT INTO topics (name, parent_id)
        VALUES ($1, $2)
        RETURNING *;
      `;
      const result = await pool.query(query, [name, parent_id || null]);
      return res.status(201).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error in createTopic:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * List all topics and reconstruct hierarchy tree on the fly
   */
  static async getTopicsTree(req: Request, res: Response) {
    try {
      const query = `SELECT * FROM topics ORDER BY name ASC;`;
      const result = await pool.query(query);
      const rows = result.rows;

      // Map-based tree construction
      const topicMap = new Map<string, any>();
      rows.forEach(topic => {
        topicMap.set(topic.id, { ...topic, children: [] });
      });

      const rootTopics: any[] = [];
      topicMap.forEach(topic => {
        if (topic.parent_id) {
          const parent = topicMap.get(topic.parent_id);
          if (parent) {
            parent.children.push(topic);
          } else {
            rootTopics.push(topic);
          }
        } else {
          rootTopics.push(topic);
        }
      });

      return res.status(200).json(rootTopics);
    } catch (error: any) {
      console.error('Error in getTopicsTree:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * List flat list of topics
   */
  static async getTopicsFlat(req: Request, res: Response) {
    try {
      const query = `SELECT * FROM topics ORDER BY name ASC;`;
      const result = await pool.query(query);
      return res.status(200).json(result.rows);
    } catch (error: any) {
      console.error('Error in getTopicsFlat:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Edit a topic
   */
  static async updateTopic(req: Request, res: Response) {
    const { id } = req.params;
    const { name, parent_id } = req.body;

    try {
      const query = `
        UPDATE topics
        SET name = $1, parent_id = $2
        WHERE id = $3
        RETURNING *;
      `;
      const result = await pool.query(query, [name, parent_id || null, id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Topic not found' });
      }
      return res.status(200).json(result.rows[0]);
    } catch (error: any) {
      console.error('Error in updateTopic:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Delete a topic (cascades on children recursively)
   */
  static async deleteTopic(req: Request, res: Response) {
    const { id } = req.params;

    try {
      const query = `DELETE FROM topics WHERE id = $1 RETURNING *;`;
      const result = await pool.query(query, [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Topic not found' });
      }
      return res.status(200).json({ message: 'Topic deleted successfully', topic: result.rows[0] });
    } catch (error: any) {
      console.error('Error in deleteTopic:', error);
      return res.status(500).json({ error: error.message });
    }
  }
}
