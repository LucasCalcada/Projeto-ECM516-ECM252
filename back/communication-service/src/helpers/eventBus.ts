import config from '@app/config';
import log from './logger';

const PACKAGE_ARRIVED_SUBSCRIBER = `${config.serviceUrl}/internal/events/package-arrived`;
const RETRY_DELAY_MS = 3000;
const RENEW_DELAY_MS = 15000;
let started = false;

function wait(ms: number) {
  return new Promise<void>((resolve) => {
    setTimeout(resolve, ms).unref();
  });
}

// Renew the same URL so replacing the bus Pod recovers its in-memory registry.
export async function subscribeToEventBus(): Promise<void> {
  if (started) return;
  started = true;
  let subscribed = false;
  for (;;) {
    let delay = RETRY_DELAY_MS;
    try {
      const response = await fetch(`${config.eventBusUrl}/events/PACKAGE_ARRIVED/subscribe`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          url: PACKAGE_ARRIVED_SUBSCRIBER,
        }),
        signal: AbortSignal.timeout(5000),
      });
      await response.arrayBuffer();
      if (!response.ok) {
        throw new Error(`Event bus returned ${response.status}`);
      }

      if (!subscribed) log('SETUP', 'Subscribed communication-service to PACKAGE_ARRIVED');
      subscribed = true;
      delay = RENEW_DELAY_MS;
    } catch {
      log('SETUP', 'Event Bus indisponivel. Nova tentativa em 3 segundos.');
      subscribed = false;
    }
    await wait(delay);
  }
}
