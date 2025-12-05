
import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { cn } from './ExpenseCard';
import useApiCall from '../../../hooks/useApiCall';
import { createExpense, updateExpense, Expense } from '../../../api/expenses';
import { getUserGroups, getGroupDetails, Group } from '../../../api/groups';
import { Loader2, Sparkles, Users, ChevronRight } from 'lucide-react';
import { suggestCategory, isAIEnabled } from '../../../services/ai';
import { Drawer } from '../../common/components/ui/Drawer';

interface ExpenseFormInputs {
    description: string;
    amount: number;
    category: string;
    date: string;
    group_id?: string;
    add_to_personal?: boolean;
}

interface AddExpenseFormProps {
    onSuccess?: () => void;
    initialData?: Expense;
    defaultGroupId?: string;
}

interface Member {
    id: string;
    username: string;
    email: string;
}

export const AddExpenseForm: React.FC<AddExpenseFormProps> = ({ onSuccess, initialData, defaultGroupId }) => {
    const [mode, setMode] = useState<'personal' | 'group'>('personal');
    const [groups, setGroups] = useState<Group[]>([]);
    const [selectedGroupId, setSelectedGroupId] = useState<string>('');
    const [groupMembers, setGroupMembers] = useState<Member[]>([]);
    const [selectedParticipants, setSelectedParticipants] = useState<string[]>([]);

    
    const [splitType, setSplitType] = useState<'EQUAL' | 'EXACT' | 'PERCENT'>('EQUAL');
    const [splitValues, setSplitValues] = useState<Record<string, number>>({});

    const [loadingGroups, setLoadingGroups] = useState(false);
    const [loadingMembers, setLoadingMembers] = useState(false);
    const [isSuggesting, setIsSuggesting] = useState(false);
    const [isSplitDrawerOpen, setIsSplitDrawerOpen] = useState(false);

    const { register, handleSubmit, reset, watch, setValue } = useForm<ExpenseFormInputs>();
    const amount = watch('amount');

    const handleSuggestCategory = async () => {
        const desc = watch('description');
        if (!desc) return;

        setIsSuggesting(true);
        const category = await suggestCategory(desc);
        setIsSuggesting(false);

        if (category) {
            setValue('category', category);
        }
    };

    const { execute: executeCreateExpense, loading: createLoading } = useApiCall({
        apiCall: createExpense
    });

    const { execute: executeUpdateExpense, loading: updateLoading } = useApiCall({
        apiCall: (data: any) => updateExpense(initialData!.id, data)
    });

    const loading = createLoading || updateLoading;

    useEffect(() => {
        if (initialData) {
            setValue('description', initialData.description);
            setValue('amount', initialData.amount);
            setValue('category', initialData.category);
            setValue('date', new Date(initialData.date).toISOString().slice(0, 16));

            if (initialData.group_id) {
                setMode('group');
                setSelectedGroupId(initialData.group_id);
                
            } else {
                setMode('personal');
            }
        } else {
            
            const now = new Date();
            now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
            setValue('date', now.toISOString().slice(0, 16));

            if (defaultGroupId) {
                setMode('group');
                setSelectedGroupId(defaultGroupId);
            }
            setValue('category', 'Other');
        }
    }, [initialData, setValue, defaultGroupId]);

    useEffect(() => {
        const fetchGroups = async () => {
            setLoadingGroups(true);
            try {
                const res = await getUserGroups();
                setGroups(res || []);
            } catch (err) {
                console.error("Failed to fetch groups", err);
            } finally {
                setLoadingGroups(false);
            }
        };
        fetchGroups();
    }, []);

    useEffect(() => {
        if (selectedGroupId) {
            const fetchMembers = async () => {
                setLoadingMembers(true);
                try {
                    const res = await getGroupDetails(selectedGroupId);
                    setGroupMembers(res.members || []);

                    if (initialData && initialData.group_id === selectedGroupId) {
                        
                        setSelectedParticipants(initialData.participants || []);
                        setSplitType((initialData.split_type as any) || 'EQUAL');
                        setSplitValues(initialData.splits || {});
                    } else if (!initialData) {
                        
                        const allMemberIds = res.members.map((m: Member) => m.id);
                        setSelectedParticipants(allMemberIds);

                        
                        const initialSplits: Record<string, number> = {};
                        allMemberIds.forEach((id: string) => initialSplits[id] = 0);
                        setSplitValues(initialSplits);
                    }

                } catch (err) {
                    console.error("Failed to fetch group members", err);
                } finally {
                    setLoadingMembers(false);
                }
            };
            fetchMembers();
        } else {
            setGroupMembers([]);
            if (!initialData) {
                setSelectedParticipants([]);
                setSplitValues({});
            }
        }
    }, [selectedGroupId, initialData]);

    const handleParticipantToggle = (userId: string) => {
        setSelectedParticipants(prev => {
            const newParticipants = prev.includes(userId)
                ? prev.filter(id => id !== userId)
                : [...prev, userId];

            
            setSplitValues(prevSplits => ({
                ...prevSplits,
                [userId]: 0
            }));

            return newParticipants;
        });
    };

    const handleSplitValueChange = (userId: string, value: string) => {
        setSplitValues(prev => ({
            ...prev,
            [userId]: parseFloat(value) || 0
        }));
    };

    const getRunningTotal = () => {
        return Object.entries(splitValues)
            .filter(([id]) => selectedParticipants.includes(id))
            .reduce((sum, [_, val]) => sum + val, 0);
    };

    const onSubmit = async (data: ExpenseFormInputs) => {
        if (mode === 'group') {
            if (!selectedGroupId) {
                alert("Please select a group");
                return;
            }
            if (selectedParticipants.length === 0) {
                alert("Please select at least one participant");
                return;
            }

            
            if (splitType === 'EXACT') {
                const total = getRunningTotal();
                if (Math.abs(total - Number(data.amount)) > 0.01) {
                    alert(`Total split amount (${total}) must equal expense amount (${data.amount})`);
                    return;
                }
            } else if (splitType === 'PERCENT') {
                const total = getRunningTotal();
                if (Math.abs(total - 100) > 0.01) {
                    alert(`Total percentage (${total}%) must equal 100%`);
                    return;
                }
            }
        }

        const payload = {
            ...data,
            amount: Number(data.amount),
            date: new Date(data.date).toISOString(),
            group_id: mode === 'group' ? selectedGroupId : undefined,
            participants: mode === 'group' ? selectedParticipants : [],
            split_type: mode === 'group' ? splitType : undefined,
            splits: mode === 'group' ? splitValues : undefined
        };

        try {
            if (initialData) {
                await executeUpdateExpense(payload);
                alert("Expense updated!");
            } else {
                await executeCreateExpense(payload);
                alert("Expense added!");
                reset();
                setSplitValues({});
            }
            if (onSuccess) onSuccess();
        } catch (error) {
            alert("Failed to save expense");
        }
    };

    return (
        <div className="w-full">
            {!defaultGroupId && (
                <div className="flex mb-6 bg-gray-100 dark:bg-slate-700 p-1 rounded-lg">
                    <button
                        onClick={() => setMode('personal')}
                        className={cn(
                            "flex-1 py-2 rounded-md text-sm font-medium transition-all",
                            mode === 'personal' ? "bg-white dark:bg-slate-600 shadow text-gray-900 dark:text-white" : "text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200"
                        )}
                    >
                        Personal
                    </button>
                    <button
                        onClick={() => setMode('group')}
                        className={cn(
                            "flex-1 py-2 rounded-md text-sm font-medium transition-all",
                            mode === 'group' ? "bg-white dark:bg-slate-600 shadow text-gray-900 dark:text-white" : "text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200"
                        )}
                    >
                        Group
                    </button>
                </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Amount</label>
                    <div className="relative mt-1 rounded-md shadow-sm">
                        <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                            <span className="text-gray-500 dark:text-slate-400 sm:text-sm">₹</span>
                        </div>
                        <input
                            type="number"
                            step="0.01"
                            {...register("amount", { required: true })}
                            className="block w-full rounded-md border-gray-300 dark:border-slate-600 pl-7 pr-12 focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                            placeholder="0.00"
                        />
                    </div>
                </div>

                {mode === 'group' && (
                    <div className="space-y-4 pt-2 border-t border-gray-100 dark:border-slate-700">
                        {!defaultGroupId && (
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">Select Group</label>
                                {loadingGroups ? (
                                    <div className="text-sm text-gray-500 dark:text-slate-400 flex items-center gap-2">
                                        <Loader2 className="w-4 h-4 animate-spin" /> Loading groups...
                                    </div>
                                ) : (
                                    <select
                                        value={selectedGroupId}
                                        onChange={(e) => setSelectedGroupId(e.target.value)}
                                        className="block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                                    >
                                        <option value="">-- Select a Group --</option>
                                        {groups.map(g => (
                                            <option key={g.id} value={g.id}>{g.name}</option>
                                        ))}
                                    </select>
                                )}
                            </div>
                        )}

                        {selectedGroupId && (
                            <div>
                                <div className="bg-gray-50 dark:bg-slate-800/50 rounded-lg p-3 border border-gray-200 dark:border-slate-700">
                                    <div className="flex justify-between items-center mb-2">
                                        <span className="text-sm font-medium text-gray-700 dark:text-slate-300">Split Details</span>
                                        <button
                                            type="button"
                                            onClick={() => setIsSplitDrawerOpen(true)}
                                            className="text-sm text-blue-600 dark:text-blue-400 font-medium hover:underline flex items-center"
                                        >
                                            Edit Splits <ChevronRight className="w-4 h-4 ml-1" />
                                        </button>
                                    </div>
                                    <div className="text-sm text-gray-600 dark:text-slate-400 flex items-center gap-2">
                                        <Users className="w-4 h-4" />
                                        <span>
                                            {splitType === 'EQUAL' ? 'Equally' : splitType === 'EXACT' ? 'Exact Amounts' : 'Percentages'} between {selectedParticipants.length} people
                                        </span>
                                    </div>
                                    {splitType !== 'EQUAL' && (
                                        <div className={cn(
                                            "mt-2 text-xs font-medium",
                                            (splitType === 'EXACT' && Math.abs(getRunningTotal() - Number(amount || 0)) > 0.01) ||
                                                (splitType === 'PERCENT' && Math.abs(getRunningTotal() - 100) > 0.01)
                                                ? "text-red-600 dark:text-red-400"
                                                : "text-green-600 dark:text-green-400"
                                        )}>
                                            Total: {getRunningTotal().toFixed(2)} {splitType === 'PERCENT' ? '%' : '₹'}
                                        </div>
                                    )}
                                </div>

                                <Drawer
                                    isOpen={isSplitDrawerOpen}
                                    onClose={() => setIsSplitDrawerOpen(false)}
                                    title="Split Expenses"
                                    footer={
                                        <div className="space-y-3">
                                            {splitType !== 'EQUAL' && (
                                                <div className="flex justify-between items-center p-3 bg-gray-50 dark:bg-slate-800 rounded-lg border border-gray-100 dark:border-slate-700">
                                                    <span className="text-sm font-medium text-gray-600 dark:text-slate-400">
                                                        {splitType === 'EXACT' ? 'Remaining:' : 'Total:'}
                                                    </span>
                                                    <span className={cn(
                                                        "text-base font-bold",
                                                        (splitType === 'EXACT' && Math.abs(getRunningTotal() - Number(amount || 0)) > 0.01) ||
                                                            (splitType === 'PERCENT' && Math.abs(getRunningTotal() - 100) > 0.01)
                                                            ? "text-red-600 dark:text-red-400"
                                                            : "text-green-600 dark:text-green-400"
                                                    )}>
                                                        {splitType === 'EXACT'
                                                            ? `₹${(Number(amount || 0) - getRunningTotal()).toFixed(2)}`
                                                            : `${getRunningTotal().toFixed(1)}%`
                                                        }
                                                    </span>
                                                </div>
                                            )}
                                            <button
                                                type="button"
                                                onClick={() => setIsSplitDrawerOpen(false)}
                                                className="w-full py-3 px-4 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 transition-colors shadow-sm active:scale-[0.98]"
                                            >
                                                Done
                                            </button>
                                        </div>
                                    }
                                >
                                    <div className="space-y-4">
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">Split Type</label>
                                            <div className="flex bg-gray-100 dark:bg-slate-800 p-1 rounded-lg">
                                                {(['EQUAL', 'EXACT', 'PERCENT'] as const).map((type) => (
                                                    <button
                                                        key={type}
                                                        type="button"
                                                        onClick={() => setSplitType(type)}
                                                        className={cn(
                                                            "flex-1 py-1.5 text-xs font-medium rounded-md transition-all",
                                                            splitType === type
                                                                ? "bg-white dark:bg-slate-700 shadow text-gray-900 dark:text-white"
                                                                : "text-gray-500 dark:text-slate-400 hover:text-gray-700 dark:hover:text-slate-200"
                                                        )}
                                                    >
                                                        {type === 'EQUAL' ? 'Equal' : type === 'EXACT' ? 'Exact' : '%'}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>

                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-2">
                                                Select Members ({selectedParticipants.length})
                                            </label>
                                            {loadingMembers ? (
                                                <div className="text-sm text-gray-500 dark:text-slate-400 flex items-center gap-2">
                                                    <Loader2 className="w-4 h-4 animate-spin" /> Loading members...
                                                </div>
                                            ) : (
                                                <div className="space-y-2">
                                                    {groupMembers.map(member => (
                                                        <div key={member.id} className={cn(
                                                            "flex flex-col p-3 rounded-xl border transition-all",
                                                            selectedParticipants.includes(member.id)
                                                                ? "bg-blue-50/50 dark:bg-blue-900/10 border-blue-200 dark:border-blue-800"
                                                                : "bg-white dark:bg-slate-800 border-transparent hover:bg-gray-50 dark:hover:bg-slate-700"
                                                        )}>
                                                            <div className="flex items-center justify-between">
                                                                <label className="flex items-center space-x-3 cursor-pointer flex-1 py-1">
                                                                    <input
                                                                        type="checkbox"
                                                                        checked={selectedParticipants.includes(member.id)}
                                                                        onChange={() => handleParticipantToggle(member.id)}
                                                                        className="w-5 h-5 rounded-md border-gray-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500 bg-white dark:bg-slate-700"
                                                                    />
                                                                    <div className="flex flex-col">
                                                                        <span className="text-base font-medium text-gray-900 dark:text-white">{member.username}</span>
                                                                        <span className="text-xs text-gray-500 dark:text-slate-400">{member.email}</span>
                                                                    </div>
                                                                </label>
                                                            </div>

                                                            {selectedParticipants.includes(member.id) && splitType !== 'EQUAL' && (
                                                                <div className="mt-3 pl-8 animate-in fade-in slide-in-from-top-2 duration-200">
                                                                    <div className="relative">
                                                                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                                                            <span className="text-gray-500 dark:text-slate-400 font-medium">
                                                                                {splitType === 'PERCENT' ? '%' : '₹'}
                                                                            </span>
                                                                        </div>
                                                                        <input
                                                                            type="number"
                                                                            step={splitType === 'PERCENT' ? "0.1" : "0.01"}
                                                                            className="block w-full pl-8 pr-4 py-2.5 text-base border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-slate-700 text-gray-900 dark:text-white shadow-sm"
                                                                            placeholder="0.00"
                                                                            value={splitValues[member.id] || ''}
                                                                            onChange={(e) => handleSplitValueChange(member.id, e.target.value)}
                                                                        />
                                                                    </div>
                                                                </div>
                                                            )}
                                                        </div>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </Drawer>
                            </div>
                        )}

                        <div className="flex items-center space-x-2 pt-2">
                            <input
                                type="checkbox"
                                id="addToPersonal"
                                {...register("add_to_personal")}
                                className="rounded border-gray-300 dark:border-slate-600 text-blue-600 focus:ring-blue-500 bg-white dark:bg-slate-700"
                            />
                            <label htmlFor="addToPersonal" className="text-sm text-gray-700 dark:text-slate-300">
                                Also add my share to personal expenses
                            </label>
                        </div>
                    </div>
                )}

                <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Description</label>
                    <div className="flex gap-2">
                        <input
                            {...register("description", { required: true })}
                            className="mt-1 block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                            placeholder="Dinner, Movie, etc."
                        />
                        {isAIEnabled() && (
                            <button
                                type="button"
                                onClick={handleSuggestCategory}
                                disabled={isSuggesting}
                                className="mt-1 px-3 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors flex items-center gap-2"
                                title="Auto-suggest category with AI"
                            >
                                <Sparkles className={`w-4 h-4 ${isSuggesting ? 'animate-spin' : ''}`} />
                            </button>
                        )}
                    </div>
                </div>



                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="min-w-0">
                        <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Category</label>
                        <select
                            {...register("category")}
                            className="mt-1 block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                        >
                            <option value="Food">Food</option>
                            <option value="Transport">Transport</option>
                            <option value="Utilities">Utilities</option>
                            <option value="Entertainment">Entertainment</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div className="min-w-0">
                        <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">Date & Time</label>
                        <input
                            type="datetime-local"
                            {...register("date", { required: true })}
                            className="mt-1 block w-full rounded-md border-gray-300 dark:border-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white box-border"
                        />
                    </div>
                </div>



                <button
                    type="submit"
                    disabled={loading}
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                >
                    {loading ? 'Saving...' : (initialData ? 'Update Expense' : 'Add Expense')}
                </button>
            </form >
        </div >
    );
};
