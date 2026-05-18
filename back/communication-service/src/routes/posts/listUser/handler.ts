import client from '@app/db/client';
import { postRecipients, posts } from '@app/db/schema/post';
import { mapPostsWithRecipients } from '@app/helpers/posts';
import { Context } from '@app/middlewares/routeWrapper';
import { and, desc, eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function listUserPosts(req: Request, ctx: Context) {
  const results = await client
    .select({
      id: posts.id,
      buildingId: posts.buildingId,
      authorUserId: posts.authorUserId,
      title: posts.title,
      description: posts.description,
      eventAt: posts.eventAt,
      createdAt: posts.createdAt,
      updatedAt: posts.updatedAt,
    })
    .from(posts)
    .innerJoin(postRecipients, eq(postRecipients.postId, posts.id))
    .where(and(eq(posts.buildingId, ctx.auth.buildingId), eq(postRecipients.userId, ctx.auth.userId)))
    .orderBy(desc(posts.createdAt));

  return mapPostsWithRecipients(results);
}
