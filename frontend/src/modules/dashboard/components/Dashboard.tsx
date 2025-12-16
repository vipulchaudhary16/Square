import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ExpenseCard } from '../../expense/components/ExpenseCard';
// Removed: AddExpenseForm, generateInsights, isAIEnabled imports
import { getDashboardData, DashboardData } from '../../../api/dashboard';
import { useSession } from '../../../hooks/useSession';
import { TrendingUp, ArrowLeftRight, Wallet } from 'lucide-react';
import { EmptyState } from '../../common/components/ui/EmptyState';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export const Dashboard: React.FC = () => {
    const { user } = useSession();
    const navigate = useNavigate();
    const currentUserId = user?.id || "";

    const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
    const [loading, setLoading] = useState(true);

    const fetchDashboardData = async () => {
        try {
            const data = await getDashboardData();
            setDashboardData(data);
        } catch (error) {
            console.error("Error fetching dashboard data", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDashboardData();
    }, []);

    if (loading || !dashboardData) {
        return (
            <div className="flex justify-center items-center min-h-screen">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    const { total_expenses, total_income, total_invested, recent_expenses, lent_amount, borrowed_amount, expense_graph } = dashboardData;
    const netBalance = total_income - total_expenses;

    const StatCard = ({ title, amount, icon: Icon, color, subtext }: any) => (
        <div className="glass-card p-6 hover:shadow-2xl border border-white/40 dark:border-slate-700/50 h-full flex flex-col justify-between">
            <div>
                <div className="flex items-center gap-3 mb-4">
                    <div className={`p-2 rounded-lg ${color} bg-opacity-20 backdrop-blur-sm`}>
                        <Icon className="w-5 h-5" />
                    </div>
                    <h3 className="text-slate-500 dark:text-slate-400 text-sm font-medium">{title}</h3>
                </div>
                <div className="text-3xl font-bold text-slate-800 dark:text-white tracking-tight mb-2">
                    ₹{amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
            </div>
            {subtext && <p className="text-xs font-medium text-slate-400 dark:text-slate-500">{subtext}</p>}
        </div>
    );

    return (
        <div className="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8">
            {/* Stats Grid */}
            <div className="flex overflow-x-auto pb-4 gap-4 -mx-4 px-4 md:mx-0 md:px-0 md:grid md:grid-cols-2 lg:grid-cols-4 md:gap-6 md:pb-0 mb-8 snap-x snap-mandatory hide-scrollbar">
                <div className="min-w-[75vw] sm:min-w-[300px] md:min-w-0 snap-center bg-gradient-to-br from-primary-600 to-primary-800 rounded-2xl p-6 text-white shadow-lg shadow-primary-500/20 relative overflow-hidden flex-shrink-0 h-full flex flex-col justify-between">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full blur-2xl -mr-8 -mt-8 pointer-events-none"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-3 mb-4">
                            <div className="p-2 bg-white/20 rounded-lg backdrop-blur-sm">
                                <Wallet className="w-5 h-5 text-white" />
                            </div>
                            <span className="text-primary-100 font-medium">Net Balance</span>
                        </div>
                        <div className="text-3xl font-bold mb-2">
                            ₹{netBalance.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </div>
                        <div className="flex items-center gap-2 text-sm text-primary-200">
                            <span>Income: ₹{total_income.toLocaleString()}</span>
                            <span>•</span>
                            <span>Exp: ₹{total_expenses.toLocaleString()}</span>
                        </div>
                    </div>
                </div>

                <div className="min-w-[75vw] sm:min-w-[300px] md:min-w-0 snap-center flex-shrink-0">
                    <StatCard
                        title="Total Investments"
                        amount={total_invested}
                        icon={TrendingUp}
                        color="bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400"
                        subtext="Active investments"
                    />
                </div>

                <div className="min-w-[75vw] sm:min-w-[300px] md:min-w-0 snap-center flex-shrink-0">
                    <StatCard
                        title="Money Lent"
                        amount={lent_amount}
                        icon={ArrowLeftRight}
                        color="bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400"
                        subtext="To be received"
                    />
                </div>

                <div className="min-w-[75vw] sm:min-w-[300px] md:min-w-0 snap-center flex-shrink-0">
                    <StatCard
                        title="Money Borrowed"
                        amount={borrowed_amount}
                        icon={ArrowLeftRight}
                        color="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400"
                        subtext="To be paid"
                    />
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-6">
                    <div className="glass-card p-6 border border-white/40 dark:border-slate-700/50">
                        <div className="mb-6">
                            <h2 className="text-xl font-bold text-slate-800 dark:text-white mb-2">Expense Trends</h2>
                            <div className="flex items-center gap-4">
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-[#8884d8]"></div>
                                    <span className="text-xs text-slate-500 dark:text-slate-400">Current Month</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-[#82ca9d]"></div>
                                    <span className="text-xs text-slate-500 dark:text-slate-400">Last Month</span>
                                </div>
                            </div>
                        </div>
                        <div className="h-[300px] w-full">
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={expense_graph}>
                                    <defs>
                                        <linearGradient id="colorCurrent" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                                            <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                                        </linearGradient>
                                        <linearGradient id="colorLast" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#82ca9d" stopOpacity={0.8}/>
                                            <stop offset="95%" stopColor="#82ca9d" stopOpacity={0}/>
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} strokeOpacity={0.1} />
                                    <XAxis 
                                        dataKey="day" 
                                        axisLine={false} 
                                        tickLine={false} 
                                        tick={{ fontSize: 12 }} 
                                        stroke="#94a3b8" 
                                    />
                                    <YAxis 
                                        axisLine={false} 
                                        tickLine={false} 
                                        tick={{ fontSize: 12 }} 
                                        stroke="#94a3b8" 
                                        tickFormatter={(value) => `₹${value}`}
                                    />
                                    <Tooltip 
                                        contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }}
                                        formatter={(value: number) => [`₹${value}`, 'Amount']}
                                        labelFormatter={(label) => `Day ${label}`}
                                    />
                                    <Area 
                                        type="monotone" 
                                        dataKey="current_month" 
                                        stroke="#8884d8" 
                                        fillOpacity={1} 
                                        fill="url(#colorCurrent)" 
                                        name="Current Month"
                                    />
                                    <Area 
                                        type="monotone" 
                                        dataKey="last_month" 
                                        stroke="#82ca9d" 
                                        fillOpacity={1} 
                                        fill="url(#colorLast)" 
                                        name="Last Month"
                                    />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </div>
                </div>

                {/* Recent Transactions */}
                <div className="lg:col-span-1">
                     <div className="flex items-center justify-between mb-4">
                        <h2 className="text-xl font-bold text-slate-800 dark:text-white">Recent Transactions</h2>
                        <button
                            onClick={() => navigate('/reports')}
                            className="text-sm font-semibold text-primary-600 hover:text-primary-700 hover:bg-primary-50 dark:hover:bg-primary-900/20 px-3 py-1.5 rounded-lg transition-colors"
                        >
                            View All
                        </button>
                    </div>

                    <div className="space-y-3">
                        {recent_expenses.length === 0 ? (
                            <EmptyState
                                title="No expenses yet"
                                description="Add your first expense to get started"
                            />
                        ) : (
                            recent_expenses.map((exp: any) => (
                                <ExpenseCard key={exp.id} expense={exp} currentUserId={currentUserId} />
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};
