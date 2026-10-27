import config from '@app/config';
import { createPostForRecipients } from '@app/helpers/posts';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';
import { Express, Request } from 'express';

interface ResidencyUser {
  id: string;
  name: string | null;
}

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

async function getResidencyUserIds(buildingId: string, residencyId: string) {
  const url = new URL(`${config.coreUrl}/internal/residencies/${residencyId}/users`);
  url.searchParams.set('buildingId', buildingId);

  const response = await fetch(url, {
    headers: {
      'X-Internal-Secret': config.internalSecret,
    },
  });

  if (!response.ok) {
    throw new Error(`Core-service returned ${response.status} while fetching residency users`);
  }

  const users = (await response.json()) as ResidencyUser[];
  return users.map((user) => user.id);
}

export default function setupInternalEventRoutes(app: Express) {
  app.post('/internal/events/package-arrived', async (req, res) => {
    validateInternalSecret(req);

    const event = readPackageArrivedPayload(req.body);
    const recipientUserIds = await getResidencyUserIds(event.buildingId, event.residencyId);

    if (recipientUserIds.length === 0) {
      res.status(200).send({ message: 'No recipients found for package event' });
      return;
    }

    const post = await createPostForRecipients({
      buildingId: event.buildingId,
      authorUserId: event.authorUserId,
      title: 'Nova encomenda recebida',
      description: [
        `A portaria recebeu uma encomenda para sua residencia: ${event.description}.`,
        `Codigo da encomenda: ${event.packageId}`,
      ].join('\n'),
      recipientUserIds,
      eventAt: null,
      skipDuplicate: true,
    });

    res.status(200).send(post);
  });
}
