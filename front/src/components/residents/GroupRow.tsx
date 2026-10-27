import { useEffect, useState } from 'react';
import type { Group, Residency } from '../../types/Core';
import useService from '../../helpers/useService';
import ResidencyRow from './ResidencyRow';
import OpenRowIcon from './OpenRowIcon';

export default function GroupRow(props: { group: Group }) {
  const [opened, setOpened] = useState<boolean>(false);
  const [residencies, setResidencies] = useState<Residency[]>([]);

  async function fetchResidencies() {
    const coreService = useService('core');
    const { data } = await coreService.get(`/residencies/list/${props.group.id}`);
    setResidencies(data.residencies);
  }

  function toggleOpen() {
    setOpened(!opened);
  }

  useEffect(() => {
    if (opened) {
      fetchResidencies();
    }
  }, [opened]);

  const content = opened ? residencies.map((r) => <ResidencyRow residency={r} />) : <></>;

  return (
    <div
      key={props.group.id}
      className="rounded-2xl border-1 border-neutral-800 bg-neutral-900 p-2"
    >
      <div className="flex items-center gap-2" onClick={toggleOpen}>
        <OpenRowIcon opened={opened} />
        <p className="text-xl font-bold">{props.group.name}</p>
      </div>

      <div className="flex flex-col pl-8">{content}</div>
    </div>
  );
}
