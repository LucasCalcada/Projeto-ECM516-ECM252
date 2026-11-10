import config from '@app/config';
import { createPost } from '@app/helpers/posts';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Express, Request } from 'express';

function validateInternalSecret(req: Request) {
  const secret = req.headers['x-internal-secret'];

  if (secret !== config.internalSecret) {
    throw Unauthorized;
  }
}

function readPackageArrivedPayload(body: any) {
  if (body?.eventName !== 'PACKAGE_ARRIVED') {
    throw BadRequest;
  }

  const data = body.data ?? {};

  if (
    typeof data.packageId !== 'string' ||
    typeof data.buildingId !== 'string' ||
    typeof data.residencyId !== 'string' ||
    typeof data.description !== 'string' ||
    typeof data.authorUserId !== 'string'
  ) {
    throw BadRequest;
  }

  return {
    packageId: data.packageId,
    buildingId: data.buildingId,
    residencyId: data.residencyId,
    description: data.description,
    authorUserId: data.authorUserId,
  };
}

export default function setupInternalEventRoutes(app: Express) {
  app.post('/internal/events/package-arrived', async (req, res) => {
    validateInternalSecret(req);

    const event = readPackageArrivedPayload(req.body);

    const post = await createPost({
      buildingId: event.buildingId,
      authorUserId: event.authorUserId,
      title: 'Nova encomenda recebida',
      description: [
        `A portaria recebeu uma encomenda para sua residencia: ${event.description}.`,
        `Codigo da encomenda: ${event.packageId}`,
      ].join('\n'),
      residencyIds: [event.residencyId],
      eventAt: null,
      skipDuplicate: true,
    });

    res.status(200).send(post);
  });
}
