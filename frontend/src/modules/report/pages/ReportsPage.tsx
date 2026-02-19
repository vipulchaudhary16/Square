import React, { useState, useEffect } from 'react';
import { ExpenseReport } from '../components/ExpenseReport';
import { IncomeReport } from '../../income/components/IncomeReport';
import { InvestmentReport } from '../../investment/components/InvestmentReport';
import { LoanReport } from '../../loan/components/LoanReport';
import { getExpenses, Expense } from '../../../api/expenses';
import {
    getIncomes,
    getInvestments,
    getLoans,
    Income,
    Investment,
    Loan,
} from '../../../api/finance';
import { useSession } from '../../../hooks/useSession';
import { LayoutDashboard, DollarSign, TrendingUp, ArrowLeftRight } from 'lucide-react';

const ReportsPage: React.FC = () => {
    useSession();
    const [activeTab, setActiveTab] = useState<'expenses' | 'income' | 'investments' | 'loans'>(
        'expenses',
    );

    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [incomes, setIncomes] = useState<Income[]>([]);
    const [investments, setInvestments] = useState<Investment[]>([]);
    const [loans, setLoans] = useState<Loan[]>([]);

    const [loading, setLoading] = useState(false);

    const fetchExpenses = async (startDate?: string, endDate?: string, category?: string) => {
        setLoading(true);
        try {
            const data = await getExpenses(startDate, endDate, true, category);
            setExpenses(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error('Failed to fetch expenses', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchOtherData = async () => {
        setLoading(true);
        try {
            const [incData, invData, loanData] = await Promise.all([
                getIncomes(),
                getInvestments(),
                getLoans(),
            ]);
            setIncomes(Array.isArray(incData) ? incData : incData.data || []);
            setInvestments(Array.isArray(invData) ? invData : invData.data || []);
            setLoans(Array.isArray(loanData) ? loanData : loanData.data || []);
        } catch (error) {
            console.error('Failed to fetch financial data', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (activeTab === 'expenses') {
            fetchExpenses();
        } else {
            fetchOtherData();
        }
    }, [activeTab]);

    const tabs = [
        { id: 'expenses', label: 'Expenses', icon: LayoutDashboard },
        { id: 'income', label: 'Income', icon: DollarSign },
        { id: 'investments', label: 'Investments', icon: TrendingUp },
        { id: 'loans', label: 'Loans', icon: ArrowLeftRight },
    ];

    return (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-20">
            <div className="flex flex-row items-center justify-between mb-6 md:mb-8">
                <h1 className="text-xl md:text-3xl font-bold text-gray-900 dark:text-white">
                    Financial Reports
                </h1>

                <div className="md:hidden">
                    <select
                        value={activeTab}
                        onChange={(e) => setActiveTab(e.target.value as any)}
                        className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5"
                    >
                        {tabs.map((tab) => (
                            <option key={tab.id} value={tab.id}>
                                {tab.label}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="hidden md:flex space-x-1 bg-slate-100 dark:bg-slate-800 p-1 rounded-xl mb-8 overflow-x-auto">
                {tabs.map((tab) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === tab.id;
                    return (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id as any)}
                            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${
                                isActive
                                    ? 'bg-white dark:bg-slate-700 text-primary-600 dark:text-primary-400 shadow-sm'
                                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/50'
                            }`}
                        >
                            <Icon size={18} />
                            {tab.label}
                        </button>
                    );
                })}
            </div>

            <div className="animate-fade-in">
                {activeTab === 'expenses' && (
                    <ExpenseReport
                        expenses={expenses}
                        isLoading={loading}
                        onFilterChange={fetchExpenses}
                    />
                )}
                {activeTab === 'income' && <IncomeReport incomes={incomes} isLoading={loading} />}
                {activeTab === 'investments' && (
                    <InvestmentReport investments={investments} isLoading={loading} />
                )}
                {activeTab === 'loans' && <LoanReport loans={loans} isLoading={loading} />}
            </div>
        </div>
    );
};

export default ReportsPage;
