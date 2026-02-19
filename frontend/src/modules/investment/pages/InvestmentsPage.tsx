import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getInvestments, Investment } from '../../../api/finance';
import { Plus, PieChart } from 'lucide-react';

const InvestmentsPage: React.FC = () => {
    const navigate = useNavigate();
    const [investments, setInvestments] = useState<Investment[]>([]);

    useEffect(() => {
        fetchInvestments();
    }, []);

    const fetchInvestments = async () => {
        try {
            const data = await getInvestments();
            setInvestments(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error('Failed to fetch investments', error);
        }
    };

    const getProfitLoss = (inv: Investment) => {
        const diff = inv.current_value - inv.amount_invested;
        const percent = (diff / inv.amount_invested) * 100;
        return { diff, percent };
    };

    return (
        <div className="flex flex-col h-[calc(100vh-8rem)] relative">
            <div className="flex justify-between items-center mb-6 px-1">
                <h1 className="text-3xl font-bold text-gray-800 dark:text-white">Investments</h1>
                <button
                    onClick={() => navigate('/new/investment')}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Investment</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                <div className="grid gap-4 pb-4">
                    {investments.map((inv) => {
                        getProfitLoss(inv);
                        return (
                            <div
                                key={inv.id}
                                onClick={() => navigate(`/investments/${inv.id}`)}
                                className="flex items-center justify-between p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors cursor-pointer group"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-blue-600 dark:text-blue-400">
                                        <PieChart className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <div className="font-medium text-gray-900 dark:text-white">
                                            {inv.name}
                                        </div>
                                        <div className="text-sm text-gray-500 dark:text-slate-400 flex items-center gap-2">
                                            <span>{new Date(inv.date).toLocaleDateString()}</span>
                                            <span className="px-1.5 py-0.5 bg-gray-200 dark:bg-slate-600 rounded text-[10px] font-medium text-gray-700 dark:text-slate-300">
                                                {inv.type}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className="text-lg font-bold text-gray-900 dark:text-white">
                                        ${inv.current_value.toFixed(2)}
                                    </div>
                                    <div
                                        className={`text-xs font-medium ${inv.current_value >= inv.amount_invested ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}
                                    >
                                        {inv.current_value >= inv.amount_invested ? '+' : ''}
                                        {(inv.current_value - inv.amount_invested).toFixed(2)}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                    {investments.length === 0 && (
                        <div className="text-center py-12 text-gray-500 dark:text-slate-400">
                            No investments found. Start building your portfolio!
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default InvestmentsPage;
