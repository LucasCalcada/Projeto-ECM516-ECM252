import { useEffect, useState } from 'react';
import { X, Plus, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import useService from '../../helpers/useService';

type UserEditorProps = {
  userId: string;
  onClose: (name: string, permissions: string[]) => void;
};

export default function UserEditor({ userId, onClose }: UserEditorProps) {
  const { t } = useTranslation('shell.residents');

  const api = useService('core');

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [name, setName] = useState('');
  const [permission, setPermission] = useState('');
  const [permissions, setPermissions] = useState<string[]>([]);

  useEffect(() => {
    const loadUser = async () => {
      try {
        setLoading(true);

        const response = await api.get(`/user/${userId}`);

        setName(response.data.user.name);
        setPermissions(response.data.user.permissions ?? []);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };

    loadUser();
  }, [api, userId]);

  const addPermission = () => {
    const value = permission.trim();

    if (!value || permissions.includes(value)) {
      return;
    }

    setPermissions((current) => [...current, value]);
    setPermission('');
  };

  const removePermission = (permissionToRemove: string) => {
    setPermissions((current) => current.filter((permission) => permission !== permissionToRemove));
  };

  const handleSave = async () => {
    try {
      setSaving(true);

      await api.put(`/user/${userId}`, {
        name,
        permissions,
      });

      onClose(name, permissions);
    } catch (error) {
      console.error(error);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/80">
        <div className="rounded-xl border border-neutral-800 bg-neutral-900 p-6 text-neutral-100">
          {t('shell:residents.userEditor.loading')}
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/80">
      <div className="relative w-full max-w-lg rounded-xl border border-neutral-800 bg-neutral-900 p-6 shadow-2xl">
        <button
          onClick={() => onClose(name, permissions)}
          className="absolute top-4 right-4 rounded-md p-1 text-neutral-400 transition hover:bg-neutral-800 hover:text-neutral-100"
        >
          <X size={18} />
        </button>

        <h2 className="mb-6 text-xl font-semibold text-neutral-100">
          {t('shell:residents.userEditor.title')}
        </h2>

        <div className="space-y-5">
          <div>
            <label className="mb-2 block text-sm font-medium text-neutral-300">
              {t('shell:residents.userEditor.name')}
            </label>

            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full rounded-lg border border-neutral-700 bg-neutral-800 px-3 py-2 text-neutral-100 outline-none focus:border-neutral-500"
              placeholder={t('shell:residents.userEditor.namePlaceholder')}
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-neutral-300">
              {t('shell:residents.userEditor.permissions')}
            </label>

            <div className="flex gap-2">
              <input
                value={permission}
                onChange={(e) => setPermission(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    addPermission();
                  }
                }}
                className="flex-1 rounded-lg border border-neutral-700 bg-neutral-800 px-3 py-2 text-neutral-100 outline-none focus:border-neutral-500"
                placeholder={t('shell:residents.userEditor.permissionPlaceholder')}
              />

              <button
                type="button"
                onClick={addPermission}
                className="flex items-center gap-2 rounded-lg bg-neutral-700 px-4 py-2 text-neutral-100 transition hover:bg-neutral-600"
              >
                <Plus size={16} />
                {t('shell:residents.userEditor.add')}
              </button>
            </div>

            <div className="mt-3 flex flex-wrap gap-2">
              {permissions.map((permission) => (
                <div
                  key={permission}
                  className="flex items-center gap-2 rounded-md border border-neutral-700 bg-neutral-800 px-3 py-1 text-sm text-neutral-200"
                >
                  <span>{permission}</span>

                  <button
                    type="button"
                    onClick={() => removePermission(permission)}
                    className="text-neutral-400 hover:text-red-400"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={() => onClose(name, permissions)}
              disabled={saving}
              className="rounded-lg border border-neutral-700 px-4 py-2 text-neutral-200 transition hover:bg-neutral-800 disabled:opacity-50"
            >
              {t('shell:residents.userEditor.cancel')}
            </button>

            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className="rounded-lg bg-neutral-100 px-4 py-2 font-medium text-neutral-900 transition hover:bg-neutral-200 disabled:opacity-50"
            >
              {saving
                ? t('shell:residents.userEditor.saving')
                : t('shell:residents.userEditor.save')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
