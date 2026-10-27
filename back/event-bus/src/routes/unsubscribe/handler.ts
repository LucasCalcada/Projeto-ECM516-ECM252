import { EventSubscriber, unsubscribe } from '@app/helpers/eventRegistry';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import { Request } from 'express';

export default async function handleUnsubscribeRoute(req: Request) {
  const eventName = String(req.params.eventName ?? req.body.event ?? '');
  const { url } = req.body;

  if (!eventName || typeof url !== 'string' || url.trim().length === 0) {
    throw BadRequest;
  }

  const subscription: EventSubscriber = {
    eventName,
    subscriberUrl: url.trim(),
  };

  unsubscribe(subscription);

  return {
    message: 'Event unsubscribed successfully',
  };
}
