import React, { useState, useMemo } from 'react';
import { Expense } from '../../../api/expenses';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip as RechartsTooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import { format, startOfWeek, endOfWeek, startOfMonth, endOfMonth, startOfYear, endOfYear, parseISO } from 'date-fns';
import { PieChart as PieIcon, Table as TableIcon, Loader2 } from 'lucide-react';
import { useTheme } from '../../../context/ThemeContext';

interface ExpenseReportProps {
    expenses: Expense[];
    isLoading?: boolean;
    onFilterChange?: (startDate: string, endDate: string, category: string) => void;
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8', '#82ca9d'];

export const ExpenseReport: React.FC<ExpenseReportProps> = ({ expenses, isLoading = false, onFilterChange }) => {
    const { theme } = useTheme();
    const [startDate, setStartDate] = useState(() => {
        const now = new Date();
        return startOfMonth(now).toISOString().slice(0, 10);
    });
    const [endDate, setEndDate] = useState(() => {
        const now = new Date();
        return endOfMonth(now).toISOString().slice(0, 10);
    });
    const [selectedCategory, setSelectedCategory] = useState<string>('All');
    const [viewMode, setViewMode] = useState<'charts' | 'table'>('charts');

    
    const categories = ['All', 'Food', 'Transport', 'Entertainment', 'Utilities', 'Shopping', 'Health', 'Travel', 'Other'];

    const handleQuickFilter = (type: 'week' | 'month' | 'year') => {
        const now = new Date();
        let start, end;

        switch (type) {
            case 'week':
                start = startOfWeek(now);
                end = endOfWeek(now);
                break;
            case 'month':
                start = startOfMonth(now);
                end = endOfMonth(now);
                break;
            case 'year':
                start = startOfYear(now);
                end = endOfYear(now);
                break;
        }

        const startStr = start.toISOString();
        const endStr = end.toISOString();
        setStartDate(startStr.slice(0, 10));
        setEndDate(endStr.slice(0, 10));
        if (onFilterChange) onFilterChange(startStr, endStr, selectedCategory);
    };

    const handleCustomFilter = () => {
        if (startDate && endDate && onFilterChange) {
            onFilterChange(new Date(startDate).toISOString(), new Date(endDate).toISOString(), selectedCategory);
        }
    };

    const handleCategoryChange = (category: string) => {
        setSelectedCategory(category);
        if (startDate && endDate && onFilterChange) {
            
            const startISO = new Date(startDate).toISOString();
            const endISO = new Date(endDate).toISOString();
            onFilterChange(startISO, endISO, category);
        }
    };

    
    const filteredExpenses = expenses;

    const totalSpending = useMemo(() => filteredExpenses.reduce((sum, e) => sum + e.amount, 0), [filteredExpenses]);

    const categoryData = useMemo(() => {
        const data: Record<string, number> = {};
        filteredExpenses.forEach(e => {
            data[e.category] = (data[e.category] || 0) + e.amount;
        });
        return Object.entries(data).map(([name, value]) => ({ name, value }));
    }, [filteredExpenses]);

    const dailyData = useMemo(() => {
        const data: Record<string, number> = {};
        filteredExpenses.forEach(e => {
            const date = format(parseISO(e.date), 'MMM dd');
            data[date] = (data[date] || 0) + e.amount;
        });
        return Object.entries(data).map(([name, value]) => ({ name, value }));
    }, [filteredExpenses]);

    const axisColor = theme === 'dark' ? '#94a3b8' : '#64748b';
    const gridColor = theme === 'dark' ? '#334155' : '#e2e8f0';
    const tooltipStyle = theme === 'dark'
        ? { backgroundColor: '#1e293b', border: '1px solid #334155', color: '#f8fafc', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.3)' }
        : { backgroundColor: '#fff', border: 'none', color: '#0f172a', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' };

    return (
        <div className="space-y-8">
            {}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                <div className="flex flex-col md:flex-row md:items-end gap-4">
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 flex-grow">
                        <div>
                            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wider">Start Date</label>
                            <input
                                type="date"
                                value={startDate}
                                onChange={(e) => setStartDate(e.target.value)}
                                className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm py-2.5 px-3 transition-all bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wider">End Date</label>
                            <input
                                type="date"
                                value={endDate}
                                onChange={(e) => setEndDate(e.target.value)}
                                className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm py-2.5 px-3 transition-all bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wider">Category</label>
                            <select
                                value={selectedCategory}
                                onChange={(e) => handleCategoryChange(e.target.value)}
                                className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm py-2.5 px-3 transition-all bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                            >
                                {categories.map(cat => (
                                    <option key={cat} value={cat}>{cat}</option>
                                ))}
                            </select>
                        </div>
                    </div>
                    <div className="flex flex-col sm:flex-row gap-3">
                        <button
                            onClick={handleCustomFilter}
                            className="bg-primary-600 text-white px-5 py-2.5 rounded-xl text-sm font-semibold hover:bg-primary-700 transition-colors shadow-sm shadow-primary-500/20"
                        >
                            Apply Filter
                        </button>
                        <button
                            onClick={() => {
                                setStartDate('');
                                setEndDate('');
                                setSelectedCategory('All');
                                if (onFilterChange) onFilterChange('', '', 'All');
                            }}
                            className="bg-white dark:bg-slate-700 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-600 px-5 py-2.5 rounded-xl text-sm font-semibold hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors"
                        >
                            Clear
                        </button>
                    </div>
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                    <button onClick={() => handleQuickFilter('week')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600">This Week</button>
                    <button onClick={() => handleQuickFilter('month')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600">This Month</button>
                    <button onClick={() => handleQuickFilter('year')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600">This Year</button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center items-center h-64">
                    <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
                </div>
            ) : (
                <>
                    {}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div className="bg-gradient-to-br from-primary-500 to-primary-700 rounded-2xl p-6 text-white shadow-lg shadow-primary-500/20">
                            <p className="text-primary-100 text-sm font-medium uppercase tracking-wider">Total Spending</p>
                            <h3 className="text-3xl font-bold mt-2 tracking-tight">₹{totalSpending.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
                        </div>
                        <div className="bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Transactions</p>
                            <h3 className="text-3xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">{filteredExpenses.length}</h3>
                        </div>
                        <div className="bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Average</p>
                            <h3 className="text-3xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">
                                ₹{filteredExpenses.length ? (totalSpending / filteredExpenses.length).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}
                            </h3>
                        </div>
                    </div>

                    {}
                    <div className="flex justify-between items-center">
                        <h2 className="text-xl font-bold text-slate-800 dark:text-white">Detailed Analysis</h2>
                        <div className="flex bg-slate-100 dark:bg-slate-700 p-1 rounded-xl">
                            <button
                                onClick={() => setViewMode('charts')}
                                className={`p-2 rounded-lg transition-all ${viewMode === 'charts' ? 'bg-white dark:bg-slate-600 text-primary-600 dark:text-primary-400 shadow-sm' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
                            >
                                <PieIcon className="w-5 h-5" />
                            </button>
                            <button
                                onClick={() => setViewMode('table')}
                                className={`p-2 rounded-lg transition-all ${viewMode === 'table' ? 'bg-white dark:bg-slate-600 text-primary-600 dark:text-primary-400 shadow-sm' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
                            >
                                <TableIcon className="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    {viewMode === 'charts' ? (
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                            {}
                            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Expenses by Category</h3>
                                <div className="flex flex-col sm:flex-row items-center gap-8">
                                    <div className="h-64 w-full sm:w-1/2">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <PieChart>
                                                <Pie
                                                    data={categoryData}
                                                    cx="50%"
                                                    cy="50%"
                                                    innerRadius={60}
                                                    outerRadius={80}
                                                    paddingAngle={5}
                                                    dataKey="value"
                                                    onClick={(data) => handleCategoryChange(data.name)}
                                                    cursor="pointer"
                                                >
                                                    {categoryData.map((_, index) => (
                                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} strokeWidth={0} />
                                                    ))}
                                                </Pie>
                                                <RechartsTooltip
                                                    contentStyle={tooltipStyle}
                                                />
                                            </PieChart>
                                        </ResponsiveContainer>
                                    </div>
                                    <div className="w-full sm:w-1/2">
                                        <ul className="space-y-3">
                                            {categoryData.map((entry, index) => (
                                                <li
                                                    key={index}
                                                    className="flex justify-between items-center text-sm cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 p-2 rounded-lg transition-colors"
                                                    onClick={() => handleCategoryChange(entry.name)}
                                                >
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[index % COLORS.length] }}></div>
                                                        <span className="text-slate-700 dark:text-slate-300 font-medium">{entry.name}</span>
                                                    </div>
                                                    <span className="font-bold text-slate-900 dark:text-white">₹{entry.value.toFixed(0)}</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                </div>
                            </div>

                            {}
                            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Daily Spending Trend</h3>
                                <div className="h-80">
                                    <ResponsiveContainer width="100%" height="100%">
                                        <BarChart data={dailyData}>
                                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                                            <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: axisColor, fontSize: 12 }} dy={10} />
                                            <YAxis axisLine={false} tickLine={false} tick={{ fill: axisColor, fontSize: 12 }} />
                                            <RechartsTooltip
                                                cursor={{ fill: theme === 'dark' ? '#334155' : '#f1f5f9' }}
                                                contentStyle={tooltipStyle}
                                            />
                                            <Bar dataKey="value" fill="#8b5cf6" radius={[4, 4, 0, 0]} barSize={32} />
                                        </BarChart>
                                    </ResponsiveContainer>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700 overflow-hidden">
                            <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-slate-100 dark:divide-slate-700">
                                    <thead className="bg-slate-50 dark:bg-slate-700">
                                        <tr>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Date</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Description</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Category</th>
                                            <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Amount</th>
                                        </tr>
                                    </thead>
                                    <tbody className="bg-white dark:bg-slate-800 divide-y divide-slate-100 dark:divide-slate-700">
                                        {filteredExpenses.map((expense) => (
                                            <tr key={expense.id} className="hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400 font-medium">
                                                    {format(parseISO(expense.date), 'MMM dd, yyyy')}
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900 dark:text-white">
                                                    {expense.description}
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">
                                                    <span className="px-2.5 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-600">
                                                        {expense.category}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900 dark:text-white text-right font-bold">
                                                    ₹{expense.amount.toFixed(2)}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    );
};
