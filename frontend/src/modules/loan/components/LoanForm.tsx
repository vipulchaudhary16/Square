import React, { useState } from 'react';
import { createLoan } from '../../../api/finance';

interface LoanFormProps {
    onSuccess: () => void;
    onCancel?: () => void;
}

export const LoanForm: React.FC<LoanFormProps> = ({ onSuccess }) => {
    const [formData, setFormData] = useState({
        counterparty_name: '',
        type: 'LENT',
        amount: '',
        date: new Date().toISOString().split('T')[0],
        due_date: '',
        description: '',
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createLoan({
                ...formData,
                amount: parseFloat(formData.amount),
                type: formData.type as 'LENT' | 'BORROWED',
                status: 'PENDING',
            });
            onSuccess();
        } catch (error) {
            console.error('Failed to create loan', error);
            alert('Failed to create loan');
        }
    };

    return (
        <form
            id="loan-form"
            onSubmit={handleSubmit}
            className="grid grid-cols-1 md:grid-cols-2 gap-4"
        >
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Person/Entity
                </label>
                <input
                    type="text"
                    required
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.counterparty_name}
                    onChange={(e) =>
                        setFormData({ ...formData, counterparty_name: e.target.value })
                    }
                    placeholder="e.g. John Doe, Bank of America"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Type
                </label>
                <select
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.type}
                    onChange={(e) =>
                        setFormData({ ...formData, type: e.target.value as 'LENT' | 'BORROWED' })
                    }
                >
                    <option value="LENT">Lent (Given)</option>
                    <option value="BORROWED">Borrowed (Taken)</option>
                </select>
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Amount
                </label>
                <input
                    type="number"
                    required
                    step="0.01"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.amount}
                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
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
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Due Date (Optional)
                </label>
                <input
                    type="date"
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.due_date}
                    onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                />
            </div>
            <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Description
                </label>
                <textarea
                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    rows={2}
                />
            </div>
        </form>
    );
};
