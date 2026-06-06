export default function hasResidency() {
  const residencyId = localStorage.getItem('residencyId');
  if (!residencyId || residencyId == 'null') {
    return false;
  }
  return true;
}
