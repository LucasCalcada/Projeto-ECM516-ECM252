import client from '@app/db/client';
import { postResidencies, posts } from '@app/db/schema/post';
import { mapPostsWithResidencies } from '@app/helpers/posts';
import { Context } from '@app/middlewares/routeWrapper';
import { and, desc, eq, exists, notExists, or } from 'drizzle-orm';
import { Request } from 'express';

// Building-wide posts plus the posts addressed to the user's residency.
export default async function listUserPosts(req: Request, ctx: Context) {
  const { buildingId, residencyId } = ctx.auth;

  const targetsPost = client
    .select({ id: postResidencies.id })
    .from(postResidencies)
    .where(eq(postResidencies.postId, posts.id));

  const buildingWide = notExists(targetsPost);
  const audience = residencyId
    ? or(
        buildingWide,
        exists(
          client
            .select({ id: postResidencies.id })
            .from(postResidencies)
            .where(
              and(
                eq(postResidencies.postId, posts.id),
                eq(postResidencies.residencyId, residencyId),
              ),
            ),
        ),
      )
    : buildingWide;

  const results = await client
    .select()
    .from(posts)
    .where(and(eq(posts.buildingId, buildingId), audience))
    .orderBy(desc(posts.createdAt));

  return mapPostsWithResidencies(results);
}
