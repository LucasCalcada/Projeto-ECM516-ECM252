import React, { useState } from 'react';
import Logo from './Logo';
import TextField from './TextField';
import Button from './Button';
import { useNavigate } from 'react-router';
import { useTranslation } from 'react-i18next';

export default function LoginBox() {
  const { t } = useTranslation();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [credentialError, setCredentialError] = useState('');
  const navigate = useNavigate();

  const handleSubmit =async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setCredentialError('');
    try{
      const response = await fetch('http://localhost:3000/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
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
    <div className="w-full min-h-screen flex flex-col items-center justify-center bg-neutral-800">
      <Logo />

      <div className="bg-neutral-800 p-10 rounded-lg  w-full max-w-sm">
        <h2 className="text-2xl font-bold text-center text-neutral-100 mb-8">Login</h2>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <TextField
            id="username"
            label={t('login.fields.username.label')}
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder={t('login.fields.username.placeholder')}
          />

          <TextField
            id="password"
            label={t('login.fields.password.label')}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={t('login.fields.password.placeholder')}
          />

          <div className="min-h-5 -mt-2 text-center text-sm text-red-400" role="alert" aria-live="polite">
            {credentialError}
          </div>
          
          <Button text={t('login.login')} type="submit" />
        </form>
      </div>
    </div>
  );
}
