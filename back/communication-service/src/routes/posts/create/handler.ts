import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { MANAGE_COMMUNICATION_POSTS_PERMISSION, requirePermission } from '@app/helpers/permissions';
import { createPostForRecipients, parsePostPayload } from '@app/helpers/posts';

export default async function createPost(req: Request, ctx: Context) {
  requirePermission(ctx, [MANAGE_COMMUNICATION_POSTS_PERMISSION]);

  const { title, description, recipientUserIds, eventAt } = parsePostPayload(req.body);

  if (!title || !description || recipientUserIds.length === 0) {
    throw BadRequest;
  }

  if (eventAt && Number.isNaN(eventAt.getTime())) {
    throw BadRequest;
  }

  return createPostForRecipients({
    buildingId: ctx.auth.buildingId,
    authorUserId: ctx.auth.userId,
    title,
    description,
    recipientUserIds,
    eventAt,
  });
}
