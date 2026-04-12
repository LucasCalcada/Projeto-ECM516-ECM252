import BadRequest from '@app/api/error/errors/BadRequest';
import NotFoundError from '@app/api/error/errors/NotFoundError';
import client from '@app/db/client';
import { buildings } from '@app/db/schema';
import { eq } from 'drizzle-orm';
import { Request } from 'express';

export default async function getBuilding(req: Request) {
  const { id } = req.params;

  if (Array.isArray(id)) {
    throw BadRequest;
  }

  const [building] = await client.select().from(buildings).where(eq(buildings.id, id));

  if (!building) {
    throw NotFoundError;
  }

  return building;
}
