import { useEffect, useState } from 'react';
import type { Residency, User } from '../../types/Core';
import useService from '../../helpers/useService';
import UserRow from './UserRow';
import OpenRowIcon from './OpenRowIcon';

export default function ResidendyRow(props: { residency: Residency }) {
  const [opened, setOpened] = useState<boolean>(false);
  const [users, setUsers] = useState<User[]>([]);

  async function fetchResidencies() {
    const coreService = useService('core');
    const { data } = await coreService.get(`/residencies/${props.residency.id}/users`);
    setUsers(data.users);
  }

  function toggleOpen() {
    setOpened(!opened);
  }

  useEffect(() => {
    if (opened) {
      fetchResidencies();
    }
  }, [opened]);

  const content = opened ? users.map((u) => <UserRow user={u} />) : <></>;

  return (
    <div>
      <div className="flex items-center gap-2" onClick={toggleOpen}>
        <OpenRowIcon opened={opened} />
        <p className="font-bold"> {props.residency.name} </p>
      </div>

      <div className="flex flex-col pl-8">{content}</div>
    </div>
  );
}
