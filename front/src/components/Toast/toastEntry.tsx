import { BadgeCheck, BadgeAlert, BadgeInfo, BadgeX, type LucideIcon } from 'lucide-react';
import type { ToastData, ToastMood } from './types';

type ToastStyle = {
  icon: LucideIcon;
  bg: string;
  iconColor: string;
};

const styleMappings: Record<ToastMood, ToastStyle> = {
  success: {
    icon: BadgeCheck,
    bg: 'bg-green-600/40',
    iconColor: 'text-green-400',
  },
  warning: {
    icon: BadgeAlert,
    bg: 'bg-yellow-600/40',
    iconColor: 'text-yellow-400',
  },
  info: {
    icon: BadgeInfo,
    bg: 'bg-neutral-300/40',
    iconColor: 'text-neutral-400',
  },
  error: {
    icon: BadgeX,
    bg: 'bg-red-600/40',
    iconColor: 'text-red-400',
  },
};

export default function ToastEntry(props: { data: ToastData }) {
  const moodStyle = styleMappings[props.data.mood];
  const Icon = moodStyle.icon;

  const style = `
    flex
    items-center
    gap-4
    self-stretch
    rounded-xl
    px-4
    py-2
    transition-all
    duration-200
    ease-out
    ${moodStyle.bg}
  `;

  return (
    <div className={style}>
      <Icon size="32" className={moodStyle.iconColor} />
      <div>
        <p className="font-bold">{props.data.title}</p>
        <p>{props.data.message}</p>
      </div>
    </div>
  );
}
