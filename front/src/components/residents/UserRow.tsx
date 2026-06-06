import { LucideDot, LucidePencilLine } from 'lucide-react';
import type { User } from '../../types/Core';
import EditUser from './EditUser';
import { useState } from 'react';
import { createPortal } from 'react-dom';

export default function UserRow(props: { user: User }) {
  const [name, setName] = useState<string>(props.user.name);
  const [editing, setEditing] = useState<boolean>(false);

  const modal = editing
    ? createPortal(
        <EditUser
          userId={props.user.id}
          onClose={(name: string, permissions: string[]) => {
            setName(name);
            setEditing(false);
          }}
        />,
        document.body,
      )
    : null;

  return (
    <div className="flex items-center gap-2">
      <LucideDot size={24} />
      <p>{name}</p>
      <LucidePencilLine size={16} onClick={() => setEditing(true)} />
      {modal}
    </div>
  );
}
