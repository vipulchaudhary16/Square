import api from './index';

export interface Group {
    id: string;
    name: string;
    description: string;
    members: string[];
    created_by: string;
    created_at: string;
}

import { User } from './users';

export interface Debt {
    from: string;
    to: string;
    amount: number;
}

export interface GroupDetails {
    group: Group;
    members: User[];
    debts?: Debt[];
}

export const createGroup = async (data: { name: string; description: string }) => {
    const response = await api.post('/groups', data);
    return response.data;
};

export const getUserGroups = async () => {
    const response = await api.get('/groups');
    return response.data;
};

export const getGroupDetails = async (id: string) => {
    const response = await api.get(`/groups/${id}`);
    return response.data;
};

export const inviteUser = async (groupId: string, email: string) => {
    const response = await api.post(`/groups/${groupId}/invite`, { email });
    return response.data;
};

export const joinGroup = async (token: string) => {
    const response = await api.post('/groups/join', { token });
    return response.data;
};

export const addMember = async (groupId: string, userId: string) => {
    const response = await api.post(`/groups/${groupId}/members`, { user_id: userId });
    return response.data;
};

export const settleDebt = async (groupId: string, toUserId: string, amount: number) => {
    const response = await api.post(`/groups/${groupId}/settle`, { to_user_id: toUserId, amount });
    return response.data;
};
