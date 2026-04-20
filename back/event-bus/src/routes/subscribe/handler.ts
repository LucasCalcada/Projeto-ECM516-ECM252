import { EventSubscriber, subscribe } from '@app/helpers/eventRegistry';
import { Request } from 'express';

export default async function handleSubscribeRoute(req: Request) {
  const { event, url } = req.body;

  const subscription: EventSubscriber = {
    eventName: event,
    subscriberUrl: url,
  };

  subscribe(subscription);

  return {
    message: 'Event registered successfully',
  };
}
