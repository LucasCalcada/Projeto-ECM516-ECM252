export type PackageViewMode = 'create' | 'building' | 'residency';

export interface PackageViewOption {
  mode: PackageViewMode;
  label: string;
}
