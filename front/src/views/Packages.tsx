import { useState } from 'react';
import PackageCreateForm from '../components/packages/PackageCreateForm';
import PackageList from '../components/packages/PackageList';
import PackagesHeader from '../components/packages/PackagesHeader';
import type { PackageViewMode, PackageViewOption } from '../components/packages/types';
import hasPermission from '../helpers/hasPermission';

function getAvailableViews() {
  const options: PackageViewOption[] = [];

  if (hasPermission(['@delivery:create'])) {
    options.push({ mode: 'create', label: 'Registrar' });
  }

  if (hasPermission(['@delivery:view:building'])) {
    options.push({ mode: 'building', label: 'Prédio' });
  }

  if (hasPermission(['@delivery:view:residency'])) {
    options.push({ mode: 'residency', label: 'Residência' });
  }

  return options;
}

function PackagesCreate() {
  return <PackageCreateForm buildingId={localStorage.getItem('buildingId')} />;
}

function PackagesBuildingList() {
  return <PackageList scope="building" />;
}

function PackagesResidencyList() {
  return <PackageList scope="residency" />;
}

function renderPackagesView(mode: PackageViewMode) {
  if (mode === 'create') {
    return <PackagesCreate />;
  }

  if (mode === 'building') {
    return <PackagesBuildingList />;
  }

  return <PackagesResidencyList />;
}

export default function PackagesView() {
  const options = getAvailableViews();
  const [activeMode, setActiveMode] = useState<PackageViewMode>(options[0]?.mode ?? 'create');
  const currentMode = options.some((option) => option.mode === activeMode)
    ? activeMode
    : options[0]?.mode;

  if (!currentMode) {
    return (
      <div className="flex h-screen items-center justify-center">
        <h1 className="text-2xl font-bold text-neutral-100">Acesso negado</h1>
      </div>
    );
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <PackagesHeader activeMode={currentMode} options={options} onModeChange={setActiveMode} />
      {renderPackagesView(currentMode)}
    </div>
  );
}
