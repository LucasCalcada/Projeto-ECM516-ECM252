import { ChevronRight, Home } from 'lucide-react';
import type { AccountUser } from '../../types/AccountUser';

interface AccountUserProps {
  user: AccountUser;
  onSelected: (user: AccountUser) => void;
}

function ResidencyData(props: { user: AccountUser }) {
  const hasResidency = props.user.groupName && props.user.residencyName;

  if (!hasResidency) {
    return;
  }

  return (
    <span>
      {props.user.groupName} - {props.user.residencyName}
    </span>
  );
}
export default function UserSelector(props: AccountUserProps) {
  return (
    <button
      onClick={() => props.onSelected(props.user)}
      className="flex w-full cursor-pointer items-center justify-between gap-8 rounded-2xl border border-neutral-800 bg-neutral-900 p-4 transition hover:border-neutral-700 hover:bg-neutral-800"
    >
      <Home size={32} />
      <div className="flex flex-col text-left text-neutral-200">
        <span className="text-xl font-bold">{props.user.buildingName}</span>
        <ResidencyData user={props.user} />
      </div>
      <ChevronRight className="text-neutral-500" size={20} />
    </button>
  );
}
