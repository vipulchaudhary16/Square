import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { DataTable } from '../components/DataTable';
import { getExpenses, Expense } from '../../../api/expenses';
import { getIncomes, getInvestments, getLoans, Income, Investment, Loan } from '../../../api/finance';
import { LayoutDashboard, DollarSign, TrendingUp, ArrowLeftRight, Filter, ChevronRight } from 'lucide-react';

export const TransactionsPage: React.FC = () => {
    const [activeTab, setActiveTab] = useState<'expenses' | 'income' | 'investments' | 'loans'>('expenses');
    const [loading, setLoading] = useState(false);

    
    const [page, setPage] = useState(1);
    const [limit, setLimit] = useState(window.innerWidth < 768 ? 5 : 10);
    const [total, setTotal] = useState(0);

    
    const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>({ key: 'date', direction: 'desc' });

    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [incomes, setIncomes] = useState<Income[]>([]);
    const [investments, setInvestments] = useState<Investment[]>([]);
    const [loans, setLoans] = useState<Loan[]>([]);

    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    useEffect(() => {
        const handleResize = () => {
            setLimit(window.innerWidth < 768 ? 5 : 10);
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    useEffect(() => {
        setPage(1); 
        setSortConfig({ key: 'date', direction: 'desc' }); 
    }, [activeTab]);

    useEffect(() => {
        fetchData();
    }, [activeTab, page, sortConfig, limit, startDate, endDate]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const sortBy = sortConfig?.key;
            const sortOrder = sortConfig?.direction;

            const ensureId = (item: any) => ({ ...item, id: item.id || item._id || item.ID });

            if (activeTab === 'expenses') {
                const response = await getExpenses(startDate, endDate, undefined, undefined, page, limit, sortBy, sortOrder);
                if (Array.isArray(response)) {
                    setExpenses(response.map(ensureId));
                    setTotal(response.length);
                } else {
                    setExpenses(response.data.map(ensureId));
                    setTotal(response.total);
                }
            } else if (activeTab === 'income') {
                const response = await getIncomes(page, limit, sortBy, sortOrder, startDate, endDate);
                if (Array.isArray(response)) {
                    setIncomes(response.map(ensureId));
                    setTotal(response.length);
                } else {
                    setIncomes(response.data.map(ensureId));
                    setTotal(response.total);
                }
            } else if (activeTab === 'investments') {
                const response = await getInvestments(page, limit, sortBy, sortOrder, startDate, endDate);
                if (Array.isArray(response)) {
                    setInvestments(response.map(ensureId));
                    setTotal(response.length);
                } else {
                    setInvestments(response.data.map(ensureId));
                    setTotal(response.total);
                }
            } else if (activeTab === 'loans') {
                const response = await getLoans(page, limit, sortBy, sortOrder, startDate, endDate);
                if (Array.isArray(response)) {
                    setLoans(response.map(ensureId));
                    setTotal(response.length);
                } else {
                    setLoans(response.data.map(ensureId));
                    setTotal(response.total);
                }
            }
        } catch (error) {
            console.error("Error fetching data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSort = (key: string) => {
        let direction: 'asc' | 'desc' = 'desc'; 
        if (sortConfig && sortConfig.key === key && sortConfig.direction === 'desc') {
            direction = 'asc';
        }
        setSortConfig({ key, direction });
    };

    const expenseColumns: any[] = [
        { header: 'Date', accessor: 'date', render: (row: Expense) => new Date(row.date).toLocaleDateString() },
        { header: 'Description', accessor: 'description' },
        {
            header: 'Category', accessor: 'category', render: (row: Expense) => (
                <span className="px-2 py-1 rounded-full text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                    {row.category}
                </span>
            )
        },
        {
            header: 'Amount', accessor: 'amount', render: (row: Expense) => (
                <span className="font-bold text-red-600 dark:text-red-400">-₹{row.amount.toFixed(2)}</span>
            )
        },
        {
            header: '',
            accessor: 'actions',
            className: 'w-10 sticky right-0 bg-slate-50 dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            tdClassName: 'sticky right-0 bg-white dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            render: () => (
                <ChevronRight className="w-5 h-5 text-slate-400" />
            )
        },
    ];

    const incomeColumns: any[] = [
        { header: 'Date', accessor: 'date', render: (row: Income) => new Date(row.date).toLocaleDateString() },
        { header: 'Source', accessor: 'source' },
        { header: 'Description', accessor: 'description' },
        {
            header: 'Amount', accessor: 'amount', render: (row: Income) => (
                <span className="font-bold text-green-600 dark:text-green-400">+₹{row.amount.toFixed(2)}</span>
            )
        },
        {
            header: '',
            accessor: 'actions',
            className: 'w-10 sticky right-0 bg-slate-50 dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            tdClassName: 'sticky right-0 bg-white dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            render: () => (
                <ChevronRight className="w-5 h-5 text-slate-400" />
            )
        },
    ];

    const investmentColumns: any[] = [
        { header: 'Date', accessor: 'date', render: (row: Investment) => new Date(row.date).toLocaleDateString() },
        { header: 'Type', accessor: 'type' },
        { header: 'Description', accessor: 'description' },
        {
            header: 'Amount', accessor: 'amount_invested', render: (row: Investment) => (
                <span className="font-bold text-blue-600 dark:text-blue-400">₹{row.amount_invested.toFixed(2)}</span>
            )
        },
        {
            header: 'Current Value', accessor: 'current_value', render: (row: Investment) => (
                <span className={`font-bold ${row.current_value >= row.amount_invested ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                    ₹{row.current_value.toFixed(2)}
                </span>
            )
        },
        {
            header: '',
            accessor: 'actions',
            className: 'w-10 sticky right-0 bg-slate-50 dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            tdClassName: 'sticky right-0 bg-white dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            render: () => (
                <ChevronRight className="w-5 h-5 text-slate-400" />
            )
        },
    ];

    const loanColumns: any[] = [
        { header: 'Date', accessor: 'date', render: (row: Loan) => new Date(row.date).toLocaleDateString() },
        { header: 'Person', accessor: 'counterparty_name' },
        {
            header: 'Type', accessor: 'type', render: (row: Loan) => (
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${row.type === 'LENT'
                    ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400'
                    : 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                    }`}>
                    {row.type}
                </span>
            )
        },
        {
            header: 'Amount', accessor: 'amount', render: (row: Loan) => (
                <span className="font-bold text-slate-800 dark:text-white">₹{row.amount.toFixed(2)}</span>
            )
        },
        {
            header: 'Status', accessor: 'status', render: (row: Loan) => (
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${row.status === 'PAID'
                    ? 'bg-slate-100 dark:bg-slate-800 text-slate-500'
                    : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400'
                    }`}>
                    {row.status}
                </span>
            )
        },
        {
            header: '',
            accessor: 'actions',
            className: 'w-10 sticky right-0 bg-slate-50 dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            tdClassName: 'sticky right-0 bg-white dark:bg-slate-800 shadow-[-4px_0_8px_-4px_rgba(0,0,0,0.1)]',
            render: () => (
                <ChevronRight className="w-5 h-5 text-slate-400" />
            )
        },
    ];

    const tabs = [
        { id: 'expenses', label: 'Expenses', icon: LayoutDashboard },
        { id: 'income', label: 'Income', icon: DollarSign },
        { id: 'investments', label: 'Investments', icon: TrendingUp },
        { id: 'loans', label: 'Loans', icon: ArrowLeftRight },
    ];

    const totalPages = Math.ceil(total / limit);

    const navigate = useNavigate();
    const [isFilterOpen, setIsFilterOpen] = useState(false);
    const filterRef = React.useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (filterRef.current && !filterRef.current.contains(event.target as Node)) {
                setIsFilterOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const clearFilters = () => {
        setStartDate('');
        setEndDate('');
        setIsFilterOpen(false);
    };

    const handleRowClick = (row: any) => {
        if (activeTab === 'expenses') {
            navigate(`/expenses/${row.id}`);
        } else if (activeTab === 'income') {
            navigate(`/income/${row.id}`);
        } else if (activeTab === 'investments') {
            navigate(`/investments/${row.id}`);
        } else if (activeTab === 'loans') {
            navigate(`/loans/${row.id}`);
        }
    };

    const FilterPopover = (
        <div className="relative" ref={filterRef}>
            <button
                onClick={() => setIsFilterOpen(!isFilterOpen)}
                className={`flex items-center gap-2 px-4 py-2 border rounded-lg text-sm font-medium transition-colors shadow-sm ${isFilterOpen || startDate || endDate
                    ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-300'
                    : 'bg-white dark:bg-slate-800 border-gray-300 dark:border-slate-700 text-gray-700 dark:text-slate-200 hover:bg-gray-50 dark:hover:bg-slate-700'
                    }`}
            >
                <Filter className="w-4 h-4" />
                Filter
                {(startDate || endDate) && (
                    <span className="ml-1 flex h-2 w-2 relative">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
                    </span>
                )}
            </button>

            {isFilterOpen && (
                <div className="absolute right-0 mt-2 w-72 bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-gray-200 dark:border-slate-700 p-4 z-50 animate-in fade-in zoom-in-95 duration-200">
                    <div className="space-y-4">
                        <div>
                            <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">Date Range</h3>
                            <div className="space-y-3">
                                <div>
                                    <label className="block text-xs text-gray-500 dark:text-slate-400 mb-1">Start Date</label>
                                    <input
                                        type="date"
                                        value={startDate}
                                        onChange={(e) => setStartDate(e.target.value)}
                                        className="w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-900 text-gray-900 dark:text-white"
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs text-gray-500 dark:text-slate-400 mb-1">End Date</label>
                                    <input
                                        type="date"
                                        value={endDate}
                                        onChange={(e) => setEndDate(e.target.value)}
                                        className="w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-900 text-gray-900 dark:text-white"
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="pt-3 border-t border-gray-100 dark:border-slate-700 flex gap-2">
                            <button
                                onClick={clearFilters}
                                className="flex-1 px-3 py-1.5 border border-gray-300 dark:border-slate-600 rounded-md text-xs font-medium text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
                            >
                                Clear
                            </button>
                            <button
                                onClick={() => setIsFilterOpen(false)}
                                className="flex-1 px-3 py-1.5 bg-blue-600 text-white rounded-md text-xs font-medium hover:bg-blue-700 transition-colors"
                            >
                                Done
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Transactions</h1>
                    <p className="text-slate-500 dark:text-slate-400 mt-1">View and manage all your financial records in one place.</p>
                </div>


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


            <div className="hidden md:flex space-x-1 bg-slate-100 dark:bg-slate-800/50 p-1 rounded-xl w-full md:w-fit overflow-x-auto">
                {tabs.map((tab) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === tab.id;
                    return (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id as any)}
                            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${isActive
                                ? 'bg-white dark:bg-slate-700 text-primary-600 dark:text-primary-400 shadow-sm'
                                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/50'
                                }`}
                        >
                            <Icon size={16} />
                            {tab.label}
                        </button>
                    );
                })}
            </div>


            {activeTab === 'expenses' && (
                <DataTable
                    data={expenses}
                    columns={expenseColumns}
                    currentPage={page}
                    totalPages={totalPages}
                    onPageChange={setPage}
                    sortConfig={sortConfig}
                    onSort={handleSort}
                    onRowClick={handleRowClick}
                    actions={FilterPopover}
                    totalRecords={total}
                    isLoading={loading}
                />
            )}
            {activeTab === 'income' && (
                <DataTable
                    data={incomes}
                    columns={incomeColumns}
                    currentPage={page}
                    totalPages={totalPages}
                    onPageChange={setPage}
                    sortConfig={sortConfig}
                    onSort={handleSort}
                    onRowClick={handleRowClick}
                    actions={FilterPopover}
                    totalRecords={total}
                    isLoading={loading}
                />
            )}
            {activeTab === 'investments' && (
                <DataTable
                    data={investments}
                    columns={investmentColumns}
                    currentPage={page}
                    totalPages={totalPages}
                    onPageChange={setPage}
                    sortConfig={sortConfig}
                    onSort={handleSort}
                    onRowClick={handleRowClick}
                    actions={FilterPopover}
                    totalRecords={total}
                    isLoading={loading}
                />
            )}
            {activeTab === 'loans' && (
                <DataTable
                    data={loans}
                    columns={loanColumns}
                    currentPage={page}
                    totalPages={totalPages}
                    onPageChange={setPage}
                    sortConfig={sortConfig}
                    onSort={handleSort}
                    onRowClick={handleRowClick}
                    actions={FilterPopover}
                    totalRecords={total}
                    isLoading={loading}
                />
            )}
        </div>
    );
};
