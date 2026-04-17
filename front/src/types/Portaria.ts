export type VisitStatus = 'active' | 'used' | 'expired';

export interface AccessInvite {
  id: string;
  guestName: string;
  guestDocument: string;
  residentName: string;
  apartment: string;
  validUntil: string;
  reason: string;
  status: VisitStatus;
  token: string;
}

export interface AccessEntryLog {
  id: string;
  inviteId: string;
  guestName: string;
  guestDocument: string;
  residentName: string;
  apartment: string;
  enteredAt: string;
  porterName: string;
}

export type DeliveryStatus = 'waiting' | 'arrived' | 'notified' | 'delivered';

export interface DeliveryPackage {
  id: string;
  residentName: string;
  apartment: string;
  carrier: string;
  description: string;
  createdAt: string;
  status: DeliveryStatus;
}
