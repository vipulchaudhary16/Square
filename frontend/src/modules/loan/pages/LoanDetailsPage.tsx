import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
    getLoanDetails,
    deleteLoan,
    addLoanComment,
    updateLoan,
    LoanDetails,
} from '../../../api/finance';
import useApiCall from '../../../hooks/useApiCall';
import {
    Loader2,
    Trash2,
    Edit2,
    Send,
    MessageSquare,
    History,
    ArrowLeft,
    Calendar,
    FileText,
    ArrowUpRight,
    ArrowDownLeft,
    User,
} from 'lucide-react';
import { useSession } from '../../../hooks/useSession';
import { DropdownMenu } from '../../common/components/ui/DropdownMenu';

const LoanDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    useSession();
    const [loan, setLoan] = useState<LoanDetails | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [newComment, setNewComment] = useState('');
    const [activeTab, setActiveTab] = useState<'comments' | 'activity'>('comments');

    const [formData, setFormData] = useState({
        counterparty_name: '',
        type: 'LENT',
        amount: '',
        date: '',
        due_date: '',
        status: 'PENDING',
        description: '',
    });

    const { execute: fetchDetails, loading } = useApiCall({
        apiCall: () => getLoanDetails(id!),
    });

    const { execute: executeDelete } = useApiCall({
        apiCall: () => deleteLoan(id!),
    });

    const { execute: executeAddComment, loading: commentLoading } = useApiCall({
        apiCall: (text: string) => addLoanComment(id!, text),
    });

    const { execute: executeUpdate, loading: updateLoading } = useApiCall({
        apiCall: (data: any) => updateLoan(id!, data),
    });

    const loadData = async () => {
        try {
            const response = await fetchDetails();
            setLoan({
                ...response.loan,
                logs: response.logs || [],
                comments: response.comments || [],
                users: response.users || {},
            });

            setFormData({
                counterparty_name: response.loan.counterparty_name,
                type: response.loan.type,
                amount: response.loan.amount.toString(),
                date: new Date(response.loan.date).toISOString().split('T')[0],
                due_date: response.loan.due_date
                    ? new Date(response.loan.due_date).toISOString().split('T')[0]
                    : '',
                status: response.loan.status,
                description: response.loan.description,
            });
        } catch (error) {
            console.error('Failed to load loan details', error);
        }
    };

    useEffect(() => {
        if (id) loadData();
    }, [id]);

    const handleDelete = async () => {
        if (window.confirm('Are you sure you want to delete this loan record?')) {
            try {
                await executeDelete();
                navigate('/loans');
            } catch (error) {
                alert('Failed to delete loan');
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
            alert('Failed to add comment');
        }
    };

    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await executeUpdate({
                ...formData,
                amount: parseFloat(formData.amount),
                date: new Date(formData.date).toISOString(),
                due_date: formData.due_date ? new Date(formData.due_date).toISOString() : undefined,
            });
            setIsEditing(false);
            loadData();
        } catch (error) {
            alert('Failed to update loan');
        }
    };

    const getUserName = (userId: string) => {
        return loan?.users?.[userId] || `User ${userId.slice(-4)}`;
    };

    if (loading && !loan) {
        return (
            <div className="flex justify-center items-center h-screen">
                <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
            </div>
        );
    }

    if (!loan) return <div className="p-8 text-center">Loan record not found</div>;

    const isLent = loan.type === 'LENT';

    return (
        <div className="max-w-5xl mx-auto p-2 md:p-8 pb-24">
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
                                label: 'Edit Loan',
                                icon: <Edit2 className="w-4 h-4" />,
                                onClick: () => setIsEditing(true),
                            },
                            {
                                label: 'Delete Loan',
                                icon: <Trash2 className="w-4 h-4" />,
                                variant: 'danger',
                                onClick: handleDelete,
                            },
                        ]}
                    />
                )}
            </div>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                            Edit Loan Record
                        </h2>
                        <button
                            onClick={() => setIsEditing(false)}
                            className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 font-medium"
                        >
                            Cancel
                        </button>
                    </div>
                    <form onSubmit={handleUpdate} className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Person Name
                            </label>
                            <input
                                type="text"
                                required
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.counterparty_name}
                                onChange={(e) =>
                                    setFormData({ ...formData, counterparty_name: e.target.value })
                                }
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Type
                            </label>
                            <select
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.type}
                                onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                            >
                                <option value="LENT">I Lent (They owe me)</option>
                                <option value="BORROWED">I Borrowed (I owe them)</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Amount
                            </label>
                            <input
                                type="number"
                                required
                                step="0.01"
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.amount}
                                onChange={(e) =>
                                    setFormData({ ...formData, amount: e.target.value })
                                }
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Status
                            </label>
                            <select
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.status}
                                onChange={(e) =>
                                    setFormData({ ...formData, status: e.target.value })
                                }
                            >
                                <option value="PENDING">Pending</option>
                                <option value="PAID">Paid / Settled</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Date
                            </label>
                            <input
                                type="date"
                                required
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.date}
                                onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Due Date (Optional)
                            </label>
                            <input
                                type="date"
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.due_date}
                                onChange={(e) =>
                                    setFormData({ ...formData, due_date: e.target.value })
                                }
                            />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                Description
                            </label>
                            <textarea
                                className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-purple-500 outline-none bg-gray-50 dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-700"
                                value={formData.description}
                                onChange={(e) =>
                                    setFormData({ ...formData, description: e.target.value })
                                }
                                rows={3}
                            />
                        </div>
                        <div className="md:col-span-2 flex justify-end gap-3 mt-4">
                            <button
                                type="submit"
                                disabled={updateLoading}
                                className="px-6 py-2.5 bg-purple-600 text-white rounded-xl hover:bg-purple-700 disabled:opacity-50 flex items-center shadow-lg shadow-purple-500/20 transition-all hover:shadow-purple-500/30 font-medium"
                            >
                                {updateLoading ? (
                                    <Loader2 className="w-4 h-4 animate-spin mr-2" />
                                ) : null}
                                Save Changes
                            </button>
                        </div>
                    </form>
                </div>
            ) : (
                <div className="space-y-8 animate-fade-in">
                    <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-bl-full -mr-8 -mt-8 pointer-events-none" />

                        <div className="relative">
                            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 mb-6">
                                <div>
                                    <div className="flex items-center gap-2 mb-3">
                                        <span
                                            className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border uppercase tracking-wide ${isLent ? 'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 border-green-100 dark:border-green-800/50' : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border-red-100 dark:border-red-800/50'}`}
                                        >
                                            {isLent ? (
                                                <ArrowUpRight className="w-3 h-3" />
                                            ) : (
                                                <ArrowDownLeft className="w-3 h-3" />
                                            )}
                                            {isLent ? 'You Lent' : 'You Borrowed'}
                                        </span>
                                        <span
                                            className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border uppercase tracking-wide ${loan.status === 'PAID' ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border-blue-100 dark:border-blue-800/50' : 'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-600 dark:text-yellow-400 border-yellow-100 dark:border-yellow-800/50'}`}
                                        >
                                            {loan.status}
                                        </span>
                                    </div>
                                    <h1 className="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-2">
                                        {loan.counterparty_name}
                                    </h1>
                                    <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-slate-400">
                                        <Calendar className="w-4 h-4" />
                                        {new Date(loan.date).toLocaleDateString(undefined, {
                                            weekday: 'long',
                                            year: 'numeric',
                                            month: 'long',
                                            day: 'numeric',
                                        })}
                                    </div>
                                </div>
                                <div className="text-left md:text-right">
                                    <div className="text-sm text-gray-500 dark:text-slate-400 mb-1 uppercase tracking-wider font-semibold">
                                        Amount
                                    </div>
                                    <div
                                        className={`text-4xl md:text-5xl font-bold tracking-tight ${isLent ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}
                                    >
                                        ${loan.amount.toFixed(2)}
                                    </div>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-6 border-t border-gray-100 dark:border-slate-700">
                                <div className="p-4 bg-gray-50 dark:bg-slate-700/30 rounded-xl border border-gray-100 dark:border-slate-700/50">
                                    <div className="text-xs text-gray-500 dark:text-slate-400 mb-1 uppercase tracking-wider font-semibold flex items-center gap-1">
                                        <User className="w-3 h-3" /> Person
                                    </div>
                                    <div className="text-lg font-semibold text-gray-900 dark:text-white">
                                        {loan.counterparty_name}
                                    </div>
                                </div>
                                {loan.due_date && (
                                    <div className="p-4 bg-gray-50 dark:bg-slate-700/30 rounded-xl border border-gray-100 dark:border-slate-700/50">
                                        <div className="text-xs text-gray-500 dark:text-slate-400 mb-1 uppercase tracking-wider font-semibold flex items-center gap-1">
                                            <Calendar className="w-3 h-3" /> Due Date
                                        </div>
                                        <div className="text-lg font-semibold text-gray-900 dark:text-white">
                                            {new Date(loan.due_date).toLocaleDateString()}
                                        </div>
                                    </div>
                                )}

                                {loan.description && (
                                    <div className="col-span-1 sm:col-span-2 mt-2 p-4 bg-gray-50 dark:bg-slate-700/30 rounded-xl border border-dashed border-gray-200 dark:border-slate-700">
                                        <h3 className="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-wider mb-2 flex items-center gap-2">
                                            <FileText className="w-3 h-3" /> Description
                                        </h3>
                                        <p className="text-gray-600 dark:text-slate-300 text-sm whitespace-pre-wrap leading-relaxed">
                                            {loan.description}
                                        </p>
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
                                    {loan.comments?.length || 0}
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

                    <div className="mt-6">
                        {activeTab === 'comments' ? (
                            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-8 animate-fade-in">
                                <div className="space-y-4 mb-6 max-h-[500px] overflow-y-auto pr-2 custom-scrollbar">
                                    {loan.comments && loan.comments.length > 0 ? (
                                        loan.comments.map((comment) => (
                                            <div key={comment.id} className="flex gap-3 group">
                                                <div className="w-8 h-8 rounded-full bg-purple-100 dark:bg-purple-900/30 flex-shrink-0 flex items-center justify-center text-xs font-bold text-purple-600 dark:text-purple-400">
                                                    {getUserName(comment.user_id)
                                                        .charAt(0)
                                                        .toUpperCase()}
                                                </div>
                                                <div className="flex-1 bg-gray-50 dark:bg-slate-700/50 rounded-2xl rounded-tl-none p-4">
                                                    <div className="flex justify-between items-start mb-1">
                                                        <span className="text-xs font-bold text-gray-900 dark:text-white">
                                                            {getUserName(comment.user_id)}
                                                        </span>
                                                        <span className="text-[10px] text-gray-400 dark:text-slate-500">
                                                            {new Date(
                                                                comment.created_at,
                                                            ).toLocaleString()}
                                                        </span>
                                                    </div>
                                                    <p className="text-sm text-gray-700 dark:text-slate-300 leading-relaxed">
                                                        {comment.text}
                                                    </p>
                                                </div>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="text-center py-12">
                                            <div className="w-12 h-12 bg-gray-50 dark:bg-slate-700/50 rounded-full flex items-center justify-center mx-auto mb-3 text-gray-300 dark:text-slate-600">
                                                <MessageSquare className="w-6 h-6" />
                                            </div>
                                            <p className="text-sm text-gray-500 dark:text-slate-400">
                                                No comments yet. Start the conversation!
                                            </p>
                                        </div>
                                    )}
                                </div>

                                <form onSubmit={handleCommentSubmit} className="relative">
                                    <input
                                        type="text"
                                        value={newComment}
                                        onChange={(e) => setNewComment(e.target.value)}
                                        placeholder="Add a comment..."
                                        className="block w-full rounded-xl border-gray-200 dark:border-slate-700 shadow-sm focus:border-purple-500 focus:ring-purple-500 sm:text-sm py-3 pl-4 pr-12 border bg-gray-50 dark:bg-slate-900/50 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-800"
                                    />
                                    <button
                                        type="submit"
                                        disabled={commentLoading || !newComment.trim()}
                                        className="absolute right-2 top-1.5 p-1.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:bg-gray-300 dark:disabled:bg-slate-700 disabled:cursor-not-allowed transition-colors shadow-sm"
                                    >
                                        {commentLoading ? (
                                            <Loader2 className="w-4 h-4 animate-spin" />
                                        ) : (
                                            <Send className="w-4 h-4" />
                                        )}
                                    </button>
                                </form>
                            </div>
                        ) : (
                            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-8 animate-fade-in">
                                <div className="flow-root">
                                    <ul className="">
                                        {loan.logs &&
                                            loan.logs.map((log, logIdx) => (
                                                <li key={log.id}>
                                                    <div className="relative pb-8">
                                                        {logIdx !== loan.logs.length - 1 ? (
                                                            <span
                                                                className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-100 dark:bg-slate-700"
                                                                aria-hidden="true"
                                                            />
                                                        ) : null}
                                                        <div className="relative flex space-x-3">
                                                            <div>
                                                                <span className="h-8 w-8 rounded-full bg-gray-50 dark:bg-slate-700 flex items-center justify-center ring-4 ring-white dark:ring-slate-800">
                                                                    <div className="w-2 h-2 rounded-full bg-blue-400 dark:bg-blue-500" />
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
                                                                    {new Date(
                                                                        log.created_at,
                                                                    ).toLocaleString()}
                                                                </p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </li>
                                            ))}
                                        {(!loan.logs || loan.logs.length === 0) && (
                                            <li className="text-sm text-gray-500 dark:text-slate-400 italic text-center py-4">
                                                No activity recorded.
                                            </li>
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

export default LoanDetailsPage;
