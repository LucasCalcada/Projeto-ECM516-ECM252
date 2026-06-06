import _ from 'lodash';

export default function hasPermission(requiredPermissions: string[]) {
  const rawPermissions = localStorage.getItem('permissions') || '[]';
  const userPermissions = JSON.parse(rawPermissions);

  const allPermissions = [...requiredPermissions, '@core:admin'];
  const hasPermissions = _.intersection(allPermissions, userPermissions).length > 0;
  return hasPermissions;
}
