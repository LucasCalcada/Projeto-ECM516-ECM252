import { useTranslation } from 'react-i18next';
import type { ResidencyGroupOption } from '../../helpers/useResidencies';

interface ResidencyPickerProps {
  groups: ResidencyGroupOption[];
  selectedIds: string[];
  onChange: (ids: string[]) => void;
  disabled?: boolean;
}

export default function ResidencyPicker({
  groups,
  selectedIds,
  onChange,
  disabled,
}: ResidencyPickerProps) {
  const { t } = useTranslation();
  const selected = new Set(selectedIds);

  function toggle(id: string) {
    const next = new Set(selected);
    if (next.has(id)) {
      next.delete(id);
    } else {
      next.add(id);
    }
    onChange([...next]);
  }

  function toggleGroup(group: ResidencyGroupOption) {
    const groupIds = group.residencies.map((residency) => residency.id);
    const allSelected = groupIds.every((id) => selected.has(id));
    const next = new Set(selected);
    groupIds.forEach((id) => (allSelected ? next.delete(id) : next.add(id)));
    onChange([...next]);
  }

  if (groups.length === 0) {
    return <p className="text-sm text-neutral-400">{t('notifications:form.noResidencies')}</p>;
  }

  return (
    <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {groups.map((group) => {
        const allSelected = group.residencies.every((residency) => selected.has(residency.id));

        return (
          <fieldset
            key={group.id}
            className="rounded-md border border-neutral-800 bg-neutral-950 p-3"
            disabled={disabled}
          >
            <legend className="sr-only">{group.name}</legend>
            <div className="mb-2 flex items-center justify-between gap-2">
              <span className="text-sm font-semibold text-neutral-100">{group.name}</span>
              <button
                type="button"
                className="text-xs font-semibold text-cyan-300 hover:text-cyan-200"
                onClick={() => toggleGroup(group)}
              >
                {allSelected
                  ? t('notifications:form.unselectGroup')
                  : t('notifications:form.selectGroup')}
              </button>
            </div>
            <div className="flex flex-col gap-1">
              {group.residencies.map((residency) => (
                <label
                  key={residency.id}
                  className="flex cursor-pointer items-center gap-2 rounded px-1 py-0.5 text-sm hover:bg-neutral-800/60"
                >
                  <input
                    type="checkbox"
                    className="accent-cyan-300"
                    checked={selected.has(residency.id)}
                    onChange={() => toggle(residency.id)}
                  />
                  {residency.name}
                </label>
              ))}
            </div>
          </fieldset>
        );
      })}
    </div>
  );
}
