export default interface Notification {
  id: string;
  buildingId: string;
  authorUserId: string;
  title: string;
  description: string;
  // Empty means the notification targets the whole building.
  residencyIds: string[];
  eventAt: string | null;
  createdAt: string;
  updatedAt: string;
}
