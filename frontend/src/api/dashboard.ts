import api from './index';

export interface DashboardData {
    total_expenses: number;
    total_income: number;
    total_invested: number;
    recent_expenses: any[]; 
    lent_amount: number;
    borrowed_amount: number;
    expense_graph: { day: number; current_month: number; last_month: number }[];
}

export const getDashboardData = async (): Promise<DashboardData> => {
    const response = await api.get('/dashboard');
    return response.data;
};
