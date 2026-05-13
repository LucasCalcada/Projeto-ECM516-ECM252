import VisitorAccessForm from '../components/visitorAccess/VisitorAccessForm';
import VisitorAccessResidencyList from '../components/visitorAccess/VisitorAccessResidencyList';

interface VisitorAccessTokenPayload {
  permissions?: string | string[];
}

function decodeTokenPayload(token: string) {
  const payload = token.split('.')[1];

  if (!payload) return null;

  try {
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const json = decodeURIComponent(
      atob(base64)
        .split('')
        .map((char) => `%${char.charCodeAt(0).toString(16).padStart(2, '0')}`)
        .join(''),
    );

    return JSON.parse(json) as VisitorAccessTokenPayload;
  } catch (error) {
    console.error('Error ao decodificar token:', error);
    return null;
  }
}

function hasPermission(permission: string) {
  const token = localStorage.getItem('userToken');
  if (!token) return false;

  const decoded = decodeTokenPayload(token);
  const permissions = decoded?.permissions;

  if (Array.isArray(permissions)) {
    return permissions.includes(permission);
  }

  return permissions === permission;
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
