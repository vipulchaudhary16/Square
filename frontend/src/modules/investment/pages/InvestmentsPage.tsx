
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getInvestments, createInvestment, Investment } from '../../../api/finance';
import { Plus, PieChart, X } from 'lucide-react';

const InvestmentsPage: React.FC = () => {
    const navigate = useNavigate();
    const [investments, setInvestments] = useState<Investment[]>([]);
    const [showForm, setShowForm] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        type: 'STOCK',
        amount_invested: '',
        current_value: '',
        date: new Date().toISOString().split('T')[0],
        description: ''
    });

    useEffect(() => {
        fetchInvestments();
    }, []);

    const fetchInvestments = async () => {
        try {
            const data = await getInvestments();
            setInvestments(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error("Failed to fetch investments", error);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createInvestment({
                ...formData,
                amount_invested: parseFloat(formData.amount_invested),
                current_value: parseFloat(formData.current_value)
            });
            setShowForm(false);
            setFormData({
                name: '',
                type: 'STOCK',
                amount_invested: '',
                current_value: '',
                date: new Date().toISOString().split('T')[0],
                description: ''
            });
            fetchInvestments();
        } catch (error) {
            console.error("Failed to create investment", error);
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
                    onClick={() => setShowForm(!showForm)}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Investment</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                {showForm && (
                    <div className="bg-white dark:bg-slate-800 rounded-xl shadow-md mb-8 animate-fade-in border dark:border-slate-700 overflow-hidden">
                        <div className="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-100 dark:border-slate-700 px-6 py-4 flex items-center justify-between">
                            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Add New Investment</h2>
                            <div className="flex items-center gap-3">
                                <button
                                    onClick={() => setShowForm(false)}
                                    className="p-2 rounded-full text-slate-400 hover:text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                                >
                                    <X className="w-5 h-5" />
                                </button>
                                <button
                                    onClick={handleSubmit}
                                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
                                >
                                    Save Investment
                                </button>
                            </div>
                        </div>

                        <div className="p-6">
                            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Name</label>
                                    <input
                                        type="text"
                                        required
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.name}
                                        onChange={e => setFormData({ ...formData, name: e.target.value })}
                                        placeholder="e.g. Apple Stock, Bitcoin"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Type</label>
                                    <select
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.type}
                                        onChange={e => setFormData({ ...formData, type: e.target.value })}
                                    >
                                        <option value="STOCK">Stock</option>
                                        <option value="CRYPTO">Crypto</option>
                                        <option value="MUTUAL_FUND">Mutual Fund</option>
                                        <option value="REAL_ESTATE">Real Estate</option>
                                        <option value="OTHER">Other</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Amount Invested</label>
                                    <input
                                        type="number"
                                        required
                                        step="0.01"
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.amount_invested}
                                        onChange={e => setFormData({ ...formData, amount_invested: e.target.value })}
                                        placeholder="0.00"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Current Value</label>
                                    <input
                                        type="number"
                                        required
                                        step="0.01"
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.current_value}
                                        onChange={e => setFormData({ ...formData, current_value: e.target.value })}
                                        placeholder="0.00"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Date</label>
                                    <input
                                        type="date"
                                        required
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.date}
                                        onChange={e => setFormData({ ...formData, date: e.target.value })}
                                    />
                                </div>
                                <div className="md:col-span-2">
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Description</label>
                                    <textarea
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.description}
                                        onChange={e => setFormData({ ...formData, description: e.target.value })}
                                        rows={2}
                                    />
                                </div>
                            </form>
                        </div>
                    </div>
                )}

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
                                        <div className="font-medium text-gray-900 dark:text-white">{inv.name}</div>
                                        <div className="text-sm text-gray-500 dark:text-slate-400 flex items-center gap-2">
                                            <span>{new Date(inv.date).toLocaleDateString()}</span>
                                            <span className="px-1.5 py-0.5 bg-gray-200 dark:bg-slate-600 rounded text-[10px] font-medium text-gray-700 dark:text-slate-300">
                                                {inv.type}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className="text-lg font-bold text-gray-900 dark:text-white">${inv.current_value.toFixed(2)}</div>
                                    <div className={`text-xs font-medium ${inv.current_value >= inv.amount_invested ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
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
