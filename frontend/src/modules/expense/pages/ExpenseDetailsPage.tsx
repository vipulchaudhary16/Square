import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getExpenseDetails, deleteExpense, addComment, Expense } from '../../../api/expenses';
import useApiCall from '../../../hooks/useApiCall';
import { Loader2, Trash2, Edit2, Send, MessageSquare, History, ArrowLeft, Calendar, User, CreditCard } from 'lucide-react';
import { AddExpenseForm } from '../components/AddExpenseForm';
import { useSession } from '../../../hooks/useSession';
import { DropdownMenu } from '../../common/components/ui/DropdownMenu';

interface ActivityLog {
    id: string;
    action: string;
    details: string;
    created_at: string;
    user_id: string;
}

interface Comment {
    id: string;
    text: string;
    created_at: string;
    user_id: string;
    username?: string;
}

interface ExpenseDetails extends Expense {
    logs: ActivityLog[];
    comments: Comment[];
    users: Record<string, string>;
}

const ExpenseDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    useSession();
    const [expense, setExpense] = useState<ExpenseDetails | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [newComment, setNewComment] = useState('');
    const [activeTab, setActiveTab] = useState<'comments' | 'activity' | 'split'>('split');

    const { execute: fetchDetails, loading } = useApiCall({
        apiCall: () => getExpenseDetails(id!)
    });

    const { execute: executeDelete } = useApiCall({
        apiCall: () => deleteExpense(id!)
    });

    const { execute: executeAddComment, loading: commentLoading } = useApiCall({
        apiCall: (text: string) => addComment(id!, text)
    });

    const loadData = async () => {
        try {
            const response = await fetchDetails();
            setExpense({
                ...response.expense,
                logs: response.logs || [],
                comments: response.comments || [],
                users: response.users || {}
            });
        } catch (error) {
            console.error("Failed to load expense details", error);
        }
    };

    useEffect(() => {
        if (id) loadData();
    }, [id]);

    const handleDelete = async () => {
        if (window.confirm("Are you sure you want to delete this expense?")) {
            try {
                await executeDelete();
                navigate(-1);
            } catch (error) {
                alert("Failed to delete expense");
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

    const getUserName = (userId: string) => {
        return expense?.users?.[userId] || `User ${userId.slice(-4)}`;
    };

    if (loading && !expense) {
        return (
            <div className="flex justify-center items-center h-screen">
                <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
            </div>
        );
    }

    if (!expense) return <div className="p-8 text-center">Expense not found</div>;

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
                                label: 'Edit Expense',
                                icon: <Edit2 className="w-4 h-4" />,
                                onClick: () => setIsEditing(true)
                            },
                            {
                                label: 'Delete Expense',
                                icon: <Trash2 className="w-4 h-4" />,
                                variant: 'danger',
                                onClick: handleDelete
                            }
                        ]}
                    />
                )}
            </div>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Edit Expense</h2>
                        <button
                            onClick={() => setIsEditing(false)}
                            className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 font-medium"
                        >
                            Cancel
                        </button>
                    </div>
                    <AddExpenseForm
                        initialData={expense}
                        onSuccess={() => {
                            setIsEditing(false);
                            loadData();
                        }}
                    />
                </div>
            ) : (
                <div className="space-y-8 animate-fade-in">

                    <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-500/10 to-purple-500/10 rounded-bl-full -mr-8 -mt-8 pointer-events-none" />

                        <div className="relative">
                            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 mb-6">
                                <div>
                                    <div className="flex items-center gap-2 mb-3">
                                        <span className="px-3 py-1 rounded-full text-xs font-semibold bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border border-blue-100 dark:border-blue-800/50 uppercase tracking-wide">
                                            {expense.category}
                                        </span>
                                        {expense.group_id && (
                                            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 border border-purple-100 dark:border-purple-800/50 uppercase tracking-wide">
                                                Group Expense
                                            </span>
                                        )}
                                    </div>
                                    <h1 className="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-2">{expense.description}</h1>
                                </div>
                                <div className="text-left md:text-right">
                                    <div className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white tracking-tight">₹{expense.amount.toFixed(2)}</div>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-6 border-t border-gray-100 dark:border-slate-700">
                                <div className="flex items-center gap-3 text-gray-600 dark:text-slate-300">
                                    <div className="w-10 h-10 rounded-full bg-gray-50 dark:bg-slate-700 flex items-center justify-center text-gray-400 dark:text-slate-400">
                                        <User className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 dark:text-slate-500 uppercase font-semibold tracking-wider">Paid By</p>
                                        <p className="font-medium">{getUserName(expense.payer_id)}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-3 text-gray-600 dark:text-slate-300">
                                    <div className="w-10 h-10 rounded-full bg-gray-50 dark:bg-slate-700 flex items-center justify-center text-gray-400 dark:text-slate-400">
                                        <Calendar className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 dark:text-slate-500 uppercase font-semibold tracking-wider">Date</p>
                                        <p className="font-medium">{new Date(expense.date).toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                                    </div>
                                </div>
                            </div>
                        </div>


                        <div className="border-b border-gray-200 dark:border-slate-700 overflow-x-auto">
                            <nav className="-mb-px flex space-x-8 min-w-max" aria-label="Tabs">
                                <button
                                    onClick={() => setActiveTab('split')}
                                    className={`${activeTab === 'split'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-300 hover:border-gray-300'
                                        } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 transition-colors`}
                                >
                                    <CreditCard className="w-4 h-4" />
                                    Split Details
                                </button>
                                <button
                                    onClick={() => setActiveTab('comments')}
                                    className={`${activeTab === 'comments'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-300 hover:border-gray-300'
                                        } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 transition-colors`}
                                >
                                    <MessageSquare className="w-4 h-4" />
                                    Comments
                                    <span className="bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 py-0.5 px-2 rounded-full text-xs">
                                        {expense.comments?.length || 0}
                                    </span>
                                </button>
                                <button
                                    onClick={() => setActiveTab('activity')}
                                    className={`${activeTab === 'activity'
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
                            {activeTab === 'split' && (
                                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-4 md:p-8 animate-fade-in">
                                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
                                        <CreditCard className="w-5 h-5 text-gray-400" />
                                        Split Details
                                        <span className="ml-auto text-xs font-normal text-gray-500 dark:text-slate-400 bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded-md">
                                            {expense.split_type} Split
                                        </span>
                                    </h3>

                                    <div className="space-y-4">
                                        {expense.splits && Object.entries(expense.splits).map(([userId, amount]) => (
                                            <div key={userId} className="flex justify-between items-center p-3 rounded-xl bg-gray-50 dark:bg-slate-700/50 border border-transparent hover:border-gray-200 dark:hover:border-slate-600 transition-colors">
                                                <div className="flex items-center gap-3 min-w-0 flex-1 mr-4">
                                                    <div className="w-8 h-8 rounded-full bg-white dark:bg-slate-600 flex-shrink-0 flex items-center justify-center text-xs font-bold text-gray-500 dark:text-slate-300 shadow-sm">
                                                        {getUserName(userId).charAt(0).toUpperCase()}
                                                    </div>
                                                    <span className="font-medium text-gray-700 dark:text-slate-200 truncate">{getUserName(userId)}</span>
                                                </div>
                                                <span className="font-bold text-gray-900 dark:text-white whitespace-nowrap">₹{amount.toFixed(2)}</span>
                                            </div>
                                        ))}
                                        {!expense.splits && (
                                            <div className="text-center py-8 text-gray-500 dark:text-slate-400 bg-gray-50 dark:bg-slate-700/30 rounded-xl border border-dashed border-gray-200 dark:border-slate-700">
                                                No detailed split info available.
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            {activeTab === 'comments' && (
                                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                                    <div className="space-y-4 mb-6 max-h-[500px] overflow-y-auto pr-2 custom-scrollbar">
                                        {expense.comments && expense.comments.length > 0 ? (
                                            expense.comments.map(comment => (
                                                <div key={comment.id} className="flex gap-3 group">
                                                    <div className="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex-shrink-0 flex items-center justify-center text-xs font-bold text-blue-600 dark:text-blue-400">
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
                                            className="block w-full rounded-xl border-gray-200 dark:border-slate-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm py-3 pl-4 pr-12 border bg-gray-50 dark:bg-slate-900/50 text-gray-900 dark:text-white transition-all focus:bg-white dark:focus:bg-slate-800"
                                        />
                                        <button
                                            type="submit"
                                            disabled={commentLoading || !newComment.trim()}
                                            className="absolute right-2 top-1.5 p-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 dark:disabled:bg-slate-700 disabled:cursor-not-allowed transition-colors shadow-sm"
                                        >
                                            {commentLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                                        </button>
                                    </form>
                                </div>
                            )}

                            {activeTab === 'activity' && (
                                <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-8 animate-fade-in">
                                    <div className="flow-root">
                                        <ul className="">
                                            {expense.logs && expense.logs.map((log, logIdx) => (
                                                <li key={log.id}>
                                                    <div className="relative pb-8">
                                                        {logIdx !== expense.logs.length - 1 ? (
                                                            <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-100 dark:bg-slate-700" aria-hidden="true" />
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
                                                                    {new Date(log.created_at).toLocaleString()}
                                                                </p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </li>
                                            ))}
                                            {(!expense.logs || expense.logs.length === 0) && (
                                                <li className="text-sm text-gray-500 dark:text-slate-400 italic text-center py-4">No activity recorded.</li>
                                            )}
                                        </ul>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ExpenseDetailsPage;
