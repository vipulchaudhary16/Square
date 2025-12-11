import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getLoans, Loan } from '../../../api/finance';
import { Plus, ArrowUpRight, ArrowDownLeft } from 'lucide-react';

const LoansPage: React.FC = () => {
    const navigate = useNavigate();
    const [loans, setLoans] = useState<Loan[]>([]);

    useEffect(() => {
        fetchLoans();
    }, []);

    const fetchLoans = async () => {
        try {
            const data = await getLoans();
            setLoans(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error("Failed to fetch loans", error);
        }
    };

    return (
        <div className="flex flex-col h-[calc(100vh-8rem)] relative">
            <div className="flex justify-between items-center mb-6 px-1">
                <h1 className="text-3xl font-bold text-gray-800 dark:text-white">Loans & Borrowing</h1>
                <button
                    onClick={() => navigate('/new/loan')}
                    className="bg-purple-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-purple-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Record</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                <div className="grid gap-4 pb-4">
                    {loans.map((loan) => {
                        return (
                            <div
                                key={loan.id}
                                onClick={() => navigate(`/loans/${loan.id}`)}
                                className="flex items-center justify-between p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors cursor-pointer group"
                            >
                                <div className="flex items-center gap-4">
                                    <div className={`p-2 rounded-full ${loan.type === 'LENT' ? 'bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400' : 'bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400'}`}>
                                        {loan.type === 'LENT' ? <ArrowUpRight className="w-5 h-5" /> : <ArrowDownLeft className="w-5 h-5" />}
                                    </div>
                                    <div>
                                        <div className="font-medium text-gray-900 dark:text-white">{loan.counterparty_name}</div>
                                        <div className="text-sm text-gray-500 dark:text-slate-400 flex items-center gap-2">
                                            <span>{new Date(loan.date).toLocaleDateString()}</span>
                                            <span className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${loan.status === 'PAID' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400' : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-600 dark:text-yellow-400'}`}>
                                                {loan.status}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <div className={`text-lg font-bold ${loan.type === 'LENT' ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                                    ${loan.amount.toFixed(2)}
                                </div>
                            </div>
                        );
                    })}
                    {loans.length === 0 && (
                        <div className="text-center py-12 text-gray-500 dark:text-slate-400">
                            No loan records found.
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default LoansPage;

