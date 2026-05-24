import api from './index';

export interface Category {
    id: string;
    name: string;
    applies_to: ('expense' | 'income' | 'budget')[];
    is_standard: boolean;
}

export const getCategories = async (appliesTo?: string): Promise<Category[]> => {
    const params = appliesTo ? `?applies_to=${appliesTo}` : '';
    const response = await api.get(`/categories${params}`);
    return response.data;
};

export const createCategory = async (data: {
    name: string;
    applies_to: string[];
}): Promise<Category> => {
    const response = await api.post('/categories', data);
    return response.data;
};

export const updateCategory = async (
    id: string,
    data: { name: string; applies_to: string[] },
): Promise<Category> => {
    const response = await api.patch(`/categories/${id}`, data);
    return response.data;
};

export const deleteCategory = async (id: string): Promise<void> => {
    await api.delete(`/categories/${id}`);
};
