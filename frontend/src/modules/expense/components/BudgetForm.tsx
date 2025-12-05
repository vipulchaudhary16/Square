import React from 'react';
import { useForm } from 'react-hook-form';
import { Loader2 } from 'lucide-react';

interface BudgetFormProps {
    onSuccess: () => void;
    initialData?: {
        category: string;
        amount: number;
        month: string;
    };
    onSubmit: (data: any) => Promise<void>;
    loading: boolean;
}

export const BudgetForm: React.FC<BudgetFormProps> = ({ onSuccess, initialData, onSubmit, loading }) => {
    const { register, handleSubmit } = useForm({
        defaultValues: initialData || {
            category: 'Food',
            amount: 0,
            month: new Date().toISOString().slice(0, 7) 
        }
    });

    const handleFormSubmit = async (data: any) => {
        await onSubmit(data);
        onSuccess();
    };

    return (
        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Category</label>
                <select
                    {...register("category")}
                    className="mt-1 block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                    disabled={!!initialData} 
                >
                    {initialData?.category === 'OVERALL' ? (
                        <option value="OVERALL">Overall Monthly Budget</option>
                    ) : (
                        <>
                            <option value="Food">Food</option>
                            <option value="Transport">Transport</option>
                            <option value="Utilities">Utilities</option>
                            <option value="Entertainment">Entertainment</option>
                            <option value="Shopping">Shopping</option>
                            <option value="Health">Health</option>
                            <option value="Travel">Travel</option>
                            <option value="Other">Other</option>
                        </>
                    )}
                </select>
            </div>

            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Month</label>
                <input
                    type="month"
                    {...register("month", { required: true })}
                    className="mt-1 block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                    disabled={!!initialData} 
                />
            </div>

            <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Budget Amount</label>
                <div className="relative mt-1 rounded-md shadow-sm">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                        <span className="text-gray-500 dark:text-slate-400 sm:text-sm">₹</span>
                    </div>
                    <input
                        type="number"
                        step="0.01"
                        {...register("amount", { required: true, min: 0 })}
                        className="block w-full rounded-md border-gray-300 dark:border-slate-600 pl-7 pr-12 focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                        placeholder="0.00"
                    />
                </div>
            </div>

            <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : (initialData ? 'Update Budget' : 'Set Budget')}
            </button>
        </form>
    );
};
