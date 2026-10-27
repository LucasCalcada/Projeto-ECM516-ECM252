export default function hasPermission(requiredPermissions: string[]) {
  const rawPermissions = localStorage.getItem('permissions') || '[]';
  const userPermissions = JSON.parse(rawPermissions);

  const allPermissions = [...requiredPermissions, '@core:admin'];
  const hasPermissions = allPermissions.some((permission) => userPermissions.includes(permission));
  return hasPermissions;
}
