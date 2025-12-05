import api from './index';

export interface DashboardData {
    total_expenses: number;
    total_income: number;
    total_invested: number;
    recent_expenses: any[]; 
    lent_amount: number;
    borrowed_amount: number;
}

export const getDashboardData = async (): Promise<DashboardData> => {
    const response = await api.get('/dashboard');
    return response.data;
};
