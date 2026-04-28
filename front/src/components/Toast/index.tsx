import { createContext, useCallback, useContext, useState } from 'react';
import type { ToastData, ToastMood } from './types';
import ToastEntry from './toastEntry';

const TOAST_DURATION = 2000;

type ToastContextType = {
  notify: (title: string, message: string, mood: ToastMood) => void;
  stack: ToastData[];
};

const ToastContext = createContext<ToastContextType | null>(null);

function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside ToastProvider');
  return ctx;
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [stack, setStack] = useState<ToastData[]>([]);

  const notify = useCallback((title: string, message: string, mood: ToastMood) => {
    const id = Date.now();

    const newToast: ToastData = { title, message, mood, id };

    setStack((prev) => [...prev, newToast]);

    setTimeout(() => {
      setStack((prev) => prev.filter((t) => t.id !== id));
    }, TOAST_DURATION);

    setTimeout(() => {
      setStack((prev) => prev.filter((t) => t.id !== id));
    }, TOAST_DURATION);
  }, []);

  return (
    <ToastContext.Provider value={{ notify, stack }}>
      {children}
      <ToastFrame />
    </ToastContext.Provider>
  );
}

function ToastFrame() {
  const { stack } = useToast();

  return (
    <div className="pointer-events-none fixed right-0 flex h-screen w-1/8 flex-col gap-2 p-4">
      {stack.map((toast) => (
        <ToastEntry key={toast.id} data={toast} />
      ))}
    </div>
  );
}
