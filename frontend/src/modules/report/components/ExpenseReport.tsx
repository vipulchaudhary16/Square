import React, { useState, useMemo } from 'react';
import { Expense } from '../../../api/expenses';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip as RechartsTooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import { useBodyScrollLock } from '../../../hooks/useBodyScrollLock';
import { format, startOfWeek, endOfWeek, startOfMonth, endOfMonth, startOfYear, endOfYear, parseISO, differenceInDays } from 'date-fns';
import { PieChart as PieIcon, Table as TableIcon, Loader2, Filter, X } from 'lucide-react';
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
    const [isFilterOpen, setIsFilterOpen] = useState(false);

    useBodyScrollLock(isFilterOpen);
    
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

    const { chartData, granularity } = useMemo(() => {
        if (!startDate || !endDate) return { chartData: [], granularity: 'Daily' };

        const start = parseISO(startDate);
        const end = parseISO(endDate);
        const daysDiff = differenceInDays(end, start);

        let granularity: 'Daily' | 'Weekly' | 'Monthly' = 'Daily';
        let dateFormat = 'MMM dd';

        if (daysDiff > 60) {
            granularity = 'Monthly';
            dateFormat = 'MMM yyyy';
        } else if (daysDiff > 30) {
            granularity = 'Weekly';
            dateFormat = 'MMM dd';
        }

        const data: Record<string, number> = {};
        
        // Initialize map with 0s if needed, or just let it be sparse. 
        // For a better chart, sparse is usually fine for bar charts, but 0s are better for continuity.
        // For now, let's stick to aggregating existing expenses to keep it simple and efficient.

        filteredExpenses.forEach(e => {
            const date = parseISO(e.date);
            let key = '';

            if (granularity === 'Monthly') {
                key = format(startOfMonth(date), dateFormat);
            } else if (granularity === 'Weekly') {
                key = format(startOfWeek(date), dateFormat);
            } else {
                key = format(date, dateFormat);
            }

            data[key] = (data[key] || 0) + e.amount;
        });


            
        // Let's refine the aggregation to use sortable keys
        const dataMap: Record<string, { label: string, value: number, sortKey: number }> = {};

        filteredExpenses.forEach(e => {
            const date = parseISO(e.date);
            let sortKey = 0;
            let label = '';

            if (granularity === 'Monthly') {
                const start = startOfMonth(date);
                sortKey = start.getTime();
                label = format(start, 'MMM yyyy');
            } else if (granularity === 'Weekly') {
                const start = startOfWeek(date);
                sortKey = start.getTime();
                label = format(start, 'MMM dd');
            } else {
                sortKey = date.getTime();
                label = format(date, 'MMM dd');
            }

            if (!dataMap[label]) {
                dataMap[label] = { label, value: 0, sortKey };
            }
            dataMap[label].value += e.amount;
        });

        const finalData = Object.values(dataMap)
            .sort((a, b) => a.sortKey - b.sortKey)
            .map(item => ({ name: item.label, value: item.value }));

        return { chartData: finalData, granularity };
    }, [filteredExpenses, startDate, endDate]);

    const axisColor = theme === 'dark' ? '#94a3b8' : '#64748b';
    const gridColor = theme === 'dark' ? '#334155' : '#e2e8f0';
    const tooltipStyle = theme === 'dark'
        ? { backgroundColor: '#1e293b', border: '1px solid #334155', color: '#f8fafc', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.3)' }
        : { backgroundColor: '#fff', border: 'none', color: '#0f172a', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' };

    return (
        <div className="space-y-8">

            <div className="bg-white dark:bg-slate-800 p-4 md:p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">

                <div className="md:hidden">
                    <button
                        onClick={() => setIsFilterOpen(true)}
                        className="w-full flex items-center justify-center gap-2 bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 text-slate-700 dark:text-slate-200 px-4 py-3 rounded-xl font-medium shadow-sm"
                    >
                        <Filter className="w-5 h-5" />
                        <span>Filter Expenses</span>
                    </button>
                </div>


                <div className="hidden md:flex flex-col md:flex-row md:items-end gap-4">
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
                            Apply
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
                

                <div className="mt-4 flex flex-wrap gap-2 overflow-x-auto pb-2 md:pb-0 hide-scrollbar">
                    <button onClick={() => handleQuickFilter('week')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600 whitespace-nowrap">This Week</button>
                    <button onClick={() => handleQuickFilter('month')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600 whitespace-nowrap">This Month</button>
                    <button onClick={() => handleQuickFilter('year')} className="px-4 py-1.5 text-xs font-medium bg-slate-50 dark:bg-slate-700 hover:bg-slate-100 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 rounded-full transition-colors border border-slate-200 dark:border-slate-600 whitespace-nowrap">This Year</button>
                </div>
            </div>


            {isFilterOpen && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="w-full max-w-md bg-white dark:bg-slate-800 rounded-2xl shadow-xl overflow-hidden animate-in zoom-in-95 fade-in duration-200">
                        <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-700 flex items-center justify-between">
                            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Filter Expenses</h3>
                            <button onClick={() => setIsFilterOpen(false)} className="text-slate-400 hover:text-slate-500">
                                <X className="w-5 h-5" />
                            </button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">Start Date</label>
                                <input
                                    type="date"
                                    value={startDate}
                                    onChange={(e) => setStartDate(e.target.value)}
                                    className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 py-2.5 px-3 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">End Date</label>
                                <input
                                    type="date"
                                    value={endDate}
                                    onChange={(e) => setEndDate(e.target.value)}
                                    className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 py-2.5 px-3 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1.5">Category</label>
                                <select
                                    value={selectedCategory}
                                    onChange={(e) => setSelectedCategory(e.target.value)}
                                    className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-primary-500 focus:ring-primary-500 py-2.5 px-3 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                                >
                                    {categories.map(cat => (
                                        <option key={cat} value={cat}>{cat}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="pt-2 flex gap-3">
                                <button
                                    onClick={() => {
                                        handleCustomFilter();
                                        setIsFilterOpen(false);
                                    }}
                                    className="flex-1 bg-primary-600 text-white py-3 rounded-xl font-semibold shadow-lg shadow-primary-500/30 active:scale-95 transition-transform"
                                >
                                    Apply Filters
                                </button>
                                <button
                                    onClick={() => {
                                        setStartDate('');
                                        setEndDate('');
                                        setSelectedCategory('All');
                                        if (onFilterChange) onFilterChange('', '', 'All');
                                        setIsFilterOpen(false);
                                    }}
                                    className="flex-1 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 py-3 rounded-xl font-semibold active:scale-95 transition-transform"
                                >
                                    Reset
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {isLoading ? (
                <div className="flex justify-center items-center h-64">
                    <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
                </div>
            ) : (
                <>

                    <div className="flex overflow-x-auto pb-4 gap-4 -mx-4 px-4 md:mx-0 md:px-0 md:grid md:grid-cols-3 md:gap-6 md:pb-0 snap-x snap-mandatory hide-scrollbar">
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-gradient-to-br from-primary-500 to-primary-700 rounded-2xl p-6 text-white shadow-lg shadow-primary-500/20 flex-shrink-0">
                            <p className="text-primary-100 text-sm font-medium uppercase tracking-wider">Total Spending</p>
                            <h3 className="text-3xl font-bold mt-2 tracking-tight">₹{totalSpending.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
                        </div>
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Transactions</p>
                            <h3 className="text-3xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">{filteredExpenses.length}</h3>
                        </div>
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Average</p>
                            <h3 className="text-3xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">
                                ₹{filteredExpenses.length ? (totalSpending / filteredExpenses.length).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}
                            </h3>
                        </div>
                    </div>


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
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Spending Trend ({granularity})</h3>
                                <div className="h-80">
                                    <ResponsiveContainer width="100%" height="100%">
                                        <BarChart data={chartData}>
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
                            <div className="overflow-x-auto max-h-[500px] overflow-y-auto custom-scrollbar">
                                <table className="min-w-full divide-y divide-slate-100 dark:divide-slate-700 relative">
                                    <thead className="bg-slate-50 dark:bg-slate-700 sticky top-0 z-10">
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
