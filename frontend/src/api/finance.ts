import api from './index';



export interface ActivityLog {
    id: string;
    action: string;
    details: string;
    created_at: string;
    user_id: string;
}

export interface Comment {
    id: string;
    text: string;
    created_at: string;
    user_id: string;
}

export interface Income {
    id: string;
    source: string;
    amount: number;
    category: string;
    date: string;
    description: string;
}

export interface IncomeDetails extends Income {
    logs: ActivityLog[];
    comments: Comment[];
    users: Record<string, string>;
}

export interface Investment {
    id: string;
    name: string;
    type: string;
    amount_invested: number;
    current_value: number;
    date: string;
    description: string;
}

export interface InvestmentDetails extends Investment {
    logs: ActivityLog[];
    comments: Comment[];
    users: Record<string, string>;
}

export interface Loan {
    id: string;
    counterparty_name: string;
    type: 'LENT' | 'BORROWED';
    amount: number;
    date: string;
    due_date?: string;
    status: 'PENDING' | 'PAID';
    description: string;
}

export interface LoanDetails extends Loan {
    logs: ActivityLog[];
    comments: Comment[];
    users: Record<string, string>;
}

export interface Budget {
    id: string;
    category: string;
    amount: number;
    month: string;
    user_id: string;
}

export interface PaginatedResponse<T> {
    data: T[];
    total: number;
    page: number;
    limit: number;
}



export const getIncomes = async (page?: number, limit?: number, sortBy?: string, sortOrder?: 'asc' | 'desc', startDate?: string, endDate?: string) => {
    const params = new URLSearchParams();
    if (page) params.append('page', page.toString());
    if (limit) params.append('limit', limit.toString());
    if (sortBy) params.append('sort_by', sortBy);
    if (sortOrder) params.append('sort_order', sortOrder);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);

    const response = await api.get(`/incomes?${params.toString()}`);
    return response.data;
};

export const createIncome = async (data: Omit<Income, 'id'>) => {
    const response = await api.post('/incomes', data);
    return response.data;
};

export const getIncomeDetails = async (id: string) => {
    const response = await api.get(`/incomes/${id}`);
    return response.data;
};

export const updateIncome = async (id: string, data: Partial<Income>) => {
    const response = await api.put(`/incomes/${id}`, data);
    return response.data;
};

export const deleteIncome = async (id: string) => {
    const response = await api.delete(`/incomes/${id}`);
    return response.data;
};

export const addIncomeComment = async (id: string, text: string) => {
    const response = await api.post(`/incomes/${id}/comments`, { text });
    return response.data;
};



export const getInvestments = async (page?: number, limit?: number, sortBy?: string, sortOrder?: 'asc' | 'desc', startDate?: string, endDate?: string) => {
    const params = new URLSearchParams();
    if (page) params.append('page', page.toString());
    if (limit) params.append('limit', limit.toString());
    if (sortBy) params.append('sort_by', sortBy);
    if (sortOrder) params.append('sort_order', sortOrder);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);

    const response = await api.get(`/investments?${params.toString()}`);
    return response.data;
};

export const createInvestment = async (data: Omit<Investment, 'id'>) => {
    const response = await api.post('/investments', data);
    return response.data;
};

export const getInvestmentDetails = async (id: string) => {
    const response = await api.get(`/investments/${id}`);
    return response.data;
};

export const updateInvestment = async (id: string, data: Partial<Investment>) => {
    const response = await api.put(`/investments/${id}`, data);
    return response.data;
};

export const deleteInvestment = async (id: string) => {
    const response = await api.delete(`/investments/${id}`);
    return response.data;
};

export const addInvestmentComment = async (id: string, text: string) => {
    const response = await api.post(`/investments/${id}/comments`, { text });
    return response.data;
};



export const getLoans = async (page?: number, limit?: number, sortBy?: string, sortOrder?: 'asc' | 'desc', startDate?: string, endDate?: string) => {
    const params = new URLSearchParams();
    if (page) params.append('page', page.toString());
    if (limit) params.append('limit', limit.toString());
    if (sortBy) params.append('sort_by', sortBy);
    if (sortOrder) params.append('sort_order', sortOrder);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);

    const response = await api.get(`/loans?${params.toString()}`);
    return response.data;
};

export const createLoan = async (data: Omit<Loan, 'id'>) => {
    const response = await api.post('/loans', data);
    return response.data;
};

export const getLoanDetails = async (id: string) => {
    const response = await api.get(`/loans/${id}`);
    return response.data;
};

export const updateLoan = async (id: string, data: Partial<Loan>) => {
    const response = await api.put(`/loans/${id}`, data);
    return response.data;
};

export const deleteLoan = async (id: string) => {
    const response = await api.delete(`/loans/${id}`);
    return response.data;
};

export const addLoanComment = async (id: string, text: string) => {
    const response = await api.post(`/loans/${id}/comments`, { text });
    return response.data;
};



export const getBudgets = async (month: string) => {
    const response = await api.get(`/budgets?month=${month}`);
    return response.data;
};

export const createBudget = async (data: Omit<Budget, 'id'>) => {
    const response = await api.post('/budgets', data);
    return response.data;
};

export const updateBudget = async (id: string, data: Partial<Budget>) => {
    const response = await api.put(`/budgets/${id}`, data);
    return response.data;
};

export const deleteBudget = async (id: string) => {
    const response = await api.delete(`/budgets/${id}`);
    return response.data;
};
