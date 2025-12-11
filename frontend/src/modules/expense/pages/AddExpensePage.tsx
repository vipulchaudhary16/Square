import React from 'react';
import { AddExpenseForm } from '../components/AddExpenseForm';
import { useNavigate } from 'react-router-dom';

export const AddExpensePage: React.FC = () => {
    const navigate = useNavigate();
    const [loading, setLoading] = React.useState(false);

    return (
        <div className="max-w-2xl mx-auto p-2">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Add New Expense</h1>
                    <p className="text-gray-500 dark:text-slate-400 text-sm mt-1">Record a new transaction.</p>
                </div>
                <button
                    type="submit"
                    form="add-expense-form"
                    disabled={loading}
                    className="flex items-center justify-center py-2 px-6 border border-transparent rounded-xl shadow-sm text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 transition-all active:scale-95"
                >
                    {loading ? 'Saving...' : 'Save'}
                </button>
            </div>
            <AddExpenseForm 
                onSuccess={() => navigate('/dashboard')} 
                formId="add-expense-form"
                hideSubmitButton={true}
                onLoadingChange={setLoading}
                hideHeader={true}
            />
        </div>
    );
};
