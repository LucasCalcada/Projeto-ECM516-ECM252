import client from '@app/db/client';
import { posts } from '@app/db/schema/post';
import { MANAGE_COMMUNICATION_POSTS_PERMISSION, requirePermission } from '@app/helpers/permissions';
import { mapPostsWithRecipients } from '@app/helpers/posts';
import { Context } from '@app/middlewares/routeWrapper';
import { desc, eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function listAdminPosts(req: Request, ctx: Context) {
  requirePermission(ctx, MANAGE_COMMUNICATION_POSTS_PERMISSION);

  const results = await client
    .select()
    .from(posts)
    .where(eq(posts.buildingId, ctx.auth.buildingId))
    .orderBy(desc(posts.createdAt));

  return mapPostsWithRecipients(results);
}
