import { useTranslation } from 'react-i18next';
import useService from '../helpers/useService';
import { useEffect, useState } from 'react';
import GroupRow from '../components/residents/GroupRow';
import type { Group } from '../types/Core';
import { LucideUsers } from 'lucide-react';

function Residents() {
  const { t } = useTranslation();
  const [loading, setLoading] = useState<boolean>(true);
  const [groups, setGroups] = useState<Group[]>([]);

  async function fetchGroups() {
    setLoading(true);
    const coreService = useService('core');
    const { data } = await coreService.get(`/groups`);
    setLoading(false);
    setGroups(data.groups);
  }

  useEffect(() => {
    fetchGroups();
  }, []);

  const content = loading ? <></> : groups.map((g) => <GroupRow group={g} />);

  const buildingName = localStorage.getItem('buildingName');

  return (
    <main className="h-full w-full p-4">
      <div className="mb-4 flex items-center gap-4 text-2xl font-bold">
        <LucideUsers size={24} />
        <h1>{t('shell:residents.title', { buildingName })}</h1>
      </div>
      <div className="flex flex-col gap-2">{content}</div>
    </main>
  );
}

export default Residents;
