import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { buildings, groups, residencies, users } from '@app/db/schema';
import aggregateDetails from '@app/helpers/building/aggregateDetails';
import { Context } from '@app/middlewares/routeWrapper';
import { and, eq, inArray, isNull } from 'drizzle-orm';
import { Request } from 'express';

export default async function getBuildingDetails(req: Request, ctx: Context) {
  const { id } = req.params;

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const [building] = await client.select().from(buildings).where(eq(buildings.id, id));

  if (!building) {
    throw NotFoundError;
  }

  const buildingGroups = await client.select().from(groups).where(eq(groups.building, building.id));
  const groupIds = buildingGroups.map((g) => g.id);

  const populatedResidencies = await client
    .select({
      groupId: groups.id,
      groupName: groups.name,
      residencyId: residencies.id,
      residencyName: residencies.name,
      residencyCode: residencies.code,
      userId: users.id,
      userName: users.name,
    })
    .from(residencies)
    .leftJoin(users, eq(users.residencyId, residencies.id))
    .innerJoin(groups, eq(groups.id, residencies.groupId))
    .where(inArray(residencies.groupId, groupIds));

  const residentData = aggregateDetails(populatedResidencies);

  const remainingUsers = await client
    .select({ id: users.id, name: users.name })
    .from(users)
    .where(and(eq(users.buildingId, building.id), isNull(users.residencyId)));

  return { residentData, remainingUsers };
}
