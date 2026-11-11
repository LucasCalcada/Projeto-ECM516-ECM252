import client from '@app/db/client';
import { postResidencies, Post, posts } from '@app/db/schema/post';
import { and, eq, inArray } from 'drizzle-orm';

export interface PostResponse {
  id: string;
  buildingId: string;
  authorUserId: string;
  title: string;
  description: string;
  // Empty means the post targets the whole building.
  residencyIds: string[];
  eventAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export async function mapPostsWithResidencies(results: Post[]): Promise<PostResponse[]> {
  if (results.length === 0) {
    return [];
  }

  const postIds = results.map((post) => post.id);
  const targets = await client
    .select()
    .from(postResidencies)
    .where(inArray(postResidencies.postId, postIds));

  const residenciesByPost = new Map<string, string[]>();

  targets.forEach((target) => {
    const current = residenciesByPost.get(target.postId) ?? [];
    current.push(target.residencyId);
    residenciesByPost.set(target.postId, current);
  });

  return results.map((post) => ({
    ...post,
    residencyIds: residenciesByPost.get(post.id) ?? [],
  }));
}

interface PostPayload {
  title: string;
  description: string;
  residencyIds: string[];
  eventAt: Date | null;
}

export function parsePostPayload(body: any): PostPayload {
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const description = typeof body.description === 'string' ? body.description.trim() : '';
  const rawResidencyIds: unknown[] = Array.isArray(body.residencyIds) ? body.residencyIds : [];
  const residencyIds: string[] = [
    ...new Set(
      rawResidencyIds.filter(
        (id: unknown): id is string => typeof id === 'string' && id.length > 0,
      ),
    ),
  ];
  const eventAt = body.eventAt ? new Date(body.eventAt) : null;

  return {
    title,
    description,
    residencyIds,
    eventAt,
  };
}

interface CreatePostInput {
  buildingId: string;
  authorUserId: string;
  title: string;
  description: string;
  residencyIds: string[];
  eventAt: Date | null;
  skipDuplicate?: boolean;
}

export async function createPost(input: CreatePostInput): Promise<PostResponse> {
  const residencyIds = [...new Set(input.residencyIds)];

  if (input.skipDuplicate) {
    const [existingPost] = await client
      .select()
      .from(posts)
      .where(
        and(
          eq(posts.buildingId, input.buildingId),
          eq(posts.authorUserId, input.authorUserId),
          eq(posts.title, input.title),
          eq(posts.description, input.description),
        ),
      )
      .limit(1);

    if (existingPost) {
      const [mappedPost] = await mapPostsWithResidencies([existingPost]);
      return mappedPost;
    }
  }

  const post = await client.transaction(async (tx) => {
    const [createdPost] = await tx
      .insert(posts)
      .values({
        buildingId: input.buildingId,
        authorUserId: input.authorUserId,
        title: input.title,
        description: input.description,
        eventAt: input.eventAt,
      })
      .returning();

    if (residencyIds.length > 0) {
      await tx.insert(postResidencies).values(
        residencyIds.map((residencyId) => ({
          postId: createdPost.id,
          residencyId,
        })),
      );
    }

    return createdPost;
  });

  const [response] = await mapPostsWithResidencies([post]);
  return response;
}
