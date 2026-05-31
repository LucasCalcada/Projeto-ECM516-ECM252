export interface EventSubscriber {
  eventName: string;
  subscriberUrl: string;
}

const registry = new Map<string, Set<string>>();

export function subscribe(subscriber: EventSubscriber) {
  const subscribers = registry.get(subscriber.eventName) ?? new Set<string>();
  subscribers.add(subscriber.subscriberUrl);
  registry.set(subscriber.eventName, subscribers);
}

export function unsubscribe(subscriber: EventSubscriber) {
  const subscribers = registry.get(subscriber.eventName);

  if (!subscribers) {
    return;
  }

  subscribers.delete(subscriber.subscriberUrl);

  if (subscribers.size === 0) {
    registry.delete(subscriber.eventName);
  }
}

export function getEventTargets(event: string) {
  const subscribers = registry.get(event) ?? new Set<string>();

  return [...subscribers].map((subscriberUrl) => ({
    eventName: event,
    subscriberUrl,
  }));
}
