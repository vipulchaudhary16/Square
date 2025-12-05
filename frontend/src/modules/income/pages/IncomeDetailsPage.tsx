import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getIncomeDetails, deleteIncome, addIncomeComment, updateIncome, IncomeDetails } from '../../../api/finance';
import useApiCall from '../../../hooks/useApiCall';
import { Loader2, Trash2, Edit2, Send, MessageSquare, History, ArrowLeft, Calendar, Tag, FileText } from 'lucide-react';
import { useSession } from '../../../hooks/useSession';

const IncomeDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    useSession();
    const [income, setIncome] = useState<IncomeDetails | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [newComment, setNewComment] = useState('');

    
    const [formData, setFormData] = useState({
        source: '',
        amount: '',
        category: '',
        date: '',
        description: ''
    });

    const { execute: fetchDetails, loading } = useApiCall({
        apiCall: () => getIncomeDetails(id!)
    });

    const { execute: executeDelete, loading: deleteLoading } = useApiCall({
        apiCall: () => deleteIncome(id!)
    });

    const { execute: executeAddComment, loading: commentLoading } = useApiCall({
        apiCall: (text: string) => addIncomeComment(id!, text)
    });

    const { execute: executeUpdate, loading: updateLoading } = useApiCall({
        apiCall: (data: any) => updateIncome(id!, data)
    });

    const loadData = async () => {
        try {
            const response = await fetchDetails();
            setIncome({
                ...response.income,
                logs: response.logs || [],
                comments: response.comments || [],
                users: response.users || {}
            });
            
            setFormData({
                source: response.income.source,
                amount: response.income.amount.toString(),
                category: response.income.category,
                date: new Date(response.income.date).toISOString().split('T')[0],
                description: response.income.description
            });
        } catch (error) {
            console.error("Failed to load income details", error);
        }
    };

    useEffect(() => {
        if (id) loadData();
    }, [id]);

    const handleDelete = async () => {
        if (window.confirm("Are you sure you want to delete this income record?")) {
            try {
                await executeDelete();
                navigate('/income');
            } catch (error) {
                alert("Failed to delete income");
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
                amount: parseFloat(formData.amount),
                date: new Date(formData.date).toISOString()
            });
            setIsEditing(false);
            loadData();
        } catch (error) {
            alert("Failed to update income");
        }
    };

    const getUserName = (userId: string) => {
        return income?.users?.[userId] || `User ${userId.slice(-4)}`;
    };

    if (loading && !income) {
        return (
            <div className="flex justify-center items-center h-screen">
                <Loader2 className="w-8 h-8 animate-spin text-green-600" />
            </div>
        );
    }

    if (!income) return <div className="p-8 text-center">Income record not found</div>;

    return (
        <div className="max-w-4xl mx-auto p-4 pb-20">
            <button
                onClick={() => navigate('/income')}
                className="flex items-center text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white mb-6 transition-colors"
            >
                <ArrowLeft className="w-4 h-4 mr-2" /> Back to Income
            </button>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 animate-fade-in">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Edit Income</h2>
                        <button onClick={() => setIsEditing(false)} className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200">Cancel</button>
                    </div>
                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Source</label>
                            <input
                                type="text"
                                required
                                className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                value={formData.source}
                                onChange={e => setFormData({ ...formData, source: e.target.value })}
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
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Category</label>
                            <select
                                className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
                                value={formData.category}
                                onChange={e => setFormData({ ...formData, category: e.target.value })}
                            >
                                <option value="Salary">Salary</option>
                                <option value="Freelance">Freelance</option>
                                <option value="Business">Business</option>
                                <option value="Investments">Investments</option>
                                <option value="Gift">Gift</option>
                                <option value="Other">Other</option>
                            </select>
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
                                rows={3}
                            />
                        </div>
                        <div className="md:col-span-2 flex justify-end gap-2 mt-4">
                            <button
                                type="submit"
                                disabled={updateLoading}
                                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center"
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
                                        {income.source}
                                    </h1>
                                    <div className="flex flex-wrap items-center gap-2 md:gap-4 mt-2 text-sm text-gray-500 dark:text-slate-400">
                                        <span className="flex items-center gap-1">
                                            <Calendar className="w-4 h-4" />
                                            {new Date(income.date).toLocaleDateString()}
                                        </span>
                                        <span className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-green-100 dark:bg-green-900/20 text-green-700 dark:text-green-300 text-xs font-medium">
                                            <Tag className="w-3 h-3" />
                                            {income.category}
                                        </span>
                                    </div>
                                </div>
                                <div className="text-left md:text-right w-full md:w-auto">
                                    <div className="text-2xl md:text-3xl font-bold text-green-600 dark:text-green-400">₹{income.amount.toFixed(2)}</div>
                                </div>
                            </div>

                            {income.description && (
                                <div className="mt-6 p-4 bg-gray-50 dark:bg-slate-700/30 rounded-lg">
                                    <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-2 flex items-center gap-2">
                                        <FileText className="w-4 h-4" /> Description
                                    </h3>
                                    <p className="text-gray-600 dark:text-slate-300 text-sm whitespace-pre-wrap">{income.description}</p>
                                </div>
                            )}

                            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-slate-700 flex flex-col sm:flex-row gap-3">
                                <button
                                    onClick={() => setIsEditing(true)}
                                    className="flex-1 flex items-center justify-center px-4 py-2 border border-gray-300 dark:border-slate-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-slate-200 bg-white dark:bg-slate-700 hover:bg-gray-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors"
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
                                {income.comments && income.comments.length > 0 ? (
                                    income.comments.map(comment => (
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
                                    className="block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm p-3 pr-10 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                                />
                                <button
                                    type="submit"
                                    disabled={commentLoading || !newComment.trim()}
                                    className="absolute right-2 top-2 p-1 text-green-600 dark:text-green-400 hover:text-green-700 dark:hover:text-green-300 disabled:text-gray-400 dark:disabled:text-slate-500"
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
                                    {income.logs && income.logs.map((log, logIdx) => (
                                        <li key={log.id}>
                                            <div className="relative pb-8">
                                                {logIdx !== income.logs.length - 1 ? (
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
                                    {(!income.logs || income.logs.length === 0) && (
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

export default IncomeDetailsPage;
