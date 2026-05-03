// back/delivery-service/src/routes/packages/update/handler.ts
import deliveryDb from '../../../db/client';
import { packages } from '../../../db/schema/package';
import { Context } from '@app/middlewares/routeWrapper';
import { Request } from 'express';
import { eq } from 'drizzle-orm';

export default async function updatePackageStatus(req: Request, ctx: Context) {
  const { packageId, status } = req.body;
  if (!packageId || !status) {
    throw new Error('O ID da encomenda e o novo status são obrigatórios.'); 
  }

  const validStatuses = ['PENDING', 'DELIVERED', 'RETURNED'];
  if (!validStatuses.includes(status)) {
    throw new Error(`Status inválido. Use um dos seguintes: ${validStatuses.join(', ')}`);
  }

  const updateData: Partial<typeof packages.$inferInsert> = { 
    status: status 
  };

  if (status === 'DELIVERED') {
    updateData.deliveredAt = new Date();
  }

  const result = await deliveryDb
    .update(packages)
    .set(updateData)
    .where(eq(packages.id, packageId))
    .returning(); 

  if (result.length === 0) {
    throw new Error('Encomenda não encontrada.');
  }
  return result[0];
}