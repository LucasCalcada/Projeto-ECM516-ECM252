import { LucideDot, LucidePencilLine } from 'lucide-react';
import type { User } from '../../types/Core';

export default function UserRow(props: { user: User }) {
  return (
    <div className="flex items-center gap-2">
      <LucideDot size={24} />
      <p>{props.user.name}</p>
      <LucidePencilLine size={16} />
    </div>
  );
}
