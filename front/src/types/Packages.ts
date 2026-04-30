export type DeliveryStatus = 'waiting' | 'arrived' | 'notified' | 'delivered';
export default interface Package {
  id: string;
  residencyId: string;
  description: string;
  status: DeliveryStatus;
  createdAt: string;
  updatedAt: string;
  deliveryAt: string | null;
}
