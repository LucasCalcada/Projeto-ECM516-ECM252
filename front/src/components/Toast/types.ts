export type ToastMood = 'success' | 'warning' | 'info' | 'error';

export type ToastData = {
  id: number;
  title: string;
  message?: string;
  mood: ToastMood;
};
