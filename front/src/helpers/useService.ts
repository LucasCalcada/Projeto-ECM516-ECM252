import axios, { type AxiosInstance } from 'axios';
import config from '../config';

type Service = 'auth' | 'core' | 'delivery' | 'visitor' | 'communication';

const createAxios = (url: string) => {
  const instance = axios.create({
    baseURL: url,
  });

  instance.interceptors.request.use((config) => {
    const token = localStorage.getItem('userToken');

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  });

  return instance;
};

const serviceAxios: Record<Service, AxiosInstance> = {
  auth: createAxios(config.authUrl),
  core: createAxios(config.coreUrl),
  delivery: createAxios(config.deliveryUrl),
  visitor: createAxios(config.visitorAccessUrl),
  communication: createAxios(config.communicationUrl),
};

export default function useService(service: Service): AxiosInstance {
  return serviceAxios[service];
}
