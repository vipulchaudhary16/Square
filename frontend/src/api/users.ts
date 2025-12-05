import api from './index';

export interface User {
    id: string;
    username: string;
    email: string;
    first_name?: string;
    last_name?: string;
}

export const searchUsers = async (query: string) => {
    const response = await api.get(`/users/search?q=${query}`);
    return response.data;
};
