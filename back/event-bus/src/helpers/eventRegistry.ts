export interface EventSubscriber {
  eventName: string;
  subscriberUrl: string;
}
const registry: Set<EventSubscriber> = new Set();

export function subscribe(subscriber: EventSubscriber) {
  registry.add(subscriber);
}

export function unsubscribe(subscriber: EventSubscriber) {
  registry.delete(subscriber);
}

export function getEventTargets(event: string) {
  const targets: EventSubscriber[] = [];
  for (const s of registry) {
    if (s.eventName != event) {
      continue;
    }

    targets.push(s);
  }

  return targets;
}
