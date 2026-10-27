import config from '@app/config';
import client from '@app/db/client';
import { users } from '@app/db/schema';
import BadRequest from '@app/api/error/errors/BadRequest';
import Unauthorized from '@app/api/error/errors/Unauthorized';
import { and, eq } from 'drizzle-orm';
import { Express, Request } from 'express';

function validateInternalSecret(req: Request) {
  const secret = req.headers['x-internal-secret'];

  if (secret !== config.internalSecret) {
    throw Unauthorized;
  }
}

export default function setupInternalResidencyRoutes(app: Express) {
  app.get('/internal/residencies/:id/users', async (req, res) => {
    validateInternalSecret(req);

    const residencyId = req.params.id;
    const buildingId = req.query.buildingId;

    if (!residencyId || typeof buildingId !== 'string') {
      throw BadRequest;
    }

    const result = await client
      .select({
        id: users.id,
        name: users.name,
      })
      .from(users)
      .where(and(eq(users.residencyId, residencyId), eq(users.buildingId, buildingId)));

    res.status(200).send(result);
  });
}
