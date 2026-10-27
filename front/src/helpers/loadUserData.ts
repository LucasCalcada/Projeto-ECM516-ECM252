import * as jose from 'jose';

function saveToStorage(key: string, value: any) {
  if (typeof value === 'string') {
    localStorage.setItem(key, value);
    return;
  }
  const valueString = JSON.stringify(value);
  localStorage.setItem(key, valueString);
}

export default function loadUserData(token: string) {
  localStorage.setItem('userToken', token);

  const userData = jose.decodeJwt(token);
  saveToStorage('userToken', token);
  Object.keys(userData).map((k) => saveToStorage(k, userData[k]));
}
