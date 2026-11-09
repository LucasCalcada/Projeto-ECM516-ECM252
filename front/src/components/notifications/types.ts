export type NotificationViewMode = 'inbox' | 'create' | 'manage';

export interface NotificationViewOption {
  mode: NotificationViewMode;
}

export type NotificationAudience = 'building' | 'residencies';
