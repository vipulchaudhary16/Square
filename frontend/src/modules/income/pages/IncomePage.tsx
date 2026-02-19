import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getIncomes, Income } from '../../../api/finance';
import { Plus, DollarSign, Calendar } from 'lucide-react';

const IncomePage: React.FC = () => {
    const navigate = useNavigate();
    const [incomes, setIncomes] = useState<Income[]>([]);

    useEffect(() => {
        fetchIncomes();
    }, []);

    const fetchIncomes = async () => {
        try {
            const data = await getIncomes();
            setIncomes(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error('Failed to fetch incomes', error);
        }
    };

    return (
        <div className="flex flex-col h-[calc(100vh-8rem)]">
            <div className="flex justify-between items-center mb-6 px-1">
                <h1 className="text-3xl font-bold text-gray-800 dark:text-white">Income</h1>
                <button
                    onClick={() => navigate('/new/income')}
                    className="bg-green-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-green-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Income</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                <div className="grid gap-4 pb-4">
                    {incomes.map((income) => (
                        <div
                            key={income.id}
                            onClick={() => navigate(`/income/${income.id}`)}
                            className="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-gray-100 dark:border-slate-700 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 hover:shadow-md transition-shadow cursor-pointer group"
                        >
                            <div className="flex items-center gap-4 w-full md:w-auto">
                                <div className="bg-green-100 dark:bg-green-900/20 p-3 rounded-full text-green-600 dark:text-green-400 flex-shrink-0">
                                    <DollarSign size={24} />
                                </div>
                                <div className="min-w-0 flex-1">
                                    <h3 className="font-semibold text-lg text-gray-800 dark:text-white truncate group-hover:text-green-600 dark:group-hover:text-green-400 transition-colors">
                                        {income.source}
                                    </h3>
                                    <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-slate-400 mt-1">
                                        <span className="flex items-center gap-1">
                                            <Calendar size={14} />
                                            {new Date(income.date).toLocaleDateString()}
                                        </span>
                                        <span className="bg-gray-100 dark:bg-slate-700 px-2 py-0.5 rounded text-xs truncate max-w-[100px]">
                                            {income.category}
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div className="flex items-center justify-between w-full md:w-auto gap-6 pl-[60px] md:pl-0">
                                <span className="text-xl font-bold text-green-600 dark:text-green-400">
                                    +${income.amount.toFixed(2)}
                                </span>
                            </div>
                        </div>
                    ))}
                    {incomes.length === 0 && (
                        <div className="text-center py-12 text-gray-500 dark:text-slate-400">
                            No income records found. Start adding your income!
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default IncomePage;
