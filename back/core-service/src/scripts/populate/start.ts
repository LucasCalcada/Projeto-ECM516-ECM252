import jwt from 'jsonwebtoken';
import db from '../../db/client';
import { residencies, type Residency } from '../../db/schema/residency';
import { permission } from 'node:process';

const URL_ACCOUNT_CREATE = 'http://localhost:8001/auth/account';
const URL_LOGIN = 'http://localhost:8001/auth/login';
const URL_USER_CREATE = 'http://localhost:8000/user';

async function createAndLinkUser() {
  const credentials = {
    name: 'Tester',
    email: 'teste@teste.com',
    phone: '11999999999',
    password: '123',
  };

  try {
    const createRes = await fetch(URL_ACCOUNT_CREATE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
    });
    if (!createRes.ok) {
      throw new Error(await createRes.text());
    }

    const loginRes = await fetch(URL_LOGIN, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: credentials.email,
        password: credentials.password,
      }),
    });
    console.log('Login realizado com sucesso');
    if (!loginRes.ok) {
      throw new Error(await loginRes.text());
    }

    const loginData = await loginRes.json();
    const token = loginData.token;

    if (!token) {
      throw new Error('Token ausente');
    }

    const availableResidencies = (await db.select().from(residencies).limit(1)) as Residency[];
    console.log('Residências disponíveis:', availableResidencies.length);
    if (availableResidencies.length === 0) {
      throw new Error('Nenhuma residencia encontrada');
    }

    const residencyId = availableResidencies[0].id;
    const decodedPayload = jwt.decode(token) as any;
    const accountId = decodedPayload?.id;

    if (!accountId) {
      throw new Error('accountId ausente no token');
    }

    const userRes = await fetch(URL_USER_CREATE, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `${token}`,
      },
      body: JSON.stringify({
        name: 'Tester',
        permissions: null,
        accountId: accountId,
        residencyId: residencyId,
        buildingId: null,
      }),
    });
    if (!userRes.ok) {
      throw new Error(await userRes.text());
    }

    const userData = await userRes.json();
    console.log(userData);

    process.exit(0);
  } catch (error: any) {
    console.error(error.message);
    process.exit(1);
  }
}

createAndLinkUser();
