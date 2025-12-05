import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getIncomes, createIncome, Income } from '../../../api/finance';
import { Plus, DollarSign, Calendar } from 'lucide-react';

const IncomePage: React.FC = () => {
    const navigate = useNavigate();
    const [incomes, setIncomes] = useState<Income[]>([]);
    const [showForm, setShowForm] = useState(false);
    const [formData, setFormData] = useState({
        source: '',
        amount: '',
        category: '',
        date: new Date().toISOString().split('T')[0],
        description: ''
    });

    useEffect(() => {
        fetchIncomes();
    }, []);

    const fetchIncomes = async () => {
        try {
            const data = await getIncomes();
            setIncomes(Array.isArray(data) ? data : data.data || []);
        } catch (error) {
            console.error("Failed to fetch incomes", error);
        }
    };



    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createIncome({
                ...formData,
                amount: parseFloat(formData.amount)
            });
            setShowForm(false);
            setFormData({
                source: '',
                amount: '',
                category: '',
                date: new Date().toISOString().split('T')[0],
                description: ''
            });
            fetchIncomes();
        } catch (error) {
            console.error("Failed to create income", error);
        }
    };

    return (
        <div className="flex flex-col h-[calc(100vh-8rem)]">
            <div className="flex justify-between items-center mb-6 px-1">
                <h1 className="text-3xl font-bold text-gray-800 dark:text-white">Income</h1>
                <button
                    onClick={() => setShowForm(!showForm)}
                    className="bg-green-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-green-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Income</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                {showForm && (
                    <div className="bg-white dark:bg-slate-800 p-6 rounded-xl shadow-md mb-8 animate-fade-in border dark:border-slate-700">
                        <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-white">Add New Income</h2>
                        <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Source</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                    value={formData.source}
                                    onChange={e => setFormData({ ...formData, source: e.target.value })}
                                    placeholder="e.g. Salary, Freelance"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Amount</label>
                                <input
                                    type="number"
                                    required
                                    step="0.01"
                                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                    value={formData.amount}
                                    onChange={e => setFormData({ ...formData, amount: e.target.value })}
                                    placeholder="0.00"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Category</label>
                                <input
                                    type="text"
                                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                    value={formData.category}
                                    onChange={e => setFormData({ ...formData, category: e.target.value })}
                                    placeholder="e.g. Primary Job, Side Hustle"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Date</label>
                                <input
                                    type="date"
                                    required
                                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                    value={formData.date}
                                    onChange={e => setFormData({ ...formData, date: e.target.value })}
                                />
                            </div>
                            <div className="md:col-span-2">
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Description</label>
                                <textarea
                                    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                    value={formData.description}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    rows={2}
                                />
                            </div>
                            <div className="md:col-span-2 flex justify-end gap-2">
                                <button
                                    type="button"
                                    onClick={() => setShowForm(false)}
                                    className="px-4 py-2 text-gray-600 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-700 rounded-lg"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                                >
                                    Save Income
                                </button>
                            </div>
                        </form>
                    </div>
                )}

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
                                    <h3 className="font-semibold text-lg text-gray-800 dark:text-white truncate group-hover:text-green-600 dark:group-hover:text-green-400 transition-colors">{income.source}</h3>
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
