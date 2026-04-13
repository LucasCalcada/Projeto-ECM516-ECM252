import React, { useState } from 'react';
import Logo from './Logo';
import TextField from './TextField';
import Button from './Button';
import { useNavigate } from 'react-router';
import { useTranslation } from 'react-i18next';
import config from '../../config';

export default function LoginBox() {
  const { t } = useTranslation();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [credentialError, setCredentialError] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setCredentialError('');
    try {
      const authUrl = `${config.authUrl}/auth/login`;
      const response = await fetch(authUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });
      if (response.ok) {
        const data = await response.json();
        localStorage.setItem('accessToken', data.accessToken);
        navigate('/home');
      } else {
        const errorText = await response.text();
        setCredentialError(errorText);
      }
    } catch (error) {
      alert('Erro ao conectar com o servidor');
    }
  };

  return (
    <div className="flex min-h-screen w-full flex-col items-center justify-center bg-neutral-800">
      <Logo />

      <div className="w-full max-w-sm rounded-lg bg-neutral-800 p-10">
        <h2 className="mb-8 text-center text-2xl font-bold text-neutral-100">Login</h2>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <TextField
            id="username"
            label={t('login.fields.email.label')}
            type="text"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder={t('login.fields.email.placeholder')}
          />

          <TextField
            id="password"
            label={t('login.fields.password.label')}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={t('login.fields.password.placeholder')}
          />

          <div
            className="-mt-2 min-h-5 text-center text-sm text-red-400"
            role="alert"
            aria-live="polite"
          >
            {credentialError}
          </div>

          <Button text={t('login.login')} type="submit" />
        </form>
      </div>
    </div>
  );
}
