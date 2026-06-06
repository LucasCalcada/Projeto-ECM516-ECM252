import config from '@app/config';
import { getEventTargets } from '@app/helpers/eventRegistry';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { randomUUID } from 'crypto';
import { Request } from 'express';

export default async function handlePublishRoute(req: Request) {
  const { eventName } = req.params;

  if (!eventName) {
    throw BadRequest;
  }

  const payload = {
    eventId: typeof req.body?.eventId === 'string' ? req.body.eventId : randomUUID(),
    eventName: String(eventName),
    occurredAt:
      typeof req.body?.occurredAt === 'string' ? req.body.occurredAt : new Date().toISOString(),
    data: req.body?.data ?? {},
  };
  const targets = getEventTargets(String(eventName));

  const deliveries = await Promise.allSettled(
    targets.map(async (t) => {
      const response = await fetch(t.subscriberUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Internal-Secret': config.internalSecret,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`Subscriber ${t.subscriberUrl} returned ${response.status}`);
      }
    }),
  );

  return {
    eventName: payload.eventName,
    subscriberCount: targets.length,
    deliveredCount: deliveries.filter((d) => d.status === 'fulfilled').length,
    failedCount: deliveries.filter((d) => d.status === 'rejected').length,
  };
}
