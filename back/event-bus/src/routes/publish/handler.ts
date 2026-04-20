import { getEventTargets } from '@app/helpers/eventRegistry';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Request } from 'express';

export default async function handlePublishRoute(req: Request) {
  const { eventName } = req.params;

  if (!eventName) {
    throw BadRequest;
  }

  const content = req.body;
  const targets = getEventTargets(String(eventName));

  targets.forEach((t) => {
    fetch(t.subscriberUrl, { method: 'POST', body: content });
  });
}
