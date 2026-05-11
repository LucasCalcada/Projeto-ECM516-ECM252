import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import axios from 'axios';
import config from '../config';
import { useTranslation } from 'react-i18next';
import { type AccountUser } from '../types/AccountUser';
import UserSelector from '../components/Login/UserSelector';
import { useToast } from '../components/Toast';

export default function SelectUserPage() {
  const [users, setUsers] = useState<AccountUser[]>([]);
  const { t } = useTranslation();

  useEffect(() => {
    loadUsers();
  }, []);

  const token = localStorage.getItem('accountToken');
  const axiosInstance = axios.create({
    baseURL: config.coreUrl,
    headers: {
      Authorization: token,
    },
  });

  const navigate = useNavigate();
  const { notifyError } = useToast();

  async function loadUsers() {
    try {
      const response = await axiosInstance.get<AccountUser[]>('/account');
      setUsers(response.data);
    } catch (error) {
      notifyError(
        t('login:selector.error.fetchError.title'),
        t('login:selector.error.fetchError.message'),
      );
    }
  }

  async function handleSelectUser(user: AccountUser) {
    try {
      const response = await axiosInstance.get('/auth', {
        params: {
          userId: user.userId,
        },
      });

      const token = response.data.token;

      localStorage.setItem('userToken', token);
      navigate('/home');
    } catch (error) {
      notifyError(
        t('login:selector.error.selectionError.title'),
        t('login:selector.error.selectionError.message'),
      );
    }
  }

  return (
    <div className="flex h-screen w-screen flex-col items-center justify-center p-16">
      <div className="flex h-full flex-col items-center justify-center gap-4 rounded-2xl border border-neutral-800 bg-neutral-900 p-4">
        <h1 className="text-2xl font-bold text-neutral-200">{t('login:selector.title')}</h1>
        <div className="flex h-full flex-col gap-2">
          {users.map((user) => {
            return <UserSelector key={user.userId} user={user} onSelected={handleSelectUser} />;
          })}
        </div>
      </div>
    </div>
  );
}
