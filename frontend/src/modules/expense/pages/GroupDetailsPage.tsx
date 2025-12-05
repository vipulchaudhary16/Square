import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Users, Mail, ArrowLeft, Calendar, User as UserIcon, Search, Plus, ArrowRight } from 'lucide-react';
import useFetchData from '../../../hooks/useFetchData';
import useApiCall from '../../../hooks/useApiCall';
import { getGroupDetails, inviteUser, addMember, GroupDetails } from '../../../api/groups';
import { searchUsers, User } from '../../../api/users';
import { getGroupExpenses, Expense } from '../../../api/expenses';

import { useSession } from '../../../hooks/useSession';

import { ExpenseReport } from '../../report/components/ExpenseReport';
import { Modal } from '../../common/components/ui/Modal';
import { AddExpenseForm } from '../components/AddExpenseForm';

export const GroupDetailsPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { user } = useSession();
    const [inviteEmail, setInviteEmail] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const [searchResults, setSearchResults] = useState<User[]>([]);
    const [activeTab, setActiveTab] = useState<'expenses' | 'members' | 'reports' | 'balances'>('expenses');
    const [showAddMember, setShowAddMember] = useState(false);
    const [isAddExpenseModalOpen, setIsAddExpenseModalOpen] = useState(false);
    const [expenseSearchQuery, setExpenseSearchQuery] = useState('');

    const { data, loading, error, refetch } = useFetchData({
        apiCall: () => getGroupDetails(id!)
    });

    const [debouncedSearchQuery, setDebouncedSearchQuery] = useState('');

    
    React.useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedSearchQuery(expenseSearchQuery);
        }, 500);
        return () => clearTimeout(timer);
    }, [expenseSearchQuery]);

    const { data: expenses, loading: expensesLoading, refetch: refetchExpenses } = useFetchData({
        apiCall: () => getGroupExpenses(id!, undefined, undefined, undefined, debouncedSearchQuery),
        dependencies: [id, debouncedSearchQuery]
    });

    const [reportExpenses, setReportExpenses] = useState<Expense[]>([]);
    const [reportLoading, setReportLoading] = useState(false);

    const fetchReportExpenses = async (startDate: string, endDate: string, category?: string) => {
        if (!id) return;
        setReportLoading(true);
        try {
            const data = await getGroupExpenses(id, startDate, endDate, category);
            setReportExpenses(data || []);
        } catch (error) {
            console.error("Failed to fetch group report expenses", error);
        } finally {
            setReportLoading(false);
        }
    };

    
    

    const { execute: executeInvite, loading: inviteLoading } = useApiCall({
        apiCall: (email: string) => inviteUser(id!, email)
    });

    const { execute: executeAddMember, loading: addMemberLoading } = useApiCall({
        apiCall: (userId: string) => addMember(id!, userId)
    });

    const handleInvite = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await executeInvite(inviteEmail);
            alert('Invitation sent!');
            setInviteEmail('');
        } catch (err) {
            alert('Failed to send invitation');
        }
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!searchQuery.trim()) return;
        try {
            const results = await searchUsers(searchQuery);
            setSearchResults(results);
        } catch (err) {
            console.error(err);
        }
    };

    const handleAddMember = async (userId: string) => {
        try {
            await executeAddMember(userId);
            alert('Member added!');
            setSearchResults([]);
            setSearchQuery('');
            refetch(undefined);
        } catch (err) {
            alert('Failed to add member');
        }
    };

    const getSplitDetails = (expense: Expense) => {
        if (!user) return null;

        
        if (expense.splits && expense.splits[user.id] !== undefined) {
            const myShare = expense.splits[user.id];

            if (expense.payer_id === user.id) {
                
                const lentAmount = expense.amount - myShare;
                if (lentAmount <= 0.01) return <span className="text-gray-500 text-xs">You paid for yourself</span>;
                return <span className="text-green-600 text-xs font-medium">You lent ₹{lentAmount.toFixed(2)}</span>;
            } else {
                
                if (myShare <= 0) return <span className="text-gray-400 text-xs">Not involved</span>;
                return <span className="text-red-600 text-xs font-medium">You owe ₹{myShare.toFixed(2)}</span>;
            }
        }

        
        const participants = expense.participants || [];
        const splitAmount = expense.amount / (participants.length || 1);

        if (expense.payer_id === user.id) {
            const myShare = participants.includes(user.id) ? splitAmount : 0;
            const lentAmount = expense.amount - myShare;
            if (lentAmount <= 0) return <span className="text-gray-500 text-xs">You paid for yourself</span>;
            return <span className="text-green-600 text-xs font-medium">You lent ₹{lentAmount.toFixed(2)}</span>;
        } else if (participants.includes(user.id)) {
            return <span className="text-red-600 text-xs font-medium">You owe ₹{splitAmount.toFixed(2)}</span>;
        } else {
            return <span className="text-gray-400 text-xs">Not involved</span>;
        }
    };

    const groupDetails = data as GroupDetails;

    const myBalance = React.useMemo(() => {
        if (!user || !groupDetails?.debts) return 0;
        let balance = 0;
        groupDetails.debts.forEach(debt => {
            if (debt.from === user.id) balance -= debt.amount;
            if (debt.to === user.id) balance += debt.amount;
        });
        return balance;
    }, [user, groupDetails]);

    if (loading) return <div className="p-12 text-center">Loading...</div>;
    if (error || !data) return <div className="p-12 text-center text-red-500">Group not found</div>;

    return (
        <div>
            {}
            <button
                onClick={() => navigate('/groups')}
                className="flex items-center text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 mb-6"
            >
                <ArrowLeft className="w-4 h-4 mr-1" /> Back to Groups
            </button>

            <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden mb-6">
                <div className="p-4 md:p-8 border-b border-gray-100 dark:border-slate-700">
                    <div className="flex flex-col md:flex-row justify-between items-start gap-4">
                        <div>
                            <h1 className="text-2xl md:text-3xl font-bold text-gray-900 dark:text-white mb-2">{groupDetails.group.name}</h1>
                            <p className="text-gray-500 dark:text-slate-400 text-base md:text-lg">{groupDetails.group.description}</p>

                            {}
                            <div className="mt-2 flex items-center gap-2">
                                <span className="text-sm text-gray-500 dark:text-slate-400">Your Net Balance:</span>
                                <span className={`text-sm font-bold px-2 py-0.5 rounded-full ${Math.abs(myBalance) < 0.01
                                    ? 'bg-gray-100 text-gray-600 dark:bg-slate-700 dark:text-slate-300'
                                    : myBalance > 0
                                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                        : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                                    }`}>
                                    {Math.abs(myBalance) < 0.01 ? 'Settled' : (myBalance > 0 ? `+₹${myBalance.toFixed(2)}` : `-₹${Math.abs(myBalance).toFixed(2)}`)}
                                </span>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 w-full md:w-auto justify-end">
                            <div className="bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 px-3 py-2 rounded-lg flex items-center gap-2 font-medium">
                                <Users className="w-5 h-5" />
                                <span className="hidden sm:inline">{groupDetails.members.length} Members</span>
                                <span className="sm:hidden">{groupDetails.members.length}</span>
                            </div>
                            <button
                                onClick={() => setIsAddExpenseModalOpen(true)}
                                className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm text-sm font-medium"
                            >
                                <Plus className="w-4 h-4" />
                                <span className="hidden sm:inline">Add Expense</span>
                                <span className="sm:hidden">Add</span>
                            </button>
                        </div>
                    </div>
                    <div className="flex items-center gap-4 mt-6 text-sm text-gray-500 dark:text-slate-400">
                        <div className="flex items-center gap-1">
                            <Calendar className="w-4 h-4" />
                            Created {new Date(groupDetails.group.created_at).toLocaleDateString()}
                        </div>
                    </div>
                </div>

                {}
                <div className="flex border-b border-gray-200 dark:border-slate-700 px-6 overflow-x-auto whitespace-nowrap scrollbar-hide">
                    <button
                        onClick={() => setActiveTab('expenses')}
                        className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${activeTab === 'expenses'
                            ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
                            : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 hover:border-gray-300 dark:hover:border-slate-600'
                            }`}
                    >
                        Expenses
                    </button>
                    <button
                        onClick={() => setActiveTab('members')}
                        className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${activeTab === 'members'
                            ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
                            : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 hover:border-gray-300 dark:hover:border-slate-600'
                            }`}
                    >
                        Members
                    </button>
                    <button
                        onClick={() => {
                            setActiveTab('reports');
                            if (reportExpenses.length === 0 && expenses) {
                                setReportExpenses(expenses);
                            }
                        }}
                        className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${activeTab === 'reports'
                            ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
                            : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 hover:border-gray-300 dark:hover:border-slate-600'
                            }`}
                    >
                        Reports
                    </button>
                    <button
                        onClick={() => setActiveTab('balances')}
                        className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${activeTab === 'balances'
                            ? 'border-blue-600 text-blue-600 dark:text-blue-400 dark:border-blue-400'
                            : 'border-transparent text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200 hover:border-gray-300 dark:hover:border-slate-600'
                            }`}
                    >
                        Balances
                    </button>
                </div>
            </div>

            {activeTab === 'expenses' && (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <div className="lg:col-span-3">
                        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Expenses</h2>
                            <div className="relative w-full sm:w-64">
                                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                                <input
                                    type="text"
                                    placeholder="Search expenses..."
                                    value={expenseSearchQuery}
                                    onChange={(e) => setExpenseSearchQuery(e.target.value)}
                                    className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all"
                                />
                            </div>
                        </div>

                        {expensesLoading ? (
                            <div className="text-center p-8 text-gray-500 dark:text-slate-400">Loading expenses...</div>
                        ) : !expenses || expenses.length === 0 ? (
                            <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-8 text-center text-gray-500 dark:text-slate-400">
                                No expenses recorded in this group yet.
                            </div>
                        ) : (
                            <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden">
                                <ul className="divide-y divide-gray-100 dark:divide-slate-700">
                                    {expenses.map((expense: Expense) => (
                                        <li key={expense.id} className="p-4 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors cursor-pointer" onClick={() => navigate(`/expenses/${expense.id}`)}>
                                            <div className="flex justify-between items-center">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900/20 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-bold">
                                                        {expense.category.charAt(0)}
                                                    </div>
                                                    <div>
                                                        <p className="font-medium text-gray-900 dark:text-white">{expense.description}</p>
                                                        <p className="text-xs text-gray-500 dark:text-slate-400">
                                                            Paid by {(() => {
                                                                const payer = groupDetails.members.find(m => m.id === expense.payer_id);
                                                                if (payer?.first_name) {
                                                                    return `${payer.first_name} ${payer.last_name}`;
                                                                }
                                                                return payer?.username || 'Unknown';
                                                            })()} • {new Date(expense.date).toLocaleString()}
                                                        </p>
                                                    </div>
                                                </div>
                                                <div className="text-right">
                                                    <p className="font-bold text-gray-900 dark:text-white">₹{expense.amount.toFixed(2)}</p>
                                                    {getSplitDetails(expense)}
                                                </div>
                                            </div>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {activeTab === 'members' && (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <div className="lg:col-span-2">
                        <div className="flex justify-between items-center mb-4">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">Members</h2>
                            <button
                                onClick={() => setShowAddMember(!showAddMember)}
                                className="text-blue-600 dark:text-blue-400 text-sm font-medium hover:text-blue-700 dark:hover:text-blue-300"
                            >
                                {showAddMember ? 'Cancel' : '+ Add Member'}
                            </button>
                        </div>

                        {showAddMember && (
                            <div className="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 mb-4">
                                {}
                                <div className="flex border-b border-gray-100 dark:border-slate-700 mb-4">
                                    <button
                                        onClick={() => setActiveTab('search' as any)} 
                                        className={`flex-1 pb-2 text-sm font-medium text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400`}
                                    >
                                        Search / Invite
                                    </button>
                                </div>

                                <div className="space-y-4">
                                    <form onSubmit={handleSearch} className="flex gap-2">
                                        <input
                                            type="text"
                                            value={searchQuery}
                                            onChange={(e) => setSearchQuery(e.target.value)}
                                            className="flex-1 rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                                            placeholder="Search by name or email"
                                        />
                                        <button type="submit" className="bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 px-3 py-2 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600">
                                            <Search className="w-4 h-4" />
                                        </button>
                                    </form>

                                    {searchResults.length > 0 && (
                                        <ul className="space-y-2 max-h-40 overflow-y-auto">
                                            {searchResults.map(user => (
                                                <li key={user.id} className="flex justify-between items-center p-2 bg-gray-50 dark:bg-slate-700 rounded-md">
                                                    <div className="text-sm overflow-hidden">
                                                        <p className="font-medium truncate text-gray-900 dark:text-white">{user.username}</p>
                                                        <p className="text-xs text-gray-500 dark:text-slate-400 truncate">{user.email}</p>
                                                    </div>
                                                    <button onClick={() => handleAddMember(user.id)} disabled={addMemberLoading} className="text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-slate-600 p-1 rounded">
                                                        <Plus className="w-4 h-4" />
                                                    </button>
                                                </li>
                                            ))}
                                        </ul>
                                    )}

                                    <div className="border-t border-gray-100 dark:border-slate-700 pt-4">
                                        <form onSubmit={handleInvite}>
                                            <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1">Or Invite by Email</label>
                                            <div className="flex gap-2">
                                                <input
                                                    type="email"
                                                    required
                                                    value={inviteEmail}
                                                    onChange={(e) => setInviteEmail(e.target.value)}
                                                    className="flex-1 rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                                                    placeholder="friend@example.com"
                                                />
                                                <button type="submit" disabled={inviteLoading} className="bg-blue-600 text-white px-3 py-2 rounded-md text-sm font-medium hover:bg-blue-700 disabled:opacity-50">
                                                    <Mail className="w-4 h-4" />
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        )}

                        <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden">
                            <ul className="divide-y divide-gray-100 dark:divide-slate-700">
                                {groupDetails.members.map((member) => (
                                    <li key={member.id} className="p-4 flex items-center gap-3">
                                        <div className="w-10 h-10 bg-gray-100 dark:bg-slate-700 rounded-full flex items-center justify-center">
                                            <UserIcon className="w-5 h-5 text-gray-500 dark:text-slate-400" />
                                        </div>
                                        <div>
                                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                                                {(member.first_name)
                                                    ? `${member.first_name} ${member.last_name}`
                                                    : (member.username || "User")}
                                            </p>
                                            <p className="text-xs text-gray-500 dark:text-slate-400">{member.email}</p>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </div>
            )}

            {activeTab === 'reports' && (
                <div className="mt-6">
                    <ExpenseReport
                        expenses={reportExpenses}
                        isLoading={reportLoading}
                        onFilterChange={fetchReportExpenses}
                    />
                </div>
            )}

            {activeTab === 'balances' && (
                <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6">
                        <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Balances</h2>
                        {!groupDetails.debts || groupDetails.debts.length === 0 ? (
                            <div className="text-center text-gray-500 dark:text-slate-400 py-8">
                                No debts found. Everyone is settled up!
                            </div>
                        ) : (
                            <ul className="space-y-4">
                                {groupDetails.debts.map((debt, index) => {
                                    const fromUser = groupDetails.members.find(m => m.id === debt.from);
                                    const toUser = groupDetails.members.find(m => m.id === debt.to);
                                    return (
                                        <li key={index} className="flex flex-col sm:flex-row sm:items-center justify-between p-3 bg-gray-50 dark:bg-slate-700/50 rounded-lg gap-2 sm:gap-0">
                                            <div className="flex items-center justify-between w-full sm:w-auto gap-4">
                                                <div className="flex items-center gap-2 min-w-0">
                                                    <div className="w-8 h-8 bg-red-100 dark:bg-red-900/20 rounded-full flex-shrink-0 flex items-center justify-center text-red-600 dark:text-red-400 font-bold text-xs">
                                                        {fromUser?.username?.charAt(0).toUpperCase() || '?'}
                                                    </div>
                                                    <span className="text-sm font-medium text-gray-900 dark:text-white truncate max-w-[80px] sm:max-w-[120px]">
                                                        {fromUser?.username || 'Unknown'}
                                                    </span>
                                                </div>

                                                <div className="flex flex-col items-center px-2">
                                                    <span className="text-[10px] text-gray-500 dark:text-slate-400 uppercase tracking-wider">owes</span>
                                                    <ArrowRight className="w-4 h-4 text-gray-400" />
                                                </div>

                                                <div className="flex items-center gap-2 min-w-0 justify-end">
                                                    <span className="text-sm font-medium text-gray-900 dark:text-white truncate max-w-[80px] sm:max-w-[120px] text-right">
                                                        {toUser?.username || 'Unknown'}
                                                    </span>
                                                    <div className="w-8 h-8 bg-green-100 dark:bg-green-900/20 rounded-full flex-shrink-0 flex items-center justify-center text-green-600 dark:text-green-400 font-bold text-xs">
                                                        {toUser?.username?.charAt(0).toUpperCase() || '?'}
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="font-bold text-gray-900 dark:text-white text-right sm:ml-4 border-t sm:border-t-0 border-gray-200 dark:border-slate-600 pt-2 sm:pt-0 mt-1 sm:mt-0">
                                                ₹{debt.amount.toFixed(2)}
                                            </div>
                                        </li>
                                    );
                                })}
                            </ul>
                        )}
                    </div>
                </div>
            )}

            <Modal
                isOpen={isAddExpenseModalOpen}
                onClose={() => setIsAddExpenseModalOpen(false)}
                title="Add Group Expense"
            >
                <AddExpenseForm
                    defaultGroupId={id}
                    onSuccess={() => {
                        setIsAddExpenseModalOpen(false);
                        refetchExpenses(undefined);
                    }}
                />
            </Modal>
        </div>
    );
};
