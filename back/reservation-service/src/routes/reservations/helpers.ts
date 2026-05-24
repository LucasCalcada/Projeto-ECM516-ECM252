import axios from 'axios';
import config from '@app/config';
import { Context } from '@app/middlewares/routeWrapper';
import Unauthorized from '@app/middlewares/error/errors/Unauthorized';

export interface AccountData {
  userId: string;
  userName: string;
  buildingId: string;
  buildingName: string;
  residencyId: string;
  residencyName: string | null;
  residencyCode: string | null;
}

export async function getAccountData(ctx: Context): Promise<AccountData> {
  const coreResponse = await axios.get(`${config.coreUrl}/account`, {
    headers: {
      Authorization: ctx.auth.token,
    },
  });

  const userData = coreResponse.data?.[0] as Partial<AccountData> | undefined;

  if (
    !userData?.userId ||
    !userData.userName ||
    !userData.buildingId ||
    !userData.buildingName ||
    !userData.residencyId
  ) {
    throw Unauthorized;
  }

  return {
    userId: userData.userId,
    userName: userData.userName,
    buildingId: userData.buildingId,
    buildingName: userData.buildingName,
    residencyId: userData.residencyId,
    residencyName: userData.residencyName ?? null,
    residencyCode: userData.residencyCode ?? null,
  };
}

export function buildApartmentLabel(account: AccountData): string {
  return account.residencyCode ?? account.residencyName ?? account.residencyId;
}

export function todayAsDateString(): string {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function isValidDateString(date: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;

  const parsed = new Date(`${date}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return false;

  const year = parsed.getFullYear();
  const month = String(parsed.getMonth() + 1).padStart(2, '0');
  const day = String(parsed.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}` === date;
}
