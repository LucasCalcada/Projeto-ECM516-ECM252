import client from '@app/db/client';
import { packages } from '@app/db/schema/package';
import e, { Request } from 'express';

export async function createPackage(req: Request) {
  const { residencyId, description } = req.body;
  const [newPackage] = await client
    .insert(packages)
    .values({
      residencyId,
      description,
      status: 'PENDING',
    })
    .returning();

  try {
    await fetch('http://localhost:8004/publish', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'PACKAGE_ARRIVED',
        data: {
          packageId: newPackage.id,
          residencyId: newPackage.residencyId,
          description: newPackage.description,
        },
      }),
    });
  } catch (error) {
    console.error('Falha ao comunicar com o Event Bus', error);
  }

  return newPackage;
}
