import axios from 'axios';
import deliveryDb from '../../../db/client';
import  { packages } from '../../../db/schema/package'; 
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';

export default async function getPackages(req: Request, ctx: Context) {
  const coreResponse = await axios.get('http://localhost:8000/api/account', {
    headers: {
      Authorization: req.headers.authorization
    }
  });

  const userData = coreResponse.data[0];
  const email = userData?.email;

  if (!email) {
    return []; 
  }

  const result = await deliveryDb
    .select()
    .from(packages)
    .where(eq(packages.residencyId, residencyId));

  return result;
}