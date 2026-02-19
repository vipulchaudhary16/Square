import React, { useState, useEffect } from 'react';
import { getBudgets, createBudget, updateBudget, deleteBudget, Budget } from '../../../api/finance';
import { getExpenses, Expense } from '../../../api/expenses';
import { BudgetForm } from '../components/BudgetForm';
import { Plus, Trash2, Edit2, Loader2 } from 'lucide-react';
import { format, parseISO } from 'date-fns';

export const BudgetPage: React.FC = () => {
    const [budgets, setBudgets] = useState<Budget[]>([]);
    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7));
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingBudget, setEditingBudget] = useState<Budget | null>(null);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [budgetsRes, expensesRes] = await Promise.all([
                getBudgets(selectedMonth),
                getExpenses(),
            ]);
            setBudgets(budgetsRes || []);
            setExpenses(Array.isArray(expensesRes) ? expensesRes : expensesRes.data || []);
        } catch (error) {
            console.error('Failed to fetch data', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, [selectedMonth]);

    const handleSave = async (data: any) => {
        if (editingBudget && editingBudget.id) {
            await updateBudget(editingBudget.id, { amount: Number(data.amount) });
        } else {
            await createBudget({ ...data, amount: Number(data.amount) });
        }
        setIsModalOpen(false);
        setEditingBudget(null);
        fetchData();
    };

    const handleDelete = async (id: string) => {
        if (confirm('Are you sure you want to delete this budget?')) {
            await deleteBudget(id);
            fetchData();
        }
    };

    const getSpendingForCategory = (category: string) => {
        return expenses
            .filter((e) => e.category === category && e.date.startsWith(selectedMonth))
            .reduce((sum, e) => sum + e.amount, 0);
    };

    const getTotalSpending = () => {
        return expenses
            .filter((e) => e.date.startsWith(selectedMonth))
            .reduce((sum, e) => sum + e.amount, 0);
    };

    const overallBudget = budgets.find((b) => b.category === 'OVERALL');
    const categoryBudgets = budgets.filter((b) => b.category !== 'OVERALL');
    const totalSpent = getTotalSpending();

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Monthly Budgets
                    </h1>
                    <p className="text-gray-500 dark:text-slate-400">Track your spending limits</p>
                </div>
                <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-4 w-full md:w-auto">
                    <input
                        type="month"
                        value={selectedMonth}
                        onChange={(e) => setSelectedMonth(e.target.value)}
                        className="rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-800 text-gray-900 dark:text-white w-full sm:w-auto"
                    />
                    {!overallBudget && (
                        <button
                            onClick={() => {
                                setEditingBudget({
                                    category: 'OVERALL',
                                    amount: 0,
                                    month: selectedMonth,
                                } as any);
                                setIsModalOpen(true);
                            }}
                            className="flex items-center justify-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors w-full sm:w-auto"
                        >
                            <Plus className="w-4 h-4" /> Set Total Budget
                        </button>
                    )}
                    <button
                        onClick={() => {
                            setEditingBudget(null);
                            setIsModalOpen(true);
                        }}
                        className="flex items-center justify-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors w-full sm:w-auto"
                    >
                        <Plus className="w-4 h-4" /> Set Category Budget
                    </button>
                </div>
            </div>

            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                </div>
            ) : (
                <div className="space-y-8">
                    {}
                    {overallBudget && (
                        <div className="bg-gradient-to-br from-slate-900 to-slate-800 dark:from-slate-800 dark:to-slate-900 rounded-2xl p-6 text-white shadow-xl">
                            <div className="flex justify-between items-start mb-6">
                                <div>
                                    <h2 className="text-xl font-bold">Overall Monthly Budget</h2>
                                    <p className="text-slate-400 text-sm">
                                        {format(parseISO(selectedMonth + '-01'), 'MMMM yyyy')}
                                    </p>
                                </div>
                                <div className="flex gap-2">
                                    <button
                                        onClick={() => {
                                            setEditingBudget(overallBudget);
                                            setIsModalOpen(true);
                                        }}
                                        className="p-2 bg-white/10 rounded-lg hover:bg-white/20 transition-colors"
                                    >
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(overallBudget.id)}
                                        className="p-2 bg-white/10 rounded-lg hover:bg-red-500/20 text-red-400 transition-colors"
                                    >
                                        <Trash2 className="w-4 h-4" />
                                    </button>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-6">
                                <div>
                                    <p className="text-slate-400 text-sm mb-1">Total Budget</p>
                                    <p className="text-3xl font-bold">
                                        ₹{overallBudget.amount.toLocaleString()}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-slate-400 text-sm mb-1">Total Spent</p>
                                    <p className="text-3xl font-bold">
                                        ₹{totalSpent.toLocaleString()}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-slate-400 text-sm mb-1">Remaining</p>
                                    <p
                                        className={`text-3xl font-bold ${overallBudget.amount - totalSpent < 0 ? 'text-red-400' : 'text-emerald-400'}`}
                                    >
                                        ₹{(overallBudget.amount - totalSpent).toLocaleString()}
                                    </p>
                                </div>
                            </div>

                            <div className="relative pt-1">
                                <div className="flex mb-2 items-center justify-between">
                                    <div>
                                        <span className="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full text-blue-600 bg-blue-200">
                                            {Math.min(
                                                (totalSpent / overallBudget.amount) * 100,
                                                100,
                                            ).toFixed(0)}
                                            % Used
                                        </span>
                                    </div>
                                </div>
                                <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-slate-700">
                                    <div
                                        style={{
                                            width: `${Math.min((totalSpent / overallBudget.amount) * 100, 100)}%`,
                                        }}
                                        className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${totalSpent > overallBudget.amount ? 'bg-red-500' : 'bg-blue-500'}`}
                                    ></div>
                                </div>
                            </div>
                        </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {categoryBudgets.map((budget) => {
                            const spent = getSpendingForCategory(budget.category);
                            const percentage = Math.min((spent / budget.amount) * 100, 100);
                            const isOverBudget = spent > budget.amount;

                            return (
                                <div
                                    key={budget.id}
                                    className="bg-white dark:bg-slate-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700"
                                >
                                    <div className="flex justify-between items-start mb-4">
                                        <div>
                                            <h3 className="font-semibold text-gray-900 dark:text-white">
                                                {budget.category}
                                            </h3>
                                            <p className="text-sm text-gray-500 dark:text-slate-400">
                                                {format(
                                                    parseISO(budget.month + '-01'),
                                                    'MMMM yyyy',
                                                )}
                                            </p>
                                        </div>
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => {
                                                    setEditingBudget(budget);
                                                    setIsModalOpen(true);
                                                }}
                                                className="text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
                                            >
                                                <Edit2 className="w-4 h-4" />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(budget.id)}
                                                className="text-gray-400 hover:text-red-600 dark:hover:text-red-400"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </div>

                                    <div className="mb-2 flex justify-between text-sm">
                                        <span className="text-gray-600 dark:text-slate-400">
                                            Spent:{' '}
                                            <span className="font-medium text-gray-900 dark:text-white">
                                                ₹{spent.toFixed(2)}
                                            </span>
                                        </span>
                                        <span className="text-gray-600 dark:text-slate-400">
                                            Budget:{' '}
                                            <span className="font-medium text-gray-900 dark:text-white">
                                                ₹{budget.amount.toFixed(2)}
                                            </span>
                                        </span>
                                    </div>

                                    <div className="w-full bg-gray-200 dark:bg-slate-700 rounded-full h-2.5 mb-4">
                                        <div
                                            className={`h-2.5 rounded-full transition-all duration-500 ${isOverBudget ? 'bg-red-600' : 'bg-blue-600'}`}
                                            style={{ width: `${percentage}%` }}
                                        ></div>
                                    </div>

                                    <div className="text-xs text-right">
                                        {isOverBudget ? (
                                            <span className="text-red-600 dark:text-red-400 font-medium">
                                                Over by ₹{(spent - budget.amount).toFixed(2)}
                                            </span>
                                        ) : (
                                            <span className="text-green-600 dark:text-green-400 font-medium">
                                                ₹{(budget.amount - spent).toFixed(2)} remaining
                                            </span>
                                        )}
                                    </div>
                                </div>
                            );
                        })}

                        {budgets.length === 0 && (
                            <div className="col-span-full text-center py-12 text-gray-500 dark:text-slate-400">
                                No budgets set for this month. Click "Set Budget" to get started.
                            </div>
                        )}
                    </div>
                </div>
            )}

            {isModalOpen && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
                    <div className="bg-white dark:bg-slate-800 rounded-xl p-6 w-full max-w-md border dark:border-slate-700">
                        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
                            {editingBudget ? 'Edit Budget' : 'Set New Budget'}
                        </h2>
                        <BudgetForm
                            onSuccess={() => {}}
                            initialData={
                                editingBudget
                                    ? {
                                          category: editingBudget.category,
                                          amount: editingBudget.amount,
                                          month: editingBudget.month,
                                      }
                                    : undefined
                            }
                            onSubmit={handleSave}
                            loading={loading}
                        />
                        <button
                            onClick={() => setIsModalOpen(false)}
                            className="mt-4 w-full py-2 text-gray-600 dark:text-slate-400 hover:text-gray-800 dark:hover:text-white"
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};
