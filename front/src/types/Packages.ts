export type DeliveryStatus = 'PENDING' | 'DELIVERED' | 'CANCELED';

export default interface Package {
  id: string;
  buildingId: string;
  residencyId: string;
  residencyName: string;
  description: string;
  status: DeliveryStatus;
  createdAt: string;
  deliveredAt: string | null;
}
