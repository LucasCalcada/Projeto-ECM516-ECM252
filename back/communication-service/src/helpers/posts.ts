import client from '@app/db/client';
import { postRecipients, Post, posts } from '@app/db/schema/post';
import { inArray } from 'drizzle-orm';

interface PostResponse {
  id: string;
  buildingId: string;
  authorUserId: string;
  title: string;
  description: string;
  recipientUserIds: string[];
  eventAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export async function mapPostsWithRecipients(results: Post[]): Promise<PostResponse[]> {
  if (results.length === 0) {
    return [];
  }

  const postIds = results.map((post) => post.id);
  const recipients = await client
    .select()
    .from(postRecipients)
    .where(inArray(postRecipients.postId, postIds));

  const recipientsByPost = new Map<string, string[]>();

  recipients.forEach((recipient) => {
    const current = recipientsByPost.get(recipient.postId) ?? [];
    current.push(recipient.userId);
    recipientsByPost.set(recipient.postId, current);
  });

  return results.map((post) => ({
    ...post,
    recipientUserIds: recipientsByPost.get(post.id) ?? [],
  }));
}

interface PostPayload {
  title: string;
  description: string;
  recipientUserIds: string[];
  eventAt: Date | null;
}

export function parsePostPayload(body: any): PostPayload {
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const description = typeof body.description === 'string' ? body.description.trim() : '';
  const rawRecipientUserIds: unknown[] = Array.isArray(body.recipientUserIds)
    ? body.recipientUserIds
    : [];
  const recipientUserIds: string[] = [
    ...new Set(
      rawRecipientUserIds.filter(
        (id: unknown): id is string => typeof id === 'string' && id.length > 0,
      ),
    ),
  ];
  const eventAt = body.eventAt ? new Date(body.eventAt) : null;

  return {
    title,
    description,
    recipientUserIds,
    eventAt,
  };
}
