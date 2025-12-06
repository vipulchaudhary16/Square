import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getIncomeDetails, deleteIncome, addIncomeComment, updateIncome, IncomeDetails } from '../../../api/finance';
import useApiCall from '../../../hooks/useApiCall';
import { Loader2, Trash2, Edit2, Send, MessageSquare, History, ArrowLeft, Calendar, FileText } from 'lucide-react';
import { useSession } from '../../../hooks/useSession';
import { DropdownMenu } from '../../common/components/ui/DropdownMenu';

const IncomeDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    useSession();
    const [income, setIncome] = useState<IncomeDetails | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [newComment, setNewComment] = useState('');
    const [activeTab, setActiveTab] = useState<'comments' | 'activity'>('comments');

    
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

    const { execute: executeDelete } = useApiCall({
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
        <div className="max-w-5xl mx-auto p-4 md:p-8 pb-24">
            <div className="flex items-center justify-between mb-6">
                <button
                    onClick={() => navigate(-1)}
                    className="flex items-center text-gray-500 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                    <ArrowLeft className="w-5 h-5 mr-2" /> Back
                </button>
                
                {!isEditing && (
                    <DropdownMenu
                        items={[
                            {
                                label: 'Edit Income',
                                icon: <Edit2 className="w-4 h-4" />,
                                onClick: () => setIsEditing(true)
                            },
                            {
                                label: 'Delete Income',
                                icon: <Trash2 className="w-4 h-4" />,
                                variant: 'danger',
                                onClick: handleDelete
                            }
                        ]}
                    />
                )}
            </div>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Edit Income</h2>
                        <button 
                            onClick={() => setIsEditing(false)} 
                            className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 font-medium"
                        >
                            Cancel
                        </button>
                    </div>
                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Source</label>
                            <input
                                type="text"
                                required
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-green-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.source}
                                onChange={e => setFormData({ ...formData, source: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Amount</label>
                            <input
                                type="number"
                                required
                                step="0.01"
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-green-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.amount}
                                onChange={e => setFormData({ ...formData, amount: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Category</label>
                            <select
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-green-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
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
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Date</label>
                            <input
                                type="date"
                                required
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-green-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.date}
                                onChange={e => setFormData({ ...formData, date: e.target.value })}
                            />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Description</label>
                            <textarea
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-green-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.description}
                                onChange={e => setFormData({ ...formData, description: e.target.value })}
                                rows={3}
                            />
                        </div>
                        <div className="md:col-span-2 flex justify-end gap-3 mt-4">
                            <button
                                type="submit"
                                disabled={updateLoading}
                                className="px-6 py-2.5 bg-green-600 text-white rounded-xl hover:bg-green-700 disabled:opacity-50 flex items-center shadow-lg shadow-green-500/20 transition-all hover:shadow-green-500/30 font-medium"
                            >
                                {updateLoading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
                                Save Changes
                            </button>
                        </div>
                    </form>
                </div>
            ) : (
                <div className="space-y-8 animate-fade-in">

                    <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-500/10 to-emerald-500/10 rounded-bl-full -mr-8 -mt-8 pointer-events-none" />
                        
                        <div className="relative">
                            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 mb-6">
                                <div>
                                    <div className="flex items-center gap-2 mb-3">
                                        <span className="px-3 py-1 rounded-full text-xs font-semibold bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 border border-green-100 dark:border-green-800/50 uppercase tracking-wide">
                                            {income.category}
                                        </span>
                                    </div>
                                    <h1 className="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-2">{income.source}</h1>
                                </div>
                                <div className="text-left md:text-right">
                                    <div className="text-4xl md:text-5xl font-bold text-green-600 dark:text-green-400 tracking-tight">+₹{income.amount.toFixed(2)}</div>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-6 border-t border-gray-100 dark:border-slate-700">
                                <div className="flex items-center gap-3 text-gray-600 dark:text-slate-300">
                                    <div className="w-10 h-10 rounded-full bg-gray-50 dark:bg-slate-700 flex items-center justify-center text-gray-400 dark:text-slate-400">
                                        <Calendar className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 dark:text-slate-500 uppercase font-semibold tracking-wider">Date</p>
                                        <p className="font-medium">{new Date(income.date).toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                                    </div>
                                </div>
                                {income.description && (
                                    <div className="col-span-1 sm:col-span-2 mt-2 p-4 bg-gray-50 dark:bg-slate-700/30 rounded-xl border border-dashed border-gray-200 dark:border-slate-700">
                                        <h3 className="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-wider mb-2 flex items-center gap-2">
                                            <FileText className="w-3 h-3" /> Description
                                        </h3>
                                        <p className="text-gray-600 dark:text-slate-300 text-sm whitespace-pre-wrap leading-relaxed">{income.description}</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>


                    <div className="border-b border-gray-200 dark:border-slate-700 overflow-x-auto">
                        <nav className="-mb-px flex space-x-8 min-w-max" aria-label="Tabs">
                            <button
                                onClick={() => setActiveTab('comments')}
                                className={`${
                                    activeTab === 'comments'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-300 hover:border-gray-300'
                                } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 transition-colors`}
                            >
                                <MessageSquare className="w-4 h-4" />
                                Comments
                                <span className="bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 py-0.5 px-2 rounded-full text-xs">
                                    {income.comments?.length || 0}
                                </span>
                            </button>
                            <button
                                onClick={() => setActiveTab('activity')}
                                className={`${
                                    activeTab === 'activity'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-300 hover:border-gray-300'
                                } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 transition-colors`}
                            >
                                <History className="w-4 h-4" />
                                Activity Log
                            </button>
                        </nav>
                    </div>


                    <div className="min-h-[400px] mt-6">
                        {activeTab === 'comments' ? (
                            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                                <div className="space-y-4 mb-6 max-h-[500px] overflow-y-auto pr-2 custom-scrollbar">
                                    {income.comments && income.comments.length > 0 ? (
                                        income.comments.map(comment => (
                                            <div key={comment.id} className="flex gap-3 group">
                                                <div className="w-8 h-8 rounded-full bg-green-100 dark:bg-green-900/30 flex-shrink-0 flex items-center justify-center text-xs font-bold text-green-600 dark:text-green-400">
                                                    {getUserName(comment.user_id).charAt(0).toUpperCase()}
                                                </div>
                                                <div className="flex-1 bg-gray-50 dark:bg-slate-700/50 rounded-2xl rounded-tl-none p-4">
                                                    <div className="flex justify-between items-start mb-1">
                                                        <span className="text-xs font-bold text-gray-900 dark:text-white">{getUserName(comment.user_id)}</span>
                                                        <span className="text-[10px] text-gray-400 dark:text-slate-500">{new Date(comment.created_at).toLocaleString()}</span>
                                                    </div>
                                                    <p className="text-sm text-gray-700 dark:text-slate-300 leading-relaxed">{comment.text}</p>
                                                </div>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="text-center py-12">
                                            <div className="w-12 h-12 bg-gray-50 dark:bg-slate-700/50 rounded-full flex items-center justify-center mx-auto mb-3 text-gray-300 dark:text-slate-600">
                                                <MessageSquare className="w-6 h-6" />
                                            </div>
                                            <p className="text-sm text-gray-500 dark:text-slate-400">No comments yet. Start the conversation!</p>
                                        </div>
                                    )}
                                </div>

                                <form onSubmit={handleCommentSubmit} className="relative">
                                    <input
                                        type="text"
                                        value={newComment}
                                        onChange={(e) => setNewComment(e.target.value)}
                                        placeholder="Add a comment..."
                                        className="block w-full rounded-xl border-gray-200 dark:border-slate-700 shadow-sm focus:border-green-500 focus:ring-green-500 sm:text-sm py-3 pl-4 pr-12 border bg-gray-50 dark:bg-slate-900/50 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-800"
                                    />
                                    <button
                                        type="submit"
                                        disabled={commentLoading || !newComment.trim()}
                                        className="absolute right-2 top-1.5 p-1.5 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-300 dark:disabled:bg-slate-700 disabled:cursor-not-allowed transition-colors shadow-sm"
                                    >
                                        {commentLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                                    </button>
                                </form>
                            </div>
                        ) : (
                            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                                <div className="flow-root">
                                    <ul className="-mb-8">
                                        {income.logs && income.logs.map((log, logIdx) => (
                                            <li key={log.id}>
                                                <div className="relative pb-8">
                                                    {logIdx !== income.logs.length - 1 ? (
                                                        <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-100 dark:bg-slate-700" aria-hidden="true" />
                                                    ) : null}
                                                    <div className="relative flex space-x-3">
                                                        <div>
                                                            <span className="h-8 w-8 rounded-full bg-gray-50 dark:bg-slate-700 flex items-center justify-center ring-4 ring-white dark:ring-slate-800">
                                                                <div className="w-2 h-2 rounded-full bg-green-400 dark:bg-green-500" />
                                                            </span>
                                                        </div>
                                                        <div className="min-w-0 flex-1 pt-1.5">
                                                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                                                                {log.action}
                                                            </p>
                                                            <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">
                                                                by {getUserName(log.user_id)}
                                                            </p>
                                                            <p className="text-xs text-gray-400 dark:text-slate-500 mt-1">
                                                                {new Date(log.created_at).toLocaleString()}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </li>
                                        ))}
                                        {(!income.logs || income.logs.length === 0) && (
                                            <li className="text-sm text-gray-500 dark:text-slate-400 italic text-center py-4">No activity recorded.</li>
                                        )}
                                    </ul>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default IncomeDetailsPage;
