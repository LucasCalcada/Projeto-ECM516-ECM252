import client from "@app/db/client";
import { packages } from "@app/db/schema/package";
import e, {Request} from "express";
import fetch from "node-fetch";

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


}
