import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import VisitorAccessForm from '../components/visitorAccess/VisitorAccessForm';
import VisitorAccessHeader, {
  type VisitorAccessViewMode,
  type VisitorAccessViewOption,
} from '../components/visitorAccess/VisitorAccessHeader';
import VisitorAccessResidencyList from '../components/visitorAccess/VisitorAccessResidencyList';

const CREATE_VISITOR_ACCESS_PERMISSION = '@Visitor:Create';
const VIEW_VISITOR_ACCESS_PERMISSION = '@Visitor:View';

function hasPermission(permission: string) {
  const permissions = JSON.parse(localStorage.getItem('permissions') || '[]');
  return permissions.includes(permission);
}

function getAvailableViews(t: (key: string) => string) {
  const options: VisitorAccessViewOption[] = [];

  if (hasPermission(CREATE_VISITOR_ACCESS_PERMISSION)) {
    options.push({ mode: 'create', label: t('visitorAccess:views.create.label') });
  }

  if (hasPermission(VIEW_VISITOR_ACCESS_PERMISSION)) {
    options.push({ mode: 'view', label: t('visitorAccess:views.view.label') });
  }

  return options;
}

function VisitorAccessCreate() {
  return <VisitorAccessForm />;
}

function VisitorAccessViewList() {
  return <VisitorAccessResidencyList />;
}

function renderVisitorAccessView(mode: VisitorAccessViewMode) {
  if (mode === 'create') {
    return <VisitorAccessCreate />;
  }

  return <VisitorAccessViewList />;
}

export default function VisitorAccessView() {
  const { t } = useTranslation();
  const options = getAvailableViews(t);
  const [activeMode, setActiveMode] = useState<VisitorAccessViewMode>(options[0]?.mode ?? 'create');
  const currentMode = options.some((option) => option.mode === activeMode)
    ? activeMode
    : options[0]?.mode;

  if (currentMode) {
    return (
      <div className="h-full overflow-auto p-4 md:p-8">
        <VisitorAccessHeader
          activeMode={currentMode}
          options={options}
          onModeChange={setActiveMode}
        />
        {renderVisitorAccessView(currentMode)}
      </div>
    );
  }

  return (
    <div className="flex h-screen items-center justify-center">
      <h1 className="text-2xl font-bold text-neutral-100">{t('common:accessDenied')}</h1>
    </div>
  );
}
