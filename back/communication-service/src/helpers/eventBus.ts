import config from '@app/config';
import log from './logger';

const PACKAGE_ARRIVED_SUBSCRIBER = `${config.serviceUrl}/internal/events/package-arrived`;
const SUBSCRIBE_RETRY_DELAY_MS = 3000;
const SUBSCRIBE_MAX_ATTEMPTS = 10;

function wait(ms: number) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

export async function subscribeToEventBus(attempt = 1): Promise<void> {
  try {
    const response = await fetch(`${config.eventBusUrl}/events/PACKAGE_ARRIVED/subscribe`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        url: PACKAGE_ARRIVED_SUBSCRIBER,
      }),
    });

    if (!response.ok) {
      throw new Error(`Event bus returned ${response.status}`);
    }

    log('SETUP', 'Subscribed communication-service to PACKAGE_ARRIVED');
  } catch (error) {
    if (attempt >= SUBSCRIBE_MAX_ATTEMPTS) {
      console.error('Falha ao se inscrever no Event Bus', error);
      return;
    }

    log(
      'SETUP',
      `Event Bus indisponivel. Tentando novamente (${attempt + 1}/${SUBSCRIBE_MAX_ATTEMPTS})`,
    );

    await wait(SUBSCRIBE_RETRY_DELAY_MS);
    await subscribeToEventBus(attempt + 1);
  }
}
