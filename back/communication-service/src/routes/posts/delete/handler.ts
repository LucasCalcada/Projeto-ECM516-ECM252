import client from '@app/db/client';
import { posts } from '@app/db/schema/post';
import { MANAGE_COMMUNICATION_POSTS_PERMISSION, requirePermission } from '@app/helpers/permissions';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import NotFoundError from '@app/middlewares/error/errors/NotFoundError';
import { Context } from '@app/middlewares/routeWrapper';
import { and, eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function deletePost(req: Request, ctx: Context) {
  requirePermission(ctx, MANAGE_COMMUNICATION_POSTS_PERMISSION);

  const postId = req.params.id;
  if (!postId || Array.isArray(postId)) {
    throw BadRequest;
  }

  const [deletedPost] = await client
    .delete(posts)
    .where(and(eq(posts.id, postId), eq(posts.buildingId, ctx.auth.buildingId)))
    .returning();

  if (!deletedPost) {
    throw NotFoundError;
  }

  return deletedPost;
}
