import React from 'react';
import { AddExpenseForm } from '../components/AddExpenseForm';
import { useNavigate } from 'react-router-dom';

export const AddExpensePage: React.FC = () => {
    const navigate = useNavigate();

    return (
        <div className="max-w-2xl mx-auto">
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Add New Expense</h1>
                <p className="text-gray-500 dark:text-slate-400">Record a new transaction for yourself or your group.</p>
            </div>
            <AddExpenseForm onSuccess={() => navigate('/dashboard')} />
        </div>
    );
};
