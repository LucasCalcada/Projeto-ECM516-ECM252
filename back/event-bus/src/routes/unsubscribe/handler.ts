import { EventSubscriber, unsubscribe } from '@app/helpers/eventRegistry';
import { Request } from 'express';

export default async function handleUnsubscribeRoute(req: Request) {
  const { event, url } = req.body;

  const subscription: EventSubscriber = {
    eventName: event,
    subscriberUrl: url,
  };

  unsubscribe(subscription);

  return {
    message: 'Event unsubscribed successfully',
  };
}
