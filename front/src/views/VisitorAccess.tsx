import VisitorAccessForm from '../components/visitorAccess/VisitorAccessForm';
import VisitorAccessResidencyList from '../components/visitorAccess/VisitorAccessResidencyList';



function hasPermission(permission: string) {
  const permissions = JSON.parse(localStorage.getItem('permissions') || '[]');
  return permissions.includes(permission);
}

function VisitorAccessCreate() {
  return <VisitorAccessForm />;
}

function VisitorAccessViewList() {
  return <VisitorAccessResidencyList />;
}

export default function VisitorAccessView() {
  if (hasPermission('@Visitor:Create')) {
    return <VisitorAccessCreate />;
  }

  if (hasPermission('@Visitor:View')) {
    return <VisitorAccessViewList />;
  }

  return (
    <div className="flex h-screen items-center justify-center">
      <h1 className="text-2xl font-bold text-neutral-100">Acesso negado</h1>
    </div>
  );
}
