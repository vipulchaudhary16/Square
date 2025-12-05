import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getInvestmentDetails, deleteInvestment, addInvestmentComment, updateInvestment, InvestmentDetails } from '../../../api/finance';
import useApiCall from '../../../hooks/useApiCall';
import { Loader2, Trash2, Edit2, Send, MessageSquare, History, ArrowLeft, Calendar, FileText, PieChart } from 'lucide-react';
import { useSession } from '../../../hooks/useSession';

const InvestmentDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    useSession();
    const [investment, setInvestment] = useState<InvestmentDetails | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [newComment, setNewComment] = useState('');

    
    const [formData, setFormData] = useState({
        name: '',
        type: 'STOCK',
        amount_invested: '',
        current_value: '',
        date: '',
        description: ''
    });

    const { execute: fetchDetails, loading } = useApiCall({
        apiCall: () => getInvestmentDetails(id!)
    });

    const { execute: executeDelete, loading: deleteLoading } = useApiCall({
        apiCall: () => deleteInvestment(id!)
    });

    const { execute: executeAddComment, loading: commentLoading } = useApiCall({
        apiCall: (text: string) => addInvestmentComment(id!, text)
    });

    const { execute: executeUpdate, loading: updateLoading } = useApiCall({
        apiCall: (data: any) => updateInvestment(id!, data)
    });

    const loadData = async () => {
        try {
            const response = await fetchDetails();
            setInvestment({
                ...response.investment,
                logs: response.logs || [],
                comments: response.comments || [],
                users: response.users || {}
            });
            
            setFormData({
                name: response.investment.name,
                type: response.investment.type,
                amount_invested: response.investment.amount_invested.toString(),
                current_value: response.investment.current_value.toString(),
                date: new Date(response.investment.date).toISOString().split('T')[0],
                description: response.investment.description
            });
        } catch (error) {
            console.error("Failed to load investment details", error);
        }
    };

    useEffect(() => {
        if (id) loadData();
    }, [id]);

    const handleDelete = async () => {
        if (window.confirm("Are you sure you want to delete this investment record?")) {
            try {
                await executeDelete();
                navigate('/investments');
            } catch (error) {
                alert("Failed to delete investment");
            }
        }
    };

    const handleCommentSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newComment.trim()) return;

        try {
            await executeAddComment(newComment);
            setNewComment('');
            loadData();
        } catch (error) {
            alert("Failed to add comment");
        }
    };

    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await executeUpdate({
                ...formData,
                amount_invested: parseFloat(formData.amount_invested),
                current_value: parseFloat(formData.current_value),
                date: new Date(formData.date).toISOString()
            });
            setIsEditing(false);
            loadData();
        } catch (error) {
            alert("Failed to update investment");
        }
    };

    const getUserName = (userId: string) => {
        return investment?.users?.[userId] || `User ${userId.slice(-4)}`;
    };

    if (loading && !investment) {
        return (
            <div className="flex justify-center items-center h-screen">
                <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
            </div>
        );
    }

    if (!investment) return <div className="p-8 text-center">Investment record not found</div>;

    const profitLoss = investment.current_value - investment.amount_invested;
    const isProfit = profitLoss >= 0;
    const percentChange = ((profitLoss / investment.amount_invested) * 100).toFixed(2);

    return (
        <div className="max-w-4xl mx-auto p-4 pb-20">
            <button
                onClick={() => navigate('/investments')}
                className="flex items-center text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white mb-6 transition-colors"
            >
                <ArrowLeft className="w-4 h-4 mr-2" /> Back to Investments
            </button>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 animate-fade-in">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Edit Investment</h2>
                        <button onClick={() => setIsEditing(false)} className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200">Cancel</button>
                    </div>
                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Name</label>
                            <input
                                type="text"
                                required
                                className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                value={formData.name}
                                onChange={e => setFormData({ ...formData, name: e.target.value })}
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
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Invested Amount</label>
                            <input
                                type="number"
                                required
                                step="0.01"
                                className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                value={formData.amount_invested}
                                onChange={e => setFormData({ ...formData, amount_invested: e.target.value })}
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
                                rows={3}
                            />
                        </div>
                        <div className="md:col-span-2 flex justify-end gap-2 mt-4">
                            <button
                                type="submit"
                                disabled={updateLoading}
                                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center"
                            >
                                {updateLoading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
                                Save Changes
                            </button>
                        </div>
                    </form>
                </div>
            ) : (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 animate-fade-in">
                    {}
                    <div className="lg:col-span-2 space-y-6">
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-6">
                            <div className="flex flex-col md:flex-row justify-between items-start gap-4">
                                <div>
                                    <h1 className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                                        {investment.name}
                                    </h1>
                                    <div className="flex flex-wrap items-center gap-2 md:gap-4 mt-2 text-sm text-gray-500 dark:text-slate-400">
                                        <span className="flex items-center gap-1">
                                            <Calendar className="w-4 h-4" />
                                            {new Date(investment.date).toLocaleDateString()}
                                        </span>
                                        <span className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 text-xs font-medium">
                                            <PieChart className="w-3 h-3" />
                                            {investment.type}
                                        </span>
                                    </div>
                                </div>
                                <div className="text-left md:text-right w-full md:w-auto">
                                    <div className="text-sm text-gray-500 dark:text-slate-400 mb-1">Current Value</div>
                                    <div className="text-2xl md:text-3xl font-bold text-gray-900 dark:text-white">${investment.current_value.toFixed(2)}</div>
                                    <div className={`text-sm font-medium mt-1 ${isProfit ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                                        {isProfit ? '+' : ''}{percentChange}% ({isProfit ? '+' : ''}{profitLoss.toFixed(2)})
                                    </div>
                                </div>
                            </div>

                            <div className="mt-6 p-4 bg-gray-50 dark:bg-slate-700/30 rounded-lg flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                                <div>
                                    <div className="text-xs text-gray-500 dark:text-slate-400 mb-1">Invested Amount</div>
                                    <div className="text-lg font-semibold text-gray-900 dark:text-white">${investment.amount_invested.toFixed(2)}</div>
                                </div>
                                <div className="hidden sm:block h-8 w-px bg-gray-300 dark:bg-slate-600 mx-4"></div>
                                <div>
                                    <div className="text-xs text-gray-500 dark:text-slate-400 mb-1">Profit / Loss</div>
                                    <div className={`text-lg font-semibold ${isProfit ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                                        {isProfit ? '+' : ''}{profitLoss.toFixed(2)}
                                    </div>
                                </div>
                            </div>

                            {investment.description && (
                                <div className="mt-4 p-4 bg-gray-50 dark:bg-slate-700/30 rounded-lg">
                                    <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-2 flex items-center gap-2">
                                        <FileText className="w-4 h-4" /> Description
                                    </h3>
                                    <p className="text-gray-600 dark:text-slate-300 text-sm whitespace-pre-wrap">{investment.description}</p>
                                </div>
                            )}

                            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-slate-700 flex flex-col sm:flex-row gap-3">
                                <button
                                    onClick={() => setIsEditing(true)}
                                    className="flex-1 flex items-center justify-center px-4 py-2 border border-gray-300 dark:border-slate-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-slate-200 bg-white dark:bg-slate-700 hover:bg-gray-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
                                >
                                    <Edit2 className="w-4 h-4 mr-2" /> Edit
                                </button>
                                <button
                                    onClick={handleDelete}
                                    disabled={deleteLoading}
                                    className="flex-1 flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 transition-colors"
                                >
                                    {deleteLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Trash2 className="w-4 h-4 mr-2" /> Delete</>}
                                </button>
                            </div>
                        </div>

                        {}
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-6">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
                                <MessageSquare className="w-5 h-5 mr-2" /> Comments
                            </h3>

                            <div className="space-y-4 mb-6 max-h-60 overflow-y-auto">
                                {investment.comments && investment.comments.length > 0 ? (
                                    investment.comments.map(comment => (
                                        <div key={comment.id} className="bg-gray-50 dark:bg-slate-700 rounded-lg p-3">
                                            <div className="flex justify-between items-start mb-1">
                                                <span className="text-xs font-medium text-gray-900 dark:text-white">{getUserName(comment.user_id)}</span>
                                                <span className="text-xs text-gray-500 dark:text-slate-400">{new Date(comment.created_at).toLocaleString()}</span>
                                            </div>
                                            <p className="text-sm text-gray-700 dark:text-slate-300">{comment.text}</p>
                                        </div>
                                    ))
                                ) : (
                                    <p className="text-sm text-gray-500 dark:text-slate-400 italic text-center py-4">No comments yet.</p>
                                )}
                            </div>

                            <form onSubmit={handleCommentSubmit} className="relative">
                                <input
                                    type="text"
                                    value={newComment}
                                    onChange={(e) => setNewComment(e.target.value)}
                                    placeholder="Add a comment..."
                                    className="block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-3 pr-10 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                                />
                                <button
                                    type="submit"
                                    disabled={commentLoading || !newComment.trim()}
                                    className="absolute right-2 top-2 p-1 text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 disabled:text-gray-400 dark:disabled:text-slate-500"
                                >
                                    {commentLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                                </button>
                            </form>
                        </div>
                    </div>

                    {}
                    <div className="lg:col-span-1">
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-6 sticky top-24">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
                                <History className="w-5 h-5 mr-2" /> Activity Log
                            </h3>
                            <div className="flow-root">
                                <ul className="-mb-8">
                                    {investment.logs && investment.logs.map((log, logIdx) => (
                                        <li key={log.id}>
                                            <div className="relative pb-8">
                                                {logIdx !== investment.logs.length - 1 ? (
                                                    <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-slate-600" aria-hidden="true" />
                                                ) : null}
                                                <div className="relative flex space-x-3">
                                                    <div>
                                                        <span className="h-8 w-8 rounded-full bg-gray-100 dark:bg-slate-700 flex items-center justify-center ring-8 ring-white dark:ring-slate-800">
                                                            <History className="h-4 w-4 text-gray-500 dark:text-slate-400" />
                                                        </span>
                                                    </div>
                                                    <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                                                        <div>
                                                            <p className="text-sm text-gray-500 dark:text-slate-400">
                                                                <span className="font-medium text-gray-900 dark:text-white">{log.action}</span>
                                                                <span className="text-xs text-gray-400 dark:text-slate-500 ml-2">by {getUserName(log.user_id)}</span>
                                                            </p>
                                                            <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{log.details}</p>
                                                        </div>
                                                        <div className="text-right text-xs whitespace-nowrap text-gray-500 dark:text-slate-400">
                                                            <time dateTime={log.created_at}>{new Date(log.created_at).toLocaleDateString()}</time>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </li>
                                    ))}
                                    {(!investment.logs || investment.logs.length === 0) && (
                                        <li className="text-sm text-gray-500 dark:text-slate-400 italic">No activity recorded.</li>
                                    )}
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default InvestmentDetailsPage;
