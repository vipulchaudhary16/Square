import React, { useState } from 'react';
import { ChevronDown, ChevronUp, Search, Filter, ArrowUpDown } from 'lucide-react';

interface Column<T> {
    header: string;
    accessor: keyof T | ((row: T) => React.ReactNode);
    render?: (row: T) => React.ReactNode;
    className?: string;
    tdClassName?: string;
}

interface DataTableProps<T> {
    data: T[];
    columns: Column<T>[];
    searchPlaceholder?: string;
    onSearch?: (query: string) => void;
    currentPage: number;
    totalPages: number;
    onPageChange: (page: number) => void;
    sortConfig?: { key: string; direction: 'asc' | 'desc' } | null;
    onSort?: (key: string) => void;
    onRowClick?: (row: T) => void;
    actions?: React.ReactNode;
    totalRecords?: number;
    isLoading?: boolean;
}

export function DataTable<T extends { id: string | number }>({
    data,
    columns,
    searchPlaceholder = "Search...",
    currentPage,
    totalPages,
    onPageChange,
    sortConfig,
    onSort,
    onRowClick,
    actions,
    totalRecords,
    isLoading = false,
}: DataTableProps<T>) {
    const [searchQuery, setSearchQuery] = useState('');

    
    const filteredData = React.useMemo(() => {
        if (!searchQuery) return data;
        return data.filter((row) =>
            Object.values(row as any).some((value) =>
                String(value).toLowerCase().includes(searchQuery.toLowerCase())
            )
        );
    }, [data, searchQuery]);

    
    
    const sortedData = filteredData;

    const handleSort = (key: string) => {
        if (onSort) {
            onSort(key);
        }
    };

    return (
        <div className="space-y-4">
            {}
            <div className="relative z-20 flex flex-col sm:flex-row gap-4 justify-between items-center bg-white/50 dark:bg-slate-800/50 backdrop-blur-sm p-4 rounded-2xl border border-slate-200 dark:border-slate-700">
                <div className="flex items-center gap-4 w-full sm:w-auto">
                    <div className="relative w-full sm:w-96">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                            type="text"
                            placeholder={searchPlaceholder}
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl text-sm focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition-all"
                        />
                    </div>
                    {actions}
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
                    <Filter className="w-4 h-4" />
                    <span>{totalRecords !== undefined ? totalRecords : sortedData.length} records found</span>
                </div>
            </div>

            {}
            <div className="relative z-10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md rounded-2xl border border-slate-200 dark:border-slate-700 overflow-hidden shadow-sm">
                {isLoading && (
                    <div className="absolute inset-0 z-50 bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm flex items-center justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
                    </div>
                )}
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-slate-50/50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                                {columns.map((col, idx) => (
                                    <th
                                        key={idx}
                                        className={`px-6 py-4 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors group ${col.className || ''}`}
                                        onClick={() => typeof col.accessor === 'string' && handleSort(col.accessor as string)}
                                        title={typeof col.accessor === 'string' ? "Click to sort" : undefined}
                                    >
                                        <div className="flex items-center gap-2">
                                            {col.header}
                                            {typeof col.accessor === 'string' && (
                                                <span className="inline-flex flex-col justify-center h-4 w-4">
                                                    {sortConfig?.key === col.accessor ? (
                                                        sortConfig.direction === 'asc' ? (
                                                            <ChevronUp className="w-3 h-3 text-primary-600 dark:text-primary-400" />
                                                        ) : (
                                                            <ChevronDown className="w-3 h-3 text-primary-600 dark:text-primary-400" />
                                                        )
                                                    ) : (
                                                        <ArrowUpDown className="w-3 h-3 text-slate-300 dark:text-slate-600 opacity-0 group-hover:opacity-100 transition-opacity" />
                                                    )}
                                                </span>
                                            )}
                                        </div>
                                    </th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                            {sortedData.map((row) => (
                                <tr
                                    key={row.id}
                                    onClick={() => onRowClick && onRowClick(row)}
                                    className={`transition-colors group ${onRowClick ? 'cursor-pointer hover:bg-slate-50/80 dark:hover:bg-slate-800/50' : ''}`}
                                >
                                    {columns.map((col, colIdx) => (
                                        <td key={colIdx} className={`px-6 py-4 text-sm text-slate-700 dark:text-slate-300 whitespace-nowrap ${col.tdClassName || ''}`}>
                                            {col.render ? col.render(row) : (
                                                typeof col.accessor === 'function'
                                                    ? col.accessor(row)
                                                    : (row[col.accessor] as React.ReactNode)
                                            )}
                                        </td>
                                    ))}
                                </tr>
                            ))}
                            {sortedData.length === 0 && (
                                <tr>
                                    <td colSpan={columns.length} className="px-6 py-12 text-center text-slate-500 dark:text-slate-400">
                                        No results found
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>

                {}
                {totalPages > 1 && (
                    <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-700 flex items-center justify-between bg-slate-50/30 dark:bg-slate-800/30">
                        <button
                            onClick={() => onPageChange(Math.max(1, currentPage - 1))}
                            disabled={currentPage === 1 || isLoading}
                            className="px-3 py-1 text-sm font-medium text-slate-600 dark:text-slate-400 disabled:opacity-50 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                        >
                            Previous
                        </button>
                        <span className="text-sm text-slate-500 dark:text-slate-400">
                            Page {currentPage} of {totalPages}
                        </span>
                        <button
                            onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
                            disabled={currentPage === totalPages || isLoading}
                            className="px-3 py-1 text-sm font-medium text-slate-600 dark:text-slate-400 disabled:opacity-50 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                        >
                            Next
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}
