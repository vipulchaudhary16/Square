import api from './index';

export const signup = async (email: string, password: string, firstName: string, lastName: string) => {
    const response = await api.post('/auth/signup', { email, password, first_name: firstName, last_name: lastName });
    return response.data;
};

export const login = async (email: string, password: string) => {
    const response = await api.post('/auth/login', { email, password });
    return response.data;
};

export const getMe = async () => {
    const response = await api.get('/auth/me');
    return response.data;
};
