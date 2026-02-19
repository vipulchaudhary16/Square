import api from './index';

export interface PaginatedResponse<T> {
    data: T[];
    total: number;
    page: number;
    limit: number;
}

export const getExpenses = async (
    startDate?: string,
    endDate?: string,
    personalOnly?: boolean,
    category?: string,
    page?: number,
    limit?: number,
    sortBy?: string,
    sortOrder?: 'asc' | 'desc',
): Promise<PaginatedResponse<Expense> | Expense[]> => {
    const params = new URLSearchParams();
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    if (personalOnly) params.append('personal_only', 'true');
    if (category && category !== 'All') params.append('category', category);
    if (page) params.append('page', page.toString());
    if (limit) params.append('limit', limit.toString());
    if (sortBy) params.append('sort_by', sortBy);
    if (sortOrder) params.append('sort_order', sortOrder);

    const response = await api.get(`/expenses?${params.toString()}`);
    return response.data;
};

export interface Expense {
    id: string;
    description: string;
    amount: number;
    category: string;
    date: string;
    payer_id: string;
    group_id?: string;
    split_type?: string;
    participants?: string[];
    splits?: Record<string, number>;
    group_name?: string;
}

export const createExpense = async (data: any) => {
    const response = await api.post('/expenses', data);
    return response.data;
};

export const getExpenseDetails = async (id: string) => {
    const response = await api.get(`/expenses/${id}`);
    return response.data;
};

export const updateExpense = async (id: string, data: any) => {
    const response = await api.put(`/expenses/${id}`, data);
    return response.data;
};

export const deleteExpense = async (id: string) => {
    const response = await api.delete(`/expenses/${id}`);
    return response.data;
};

export const addComment = async (id: string, text: string) => {
    const response = await api.post(`/expenses/${id}/comments`, { text });
    return response.data;
};

export const getGroupExpenses = async (
    groupId: string,
    startDate?: string,
    endDate?: string,
    category?: string,
    search?: string,
) => {
    const params = new URLSearchParams();
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    if (category && category !== 'All') params.append('category', category);
    if (search) params.append('search', search);
    const response = await api.get(`/groups/${groupId}/expenses?${params.toString()}`);
    return response.data;
};
