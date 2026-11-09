import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { MANAGE_COMMUNICATION_POSTS_PERMISSION, requirePermission } from '@app/helpers/permissions';
import { createPost as createPostForResidencies, parsePostPayload } from '@app/helpers/posts';

// Without residencyIds the post is delivered to the whole building.
export default async function createPost(req: Request, ctx: Context) {
  requirePermission(ctx, [MANAGE_COMMUNICATION_POSTS_PERMISSION]);

  const { title, description, residencyIds, eventAt } = parsePostPayload(req.body);

  if (!title || !description) {
    throw BadRequest;
  }

  if (eventAt && Number.isNaN(eventAt.getTime())) {
    throw BadRequest;
  }

  return createPostForResidencies({
    buildingId: ctx.auth.buildingId,
    authorUserId: ctx.auth.userId,
    title,
    description,
    residencyIds,
    eventAt,
  });
}
