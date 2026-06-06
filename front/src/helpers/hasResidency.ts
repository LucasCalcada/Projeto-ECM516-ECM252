export default function hasResidency() {
  const residencyId = localStorage.getItem('residencyId');
  return Boolean(residencyId);
}
