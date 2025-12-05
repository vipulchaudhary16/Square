import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getExpenseDetails, deleteExpense, addComment, Expense } from '../../../api/expenses';
import useApiCall from '../../../hooks/useApiCall';
import { Loader2, Trash2, Edit2, Send, MessageSquare, History, ArrowLeft } from 'lucide-react';
import { AddExpenseForm } from '../components/AddExpenseForm';
import { useSession } from '../../../hooks/useSession';

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

    const { execute: fetchDetails, loading } = useApiCall({
        apiCall: () => getExpenseDetails(id!)
    });

    const { execute: executeDelete, loading: deleteLoading } = useApiCall({
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
        <div className="max-w-4xl mx-auto p-4 pb-20">
            <button
                onClick={() => navigate(-1)}
                className="flex items-center text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-white mb-6 transition-colors"
            >
                <ArrowLeft className="w-4 h-4 mr-2" /> Back
            </button>

            {isEditing ? (
                <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6">
                    <div className="flex justify-between items-center mb-4">
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Edit Expense</h2>
                        <button onClick={() => setIsEditing(false)} className="text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200">Cancel</button>
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
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {}
                    <div className="md:col-span-2 space-y-6">
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6">
                            <div className="flex justify-between items-start">
                                <div>
                                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{expense.description}</h1>
                                    <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">
                                        Paid by <span className="font-medium text-gray-900 dark:text-white">{getUserName(expense.payer_id)}</span> on {new Date(expense.date).toLocaleString()}
                                    </p>
                                    <div className="mt-4 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/20 text-blue-800 dark:text-blue-300">
                                        {expense.category}
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className="text-3xl font-bold text-gray-900 dark:text-white">₹{expense.amount.toFixed(2)}</div>
                                    <div className="text-sm text-gray-500 dark:text-slate-400 mt-1">{expense.split_type} Split</div>
                                </div>
                            </div>

                            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-slate-700">
                                <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-4">Split Details</h3>
                                <div className="space-y-3">
                                    {expense.splits && Object.entries(expense.splits).map(([userId, amount]) => (
                                        <div key={userId} className="flex justify-between items-center text-sm">
                                            <span className="text-gray-600 dark:text-slate-300">{getUserName(userId)}</span>
                                            <span className="font-medium text-gray-900 dark:text-white">₹{amount.toFixed(2)}</span>
                                        </div>
                                    ))}
                                    {!expense.splits && (
                                        <p className="text-sm text-gray-500 dark:text-slate-400 italic">No detailed split info available.</p>
                                    )}
                                </div>
                            </div>

                            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-slate-700 flex gap-3">
                                <button
                                    onClick={() => setIsEditing(true)}
                                    className="flex-1 flex items-center justify-center px-4 py-2 border border-gray-300 dark:border-slate-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-slate-200 bg-white dark:bg-slate-700 hover:bg-gray-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                                >
                                    <Edit2 className="w-4 h-4 mr-2" /> Edit
                                </button>
                                <button
                                    onClick={handleDelete}
                                    disabled={deleteLoading}
                                    className="flex-1 flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                                >
                                    {deleteLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Trash2 className="w-4 h-4 mr-2" /> Delete</>}
                                </button>
                            </div>
                        </div>

                        {}
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
                                <MessageSquare className="w-5 h-5 mr-2" /> Comments
                            </h3>

                            <div className="space-y-4 mb-6 max-h-60 overflow-y-auto">
                                {expense.comments && expense.comments.length > 0 ? (
                                    expense.comments.map(comment => (
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
                    <div className="md:col-span-1">
                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
                                <History className="w-5 h-5 mr-2" /> Activity Log
                            </h3>
                            <div className="flow-root">
                                <ul className="-mb-8">
                                    {expense.logs && expense.logs.map((log, logIdx) => (
                                        <li key={log.id}>
                                            <div className="relative pb-8">
                                                {logIdx !== expense.logs.length - 1 ? (
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
                                    {(!expense.logs || expense.logs.length === 0) && (
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

export default ExpenseDetailsPage;
