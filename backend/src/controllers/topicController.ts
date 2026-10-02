import { Request, Response } from 'express';
import { pool } from '../config/db';

export class TopicController {
  /**
   * Create category or hierarchical subtopic
   */
  static async createTopic(req: Request, res: Response) {
    const { name, parent_id } = req.body;
    const questionType = req.body.question_type ?? 'mcq';

    if (!name) {
      return res.status(400).json({ error: 'Topic name is required' });
    }
    if (!['mcq', 'written'].includes(questionType)) {
      return res.status(400).json({ error: 'question_type must be mcq or written' });
    }

    try {
      const query = `
        INSERT INTO topics (name, parent_id, sort_order, question_type)
        VALUES (
          $1,
          $2,
          COALESCE((
            SELECT MAX(sort_order) + 1
            FROM topics
            WHERE parent_id IS NOT DISTINCT FROM $2::uuid
          ), 0),
          $3
        )
        RETURNING *;
      `;
      const result = await pool.query(query, [name, parent_id || null, questionType]);
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
      const query = `SELECT * FROM topics ORDER BY sort_order ASC, name ASC;`;
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
      const query = `SELECT * FROM topics ORDER BY sort_order ASC, name ASC;`;
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

  static async reorderTopics(req: Request, res: Response) {
    const { parentId = null, topicIds } = req.body;
    if (
      !Array.isArray(topicIds) ||
      topicIds.length === 0 ||
      topicIds.some((id: unknown) => typeof id !== 'string') ||
      new Set(topicIds).size !== topicIds.length
    ) {
      return res.status(400).json({ error: 'A non-empty, unique topicIds array is required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const siblings = await client.query(
        `SELECT id FROM topics
         WHERE parent_id IS NOT DISTINCT FROM $1::uuid
         ORDER BY sort_order ASC, name ASC
         FOR UPDATE;`,
        [parentId],
      );
      const siblingIds = siblings.rows.map(row => row.id);
      if (
        siblingIds.length !== topicIds.length ||
        siblingIds.some((id: string) => !topicIds.includes(id))
      ) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'topicIds must contain every sibling topic exactly once' });
      }

      for (const [sortOrder, topicId] of topicIds.entries()) {
        await client.query(
          `UPDATE topics SET sort_order = $1
           WHERE id = $2 AND parent_id IS NOT DISTINCT FROM $3::uuid;`,
          [sortOrder, topicId, parentId],
        );
      }
      await client.query('COMMIT');
      return res.status(200).json({ message: 'Topics reordered successfully' });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error reordering topics:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async moveTopic(req: Request, res: Response) {
    const { id } = req.params;
    const { parentId = null } = req.body;
    if (parentId !== null && typeof parentId !== 'string') {
      return res.status(400).json({ error: 'parentId must be a topic id or null' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const topicResult = await client.query(
        'SELECT id, parent_id FROM topics WHERE id = $1 FOR UPDATE;',
        [id],
      );
      if (topicResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Topic not found' });
      }

      if (parentId !== null) {
        const cycleCheck = await client.query(`
          WITH RECURSIVE subtree AS (
            SELECT id FROM topics WHERE id = $1
            UNION ALL
            SELECT child.id FROM topics child
            INNER JOIN subtree parent ON child.parent_id = parent.id
          )
          SELECT EXISTS (SELECT 1 FROM subtree WHERE id = $2) AS would_cycle;
        `, [id, parentId]);
        if (cycleCheck.rows[0].would_cycle) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'A topic cannot be moved into its own subtree' });
        }
        const targetExists = await client.query('SELECT 1 FROM topics WHERE id = $1;', [parentId]);
        if (targetExists.rows.length === 0) {
          await client.query('ROLLBACK');
          return res.status(404).json({ error: 'Target topic not found' });
        }
      }

      const orderResult = await client.query(`
        SELECT COALESCE(MAX(sort_order) + 1, 0) AS next_order
        FROM topics WHERE parent_id IS NOT DISTINCT FROM $1::uuid;
      `, [parentId]);
      await client.query(
        'UPDATE topics SET parent_id = $1, sort_order = $2 WHERE id = $3;',
        [parentId, orderResult.rows[0].next_order, id],
      );
      await client.query('COMMIT');
      return res.status(200).json({ message: 'Topic moved successfully' });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error moving topic:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  static async copyTopicChildren(req: Request, res: Response) {
    const sourceParentId = req.params.id;
    const { targetParentId = null, childIds, copyQuestions = false } = req.body;
    if (
      !Array.isArray(childIds) ||
      childIds.length === 0 ||
      childIds.some((id: unknown) => typeof id !== 'string') ||
      new Set(childIds).size !== childIds.length ||
      (targetParentId !== null && typeof targetParentId !== 'string') ||
      typeof copyQuestions !== 'boolean'
    ) {
      return res.status(400).json({ error: 'Valid childIds, targetParentId, and copyQuestions are required' });
    }
    if (targetParentId === sourceParentId) {
      return res.status(400).json({ error: 'Choose a different destination topic' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const sourceResult = await client.query(
        'SELECT id FROM topics WHERE id = $1 FOR UPDATE;',
        [sourceParentId],
      );
      if (sourceResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Source topic not found' });
      }
      if (targetParentId !== null) {
        const targetResult = await client.query(
          'SELECT id FROM topics WHERE id = $1 FOR UPDATE;',
          [targetParentId],
        );
        if (targetResult.rows.length === 0) {
          await client.query('ROLLBACK');
          return res.status(404).json({ error: 'Target topic not found' });
        }
      }

      const sourceChildrenResult = await client.query(
        'SELECT id FROM topics WHERE parent_id = $1 ORDER BY sort_order, name;',
        [sourceParentId],
      );
      const sourceChildIds = sourceChildrenResult.rows.map(row => row.id);
      if (childIds.some((childId: string) => !sourceChildIds.includes(childId))) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Only direct subtopics of the source can be copied' });
      }

      const allTopicsResult = await client.query(
        'SELECT id, name, parent_id, sort_order FROM topics ORDER BY sort_order, name;',
      );
      const childrenByParent = new Map<string, any[]>();
      const nextOrderByParent = new Map<string, number>();
      for (const topic of allTopicsResult.rows) {
        const parentKey = topic.parent_id ?? 'root';
        const siblings = childrenByParent.get(parentKey) ?? [];
        siblings.push(topic);
        childrenByParent.set(parentKey, siblings);
        nextOrderByParent.set(parentKey, Math.max(nextOrderByParent.get(parentKey) ?? 0, Number(topic.sort_order) + 1));
      }

      let copiedTopics = 0;
      let copiedQuestions = 0;
      const cloneSubtree = async (sourceId: string, newParentId: string | null): Promise<void> => {
        const sourceTopic = allTopicsResult.rows.find(topic => topic.id === sourceId);
        if (!sourceTopic) throw new Error('A selected subtopic no longer exists');
        const parentKey = newParentId ?? 'root';
        const sortOrder = nextOrderByParent.get(parentKey) ?? 0;
        nextOrderByParent.set(parentKey, sortOrder + 1);
        const inserted = await client.query(
          'INSERT INTO topics (name, parent_id, sort_order, question_type) VALUES ($1, $2, $3, $4) RETURNING id;',
          [sourceTopic.name, newParentId, sortOrder, sourceTopic.question_type ?? 'mcq'],
        );
        const clonedId = inserted.rows[0].id as string;
        copiedTopics++;

        if (copyQuestions) {
          const copied = await client.query(`
            INSERT INTO questions (
              topic_id, question_text, option_a, option_b, option_c, option_d,
              correct_option, explanation, previous_years, difficulty_level,
              exam_type, question_set, source
            )
            SELECT $1, question_text, option_a, option_b, option_c, option_d,
                   correct_option, explanation, previous_years, difficulty_level,
                   exam_type, question_set, source
            FROM questions WHERE topic_id = $2;
          `, [clonedId, sourceId]);
          copiedQuestions += copied.rowCount ?? 0;
        }

        for (const child of childrenByParent.get(sourceId) ?? []) {
          await cloneSubtree(child.id, clonedId);
        }
      };

      for (const childId of childIds) {
        await cloneSubtree(childId, targetParentId);
      }
      await client.query('COMMIT');
      return res.status(201).json({ copiedTopics, copiedQuestions });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error copying subtopics:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }

  /**
   * Delete a topic (cascades on children recursively)
   */
  static async deleteTopic(req: Request, res: Response) {
    const { id } = req.params;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await client.query(
        `WITH RECURSIVE topic_tree AS (
           SELECT id FROM topics WHERE id = $1
           UNION ALL
           SELECT child.id
           FROM topics child
           INNER JOIN topic_tree parent ON child.parent_id = parent.id
         )
         DELETE FROM questions
         WHERE topic_id IN (SELECT id FROM topic_tree)
         RETURNING id;`,
        [id],
      );

      const topicResult = await client.query(
        `DELETE FROM topics WHERE id = $1 RETURNING *;`,
        [id],
      );
      await client.query('COMMIT');
      if (topicResult.rows.length === 0) {
        return res.status(404).json({ error: 'Topic not found' });
      }
      return res.status(200).json({
        message: 'Topic deleted successfully',
        topic: topicResult.rows[0],
        deletedQuestions: result.rows.length,
      });
    } catch (error: any) {
      await client.query('ROLLBACK');
      console.error('Error in deleteTopic:', error);
      return res.status(500).json({ error: error.message });
    } finally {
      client.release();
    }
  }
}
