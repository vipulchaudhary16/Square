import React, { useState } from 'react';
import { createInvestment } from '../../../api/finance';

interface InvestmentFormProps {
    onSuccess: () => void;
    onCancel?: () => void;
}

export const InvestmentForm: React.FC<InvestmentFormProps> = ({ onSuccess }) => {
    const [formData, setFormData] = useState({
        name: '',
        type: 'STOCK',
        amount_invested: '',
        current_value: '',
        date: new Date().toISOString().split('T')[0],
        description: '',
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createInvestment({
                ...formData,
                amount_invested: parseFloat(formData.amount_invested),
                current_value: parseFloat(formData.current_value),
            });
            onSuccess();
        } catch (error) {
            console.error('Failed to create investment', error);
            alert('Failed to create investment');
        }
    };

    return (
        <form
            id="investment-form"
            onSubmit={handleSubmit}
            className="grid grid-cols-1 md:grid-cols-2 gap-4"
        >
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Name
                </label>
                <input
                    type="text"
                    required
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Apple Stock, Bitcoin"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Type
                </label>
                <select
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                    <option value="STOCK">Stock</option>
                    <option value="CRYPTO">Crypto</option>
                    <option value="MUTUAL_FUND">Mutual Fund</option>
                    <option value="REAL_ESTATE">Real Estate</option>
                    <option value="OTHER">Other</option>
                </select>
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Amount Invested
                </label>
                <input
                    type="number"
                    required
                    step="0.01"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.amount_invested}
                    onChange={(e) => setFormData({ ...formData, amount_invested: e.target.value })}
                    placeholder="0.00"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Current Value
                </label>
                <input
                    type="number"
                    required
                    step="0.01"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.current_value}
                    onChange={(e) => setFormData({ ...formData, current_value: e.target.value })}
                    placeholder="0.00"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Date
                </label>
                <input
                    type="date"
                    required
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                />
            </div>
            <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Description
                </label>
                <textarea
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    rows={2}
                />
            </div>
        </form>
    );
};
