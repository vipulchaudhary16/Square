import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ExpenseCard } from '../../expense/components/ExpenseCard';
import { AddExpenseForm } from '../../expense/components/AddExpenseForm';
import { getDashboardData } from '../../../api/dashboard';
import { useSession } from '../../../hooks/useSession';
import { TrendingUp, ArrowLeftRight, Wallet, Sparkles, Loader2, Plus } from 'lucide-react';
import { generateInsights, isAIEnabled } from '../../../services/ai';
import { Modal } from '../../common/components/ui/Modal';

export const Dashboard: React.FC = () => {
    const { user } = useSession();
    const navigate = useNavigate();
    const currentUserId = user?.id || "";

    const [dashboardData, setDashboardData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [insights, setInsights] = useState<string[]>([]);
    const [loadingInsights, setLoadingInsights] = useState(false);
    const [isAddExpenseModalOpen, setIsAddExpenseModalOpen] = useState(false);

    const handleGenerateInsights = async () => {
        if (!dashboardData?.recent_expenses) return;
        setLoadingInsights(true);
        const results = await generateInsights(dashboardData.recent_expenses);
        setInsights(results);
        setLoadingInsights(false);
    };

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

    const { total_expenses, total_income, total_invested, recent_expenses, lent_amount, borrowed_amount } = dashboardData;
    const netBalance = total_income - total_expenses;

    const StatCard = ({ title, amount, icon: Icon, color, subtext }: any) => (
        <div className="glass-card p-6 hover:shadow-2xl border border-white/40 dark:border-slate-700/50">
            <div className="flex items-center gap-3 mb-4">
                <div className={`p - 2 rounded - lg ${color} bg - opacity - 20 backdrop - blur - sm`}>
                    <Icon className="w-5 h-5" />
                </div>
                <h3 className="text-slate-500 dark:text-slate-400 text-sm font-medium">{title}</h3>
            </div>
            <div className="text-3xl font-bold text-slate-800 dark:text-white tracking-tight mb-2">
                ₹{amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            {subtext && <p className="text-xs font-medium text-slate-400 dark:text-slate-500">{subtext}</p>}
        </div>
    );

    return (
        <div className="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8">
            {}
            <div className="flex overflow-x-auto pb-4 gap-4 -mx-4 px-4 md:mx-0 md:px-0 md:grid md:grid-cols-2 lg:grid-cols-4 md:gap-6 md:pb-0 mb-8 snap-x snap-mandatory hide-scrollbar">
                <div className="min-w-[75vw] sm:min-w-[300px] md:min-w-0 snap-center bg-gradient-to-br from-primary-600 to-primary-800 rounded-2xl p-6 text-white shadow-lg shadow-primary-500/20 relative overflow-hidden flex-shrink-0">
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



            <div className="grid grid-cols-1 lg:col-span-2 lg:grid-cols-3 gap-8">
                {}
                <div className="lg:col-span-2">
                    <div className="flex items-center justify-between mb-6">
                        <h2 className="text-xl font-bold text-slate-800 dark:text-white">Recent Expenses</h2>
                        <button
                            onClick={() => navigate('/reports')}
                            className="text-sm font-semibold text-primary-600 hover:text-primary-700 hover:bg-primary-50 dark:hover:bg-primary-900/20 px-3 py-1.5 rounded-lg transition-colors"
                        >
                            View All
                        </button>
                    </div>

                    <div className="space-y-3">
                        {recent_expenses.length === 0 ? (
                            <div className="text-center py-12 bg-white dark:bg-slate-800 rounded-2xl border border-slate-100 dark:border-slate-700 border-dashed">
                                <p className="text-slate-500 dark:text-slate-400 font-medium">No expenses yet</p>
                                <p className="text-slate-400 dark:text-slate-500 text-sm mt-1">Add your first expense to get started</p>
                            </div>
                        ) : (
                            recent_expenses.map((exp: any) => (
                                <ExpenseCard key={exp.id} expense={exp} currentUserId={currentUserId} />
                            ))
                        )}
                    </div>
                </div>

                {}
                <div className="hidden lg:col-span-1 lg:block">
                    <div className="glass-card p-6 sticky top-24 border border-white/40 dark:border-slate-700/50">
                        <h2 className="text-xl font-bold text-slate-800 dark:text-white mb-6 flex items-center gap-2">
                            <span className="w-1 h-6 bg-primary-500 rounded-full"></span>
                            Quick Add
                        </h2>
                        <AddExpenseForm onSuccess={() => {
                            fetchDashboardData();
                        }} />
                    </div>
                </div>

                {}
                {isAIEnabled() && (
                    <div className="mb-8 bg-gradient-to-r from-purple-50 to-indigo-50 dark:from-purple-900/20 dark:to-indigo-900/20 rounded-2xl p-4 md:p-6 border border-purple-100 dark:border-purple-800">
                        <div className="flex flex-col items-start gap-4 md:flex-row md:items-center md:justify-between mb-4">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-white dark:bg-slate-800 rounded-lg shadow-sm">
                                    <Sparkles className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                                </div>
                                <h2 className="text-lg font-bold text-slate-800 dark:text-white">AI Financial Insights</h2>
                            </div>
                            <button
                                onClick={handleGenerateInsights}
                                disabled={loadingInsights}
                                className="w-full md:w-auto text-sm font-medium text-purple-700 dark:text-purple-300 hover:bg-white/50 dark:hover:bg-slate-800/50 px-4 py-2 rounded-lg transition-colors flex items-center justify-center gap-2"
                            >
                                {loadingInsights ? (
                                    <>
                                        <Loader2 className="w-4 h-4 animate-spin" /> Analyzing...
                                    </>
                                ) : (
                                    <>
                                        <Sparkles className="w-4 h-4" /> Generate Insights
                                    </>
                                )}
                            </button>
                        </div>

                        {insights.length > 0 ? (
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                                {insights.map((insight, index) => (
                                    <div key={index} className="bg-white/60 dark:bg-slate-800/60 backdrop-blur-sm p-4 rounded-xl border border-white/20 dark:border-slate-700/50 shadow-sm">
                                        <p className="text-slate-700 dark:text-slate-300 text-sm leading-relaxed">{insight}</p>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <p className="text-slate-500 dark:text-slate-400 text-sm text-center py-4">
                                Click "Generate Insights" to get personalized financial advice based on your recent activity.
                            </p>
                        )}
                    </div>
                )}
            </div>

            {}
            <button
                onClick={() => setIsAddExpenseModalOpen(true)}
                className="fixed bottom-6 right-6 hidden z-40 bg-primary-600 hover:bg-primary-700 text-white p-4 rounded-full shadow-lg shadow-primary-600/30 transition-transform hover:scale-110 active:scale-95"
                aria-label="Add Expense"
            >
                <Plus className="w-6 h-6" />
            </button>

            {}
            <Modal
                isOpen={isAddExpenseModalOpen}
                onClose={() => setIsAddExpenseModalOpen(false)}
                title="Add New Expense"
            >
                <AddExpenseForm onSuccess={() => {
                    fetchDashboardData();
                    setIsAddExpenseModalOpen(false);
                }} />
            </Modal>
        </div>
    );
};
