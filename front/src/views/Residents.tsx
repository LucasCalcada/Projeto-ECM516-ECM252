import { useTranslation } from 'react-i18next';
import { ChevronRight } from 'lucide-react';
import useService from '../helpers/useService';
import { useEffect, useState } from 'react';

interface RowEntry {
  id: string;
  name: string;
  groupName: string;
  residencyName: string;
}

function Row(props: RowEntry) {
  const { t } = useTranslation();

  return (
    <div className="flex flex-1">
      <p className="flex-4">{props.name}</p>
      <p className="flex-1">{props.groupName}</p>
      <p className="flex-1">{props.residencyName}</p>
      <ChevronRight />
    </div>
  );
}

function TableData(props: { data: RowEntry[] }) {
  if (props.data.length) {
    return (
      <div>
        <p>No data</p>
      </div>
    );
  }

  return <div></div>;
}

function Residents() {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(true);
  const [tableData, setTableData] = useState([]);

  async function fetchData() {
    setLoading(true);
    const coreService = useService('core');
    const buildingId = localStorage.getItem('buildingId');
    const { data } = await coreService.get(`/building/${buildingId}/details`);
    setLoading(false);
    const concatData = [...data.residentData, ...data.remainingData] as RowEntry[];
    setTableData(concatData);
  }
  useEffect(() => {
    fetchData();
  }, []);

  return (
    <main className="">
      <div className="flex flex-1">
        <p className="flex-4">{t('common:name')}</p>
        <p className="flex-1">{t('common:group')}</p>
        <p className="flex-1">{t('common:residency')}</p>
        <div></div>
      </div>
      {loading ? <></> : <TableData data={tableData} />}
    </main>
  );
}

export default Residents;
