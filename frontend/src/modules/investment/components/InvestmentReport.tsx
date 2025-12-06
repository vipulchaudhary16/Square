import React, { useState, useMemo } from 'react';
import { Investment } from '../../../api/finance';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip as RechartsTooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid, Legend } from 'recharts';
import { PieChart as PieIcon, Table as TableIcon } from 'lucide-react';
import { useTheme } from '../../../context/ThemeContext';

interface InvestmentReportProps {
    investments: Investment[];
    isLoading: boolean;
}

const COLORS = ['#3B82F6', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981', '#6366F1'];

export const InvestmentReport: React.FC<InvestmentReportProps> = ({ investments, isLoading }) => {
    const { theme } = useTheme();
    const [filterType, setFilterType] = useState<string>('All');
    const [viewMode, setViewMode] = useState<'charts' | 'table'>('charts');

    const filteredInvestments = useMemo(() => {
        if (filterType === 'All') return investments;
        return investments.filter(inv => inv.type === filterType);
    }, [investments, filterType]);

    const totalInvested = useMemo(() => filteredInvestments.reduce((sum, i) => sum + i.amount_invested, 0), [filteredInvestments]);
    const currentTotalValue = useMemo(() => filteredInvestments.reduce((sum, i) => sum + i.current_value, 0), [filteredInvestments]);
    const totalProfitLoss = currentTotalValue - totalInvested;
    const roi = totalInvested > 0 ? (totalProfitLoss / totalInvested) * 100 : 0;

    const typeData = useMemo(() => {
        const data: Record<string, number> = {};
        filteredInvestments.forEach(i => {
            data[i.type] = (data[i.type] || 0) + i.current_value;
        });
        return Object.entries(data).map(([name, value]) => ({ name, value }));
    }, [filteredInvestments]);

    const growthData = useMemo(() => {
        return filteredInvestments.map(inv => ({
            name: inv.name,
            invested: inv.amount_invested,
            current: inv.current_value
        }));
    }, [filteredInvestments]);

    const axisColor = theme === 'dark' ? '#94a3b8' : '#64748b';
    const gridColor = theme === 'dark' ? '#334155' : '#e2e8f0';
    const tooltipStyle = theme === 'dark'
        ? { backgroundColor: '#1e293b', border: '1px solid #334155', color: '#f8fafc', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.3)' }
        : { backgroundColor: '#fff', border: 'none', color: '#0f172a', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' };

    return (
        <div className="space-y-8">

            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                <div className="flex items-center gap-4">
                    <div className="w-full sm:w-64">
                        <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wider">Investment Type</label>
                        <select
                            value={filterType}
                            onChange={(e) => setFilterType(e.target.value)}
                            className="w-full rounded-xl border-slate-200 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm py-2.5 px-3 transition-all bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                        >
                            <option value="All">All Types</option>
                            <option value="STOCK">Stock</option>
                            <option value="CRYPTO">Crypto</option>
                            <option value="MUTUAL_FUND">Mutual Fund</option>
                            <option value="REAL_ESTATE">Real Estate</option>
                            <option value="OTHER">Other</option>
                        </select>
                    </div>
                    <button
                        onClick={() => setFilterType('All')}
                        className="bg-white dark:bg-slate-700 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-600 px-5 py-2.5 rounded-xl text-sm font-semibold hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors"
                    >
                        Clear
                    </button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center items-center h-64">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                </div>
            ) : (
                <>

                    <div className="flex overflow-x-auto pb-4 gap-4 -mx-4 px-4 md:mx-0 md:px-0 md:grid md:grid-cols-4 md:gap-6 md:pb-0 snap-x snap-mandatory hide-scrollbar">
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Total Invested</p>
                            <h3 className="text-2xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">₹{totalInvested.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
                        </div>
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">Current Value</p>
                            <h3 className="text-2xl font-bold mt-2 text-slate-900 dark:text-white tracking-tight">₹{currentTotalValue.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h3>
                        </div>
                        <div className={`min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0 ${totalProfitLoss >= 0 ? 'bg-green-50 dark:bg-green-900/20 border-green-100 dark:border-green-800' : 'bg-red-50 dark:bg-red-900/20 border-red-100 dark:border-red-800'}`}>
                            <p className={`text-sm font-medium uppercase tracking-wider ${totalProfitLoss >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>Total P/L</p>
                            <h3 className={`text-2xl font-bold mt-2 tracking-tight ${totalProfitLoss >= 0 ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'}`}>
                                {totalProfitLoss >= 0 ? '+' : ''}₹{totalProfitLoss.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                            </h3>
                        </div>
                        <div className="min-w-[85vw] sm:min-w-[300px] md:min-w-0 snap-center bg-white dark:bg-slate-800 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-slate-700 flex-shrink-0">
                            <p className="text-slate-500 dark:text-slate-400 text-sm font-medium uppercase tracking-wider">ROI</p>
                            <h3 className={`text-2xl font-bold mt-2 tracking-tight ${roi >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                                {roi.toFixed(2)}%
                            </h3>
                        </div>
                    </div>


                    <div className="flex justify-between items-center">
                        <h2 className="text-xl font-bold text-slate-800 dark:text-white">Portfolio Analysis</h2>
                        <div className="flex bg-slate-100 dark:bg-slate-700 p-1 rounded-xl">
                            <button
                                onClick={() => setViewMode('charts')}
                                className={`p-2 rounded-lg transition-all ${viewMode === 'charts' ? 'bg-white dark:bg-slate-600 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
                            >
                                <PieIcon className="w-5 h-5" />
                            </button>
                            <button
                                onClick={() => setViewMode('table')}
                                className={`p-2 rounded-lg transition-all ${viewMode === 'table' ? 'bg-white dark:bg-slate-600 text-blue-600 dark:text-blue-400 shadow-sm' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
                            >
                                <TableIcon className="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    {viewMode === 'charts' ? (
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">

                            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Portfolio Allocation</h3>
                                <div className="flex flex-col sm:flex-row items-center gap-8">
                                    <div className="h-64 w-full sm:w-1/2">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <PieChart>
                                                <Pie
                                                    data={typeData}
                                                    cx="50%"
                                                    cy="50%"
                                                    innerRadius={60}
                                                    outerRadius={80}
                                                    paddingAngle={5}
                                                    dataKey="value"
                                                >
                                                    {typeData.map((_, index) => (
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
                                            {typeData.map((entry, index) => (
                                                <li key={index} className="flex justify-between items-center text-sm">
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


                            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-100 dark:border-slate-700">
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Investment Performance</h3>
                                <div className="h-80">
                                    <ResponsiveContainer width="100%" height="100%">
                                        <BarChart data={growthData}>
                                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                                            <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: axisColor, fontSize: 12 }} dy={10} />
                                            <YAxis axisLine={false} tickLine={false} tick={{ fill: axisColor, fontSize: 12 }} />
                                            <RechartsTooltip
                                                cursor={{ fill: theme === 'dark' ? '#334155' : '#f1f5f9' }}
                                                contentStyle={tooltipStyle}
                                            />
                                            <Legend wrapperStyle={{ color: theme === 'dark' ? '#cbd5e1' : '#475569' }} />
                                            <Bar dataKey="invested" name="Invested" fill="#94a3b8" radius={[4, 4, 0, 0]} />
                                            <Bar dataKey="current" name="Current Value" fill="#3B82F6" radius={[4, 4, 0, 0]} />
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
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Name</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Type</th>
                                            <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Invested</th>
                                            <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Current Value</th>
                                            <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">P/L</th>
                                        </tr>
                                    </thead>
                                    <tbody className="bg-white dark:bg-slate-800 divide-y divide-slate-100 dark:divide-slate-700">
                                        {filteredInvestments.map((inv) => {
                                            const pl = inv.current_value - inv.amount_invested;
                                            return (
                                                <tr key={inv.id} className="hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900 dark:text-white">
                                                        {inv.name}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">
                                                        <span className="px-2.5 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-600">
                                                            {inv.type}
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400 text-right">
                                                        ₹{inv.amount_invested.toFixed(2)}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900 dark:text-white text-right font-bold">
                                                        ₹{inv.current_value.toFixed(2)}
                                                    </td>
                                                    <td className={`px-6 py-4 whitespace-nowrap text-sm text-right font-bold ${pl >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                                                        {pl >= 0 ? '+' : ''}₹{pl.toFixed(2)}
                                                    </td>
                                                </tr>
                                            );
                                        })}
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
