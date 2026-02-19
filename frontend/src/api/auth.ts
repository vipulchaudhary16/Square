import api from './index';

export const signup = async (
    email: string,
    password: string,
    firstName: string,
    lastName: string,
) => {
    const response = await api.post('/auth/signup', {
        email,
        password,
        first_name: firstName,
        last_name: lastName,
    });
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

export const forgotPassword = async (email: string) => {
    const response = await api.post('/auth/forgot-password', { email });
    return response.data;
};

export const resetPassword = async (token: string, password: string) => {
    const response = await api.post('/auth/reset-password', { token, password });
    return response.data;
};
