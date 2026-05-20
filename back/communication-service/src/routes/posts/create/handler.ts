import client from '@app/db/client';
import { postRecipients, posts } from '@app/db/schema/post';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import {
  MANAGE_COMMUNICATION_POSTS_PERMISSION,
  requirePermission,
} from '@app/helpers/permissions';
import { mapPostsWithRecipients, parsePostPayload } from '@app/helpers/posts';

export default async function createPost(req: Request, ctx: Context) {
  requirePermission(ctx, MANAGE_COMMUNICATION_POSTS_PERMISSION);

  const { title, description, recipientUserIds, eventAt } = parsePostPayload(req.body);

  if (!title || !description || recipientUserIds.length === 0) {
    throw BadRequest;
  }

  if (eventAt && Number.isNaN(eventAt.getTime())) {
    throw BadRequest;
  }

  const post = await client.transaction(async (tx) => {
    const [createdPost] = await tx
      .insert(posts)
      .values({
        buildingId: ctx.auth.buildingId,
        authorUserId: ctx.auth.userId,
        title,
        description,
        eventAt,
      })
      .returning();

    await tx.insert(postRecipients).values(
      recipientUserIds.map((userId) => ({
        postId: createdPost.id,
        userId,
      })),
    );

    return createdPost;
  });

  const [response] = await mapPostsWithRecipients([post]);
  return response;
}
