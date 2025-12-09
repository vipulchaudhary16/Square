import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getLoans, createLoan, Loan } from '../../../api/finance';
import { Plus, ArrowLeftRight, X, ArrowUpRight, ArrowDownLeft } from 'lucide-react';

const LoansPage: React.FC = () => {
    const navigate = useNavigate();
    const [loans, setLoans] = useState<Loan[]>([]);
    const [showForm, setShowForm] = useState(false);
    const [formData, setFormData] = useState({
        counterparty_name: '',
        type: 'LENT',
        amount: '',
        date: new Date().toISOString().split('T')[0],
        due_date: '',
        description: ''
    });

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



    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createLoan({
                ...formData,
                amount: parseFloat(formData.amount),
                type: formData.type as 'LENT' | 'BORROWED',
                status: 'PENDING'
            });
            setShowForm(false);
            setFormData({
                counterparty_name: '',
                type: 'LENT',
                amount: '',
                date: new Date().toISOString().split('T')[0],
                due_date: '',
                description: ''
            });
            fetchLoans();
        } catch (error) {
            console.error("Failed to create loan", error);
        }
    };

    return (
        <div className="flex flex-col h-[calc(100vh-8rem)] relative">
            <div className="flex justify-between items-center mb-6 px-1">
                <h1 className="text-3xl font-bold text-gray-800 dark:text-white">Loans & Borrowing</h1>
                <button
                    onClick={() => setShowForm(!showForm)}
                    className="bg-purple-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-purple-700 transition-colors"
                >
                    <Plus size={20} />
                    <span className="hidden md:inline">Add Record</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 -mr-2">
                {showForm && (
                    <div className="bg-white dark:bg-slate-800 rounded-xl shadow-md mb-8 animate-fade-in border dark:border-slate-700 overflow-hidden">
                        <div className="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-100 dark:border-slate-700 px-6 py-4 flex items-center justify-between">
                            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Add New Loan</h2>
                            <div className="flex items-center gap-3">
                                <button
                                    onClick={() => setShowForm(false)}
                                    className="p-2 rounded-full text-slate-400 hover:text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                                >
                                    <X className="w-5 h-5" />
                                </button>
                                <button
                                    type="submit" // Changed from onClick={handleSubmit} to type="submit" to correctly trigger form submission
                                    form="loan-form" // Added form attribute to link button to form
                                    className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 text-sm font-medium"
                                >
                                    Save Loan
                                </button>
                            </div>
                        </div>

                        <div className="p-6">
                            <form id="loan-form" onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Person/Entity</label>
                                    <input
                                        type="text"
                                        required
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.counterparty_name} // Changed from formData.person to formData.counterparty_name
                                        onChange={e => setFormData({ ...formData, counterparty_name: e.target.value })} // Changed from person to counterparty_name
                                        placeholder="e.g. John Doe, Bank of America"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Type</label>
                                    <select
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.type}
                                        onChange={e => setFormData({ ...formData, type: e.target.value as 'LENT' | 'BORROWED' })}
                                    >
                                        <option value="LENT">Lent (Given)</option>
                                        <option value="BORROWED">Borrowed (Taken)</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Amount</label>
                                    <input
                                        type="number"
                                        required
                                        step="0.01"
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.amount}
                                        onChange={e => setFormData({ ...formData, amount: e.target.value })}
                                        placeholder="0.00"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Date</label>
                                    <input
                                        type="date"
                                        required
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.date}
                                        onChange={e => setFormData({ ...formData, date: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Due Date (Optional)</label>
                                    <input
                                        type="date"
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                        value={formData.due_date}
                                        onChange={e => setFormData({ ...formData, due_date: e.target.value })}
                                    />
                                </div>
                                <div className="md:col-span-2">
                                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Description</label>
                                    <textarea
                                        className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-purple-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
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

