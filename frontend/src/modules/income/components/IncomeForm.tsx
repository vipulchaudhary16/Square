import React, { useState } from 'react';
import { createIncome } from '../../../api/finance';

interface IncomeFormProps {
    onSuccess: () => void;
    onCancel?: () => void;
}

export const IncomeForm: React.FC<IncomeFormProps> = ({ onSuccess }) => {
    const [formData, setFormData] = useState({
        source: '',
        amount: '',
        category: '',
        date: new Date().toISOString().split('T')[0],
        description: '',
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createIncome({
                ...formData,
                amount: parseFloat(formData.amount),
            });
            onSuccess();
        } catch (error) {
            console.error('Failed to create income', error);
            alert('Failed to create income');
        }
    };

    return (
        <form
            id="income-form"
            onSubmit={handleSubmit}
            className="grid grid-cols-1 md:grid-cols-2 gap-4"
        >
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Source
                </label>
                <input
                    type="text"
                    required
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.source}
                    onChange={(e) => setFormData({ ...formData, source: e.target.value })}
                    placeholder="e.g. Salary, Freelance"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Amount
                </label>
                <input
                    type="number"
                    required
                    step="0.01"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.amount}
                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                    placeholder="0.00"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Category
                </label>
                <input
                    type="text"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    placeholder="e.g. Primary Job, Side Hustle"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Date
                </label>
                <input
                    type="date"
                    required
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                />
            </div>
            <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Description
                </label>
                <textarea
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    rows={2}
                />
            </div>
        </form>
    );
};
