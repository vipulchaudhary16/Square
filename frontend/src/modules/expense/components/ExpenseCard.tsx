import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

interface Expense {
    id: string;
    description: string;
    amount: number;
    date: string;
    category: string;
    payer_id: string;
    group_id?: string;
    group_name?: string;
}

interface ExpenseCardProps {
    expense: Expense;
    currentUserId: string;
}

export function cn(...inputs: (string | undefined | null | false)[]) {
    return twMerge(clsx(inputs));
}

export const ExpenseCard: React.FC<ExpenseCardProps> = ({ expense, currentUserId }) => {
    const isPayer = expense.payer_id === currentUserId;
    const isPersonal = !expense.group_id;

    return (
        <div className="group bg-white dark:bg-slate-800 rounded-2xl p-4 mb-3 flex justify-between items-center border border-slate-100 dark:border-slate-700 shadow-sm hover:shadow-md transition-all duration-200 hover:border-primary-100 dark:hover:border-primary-900">
            <div className="flex items-center gap-4">
                <div className={cn(
                    "hidden md:flex w-12 h-12 rounded-xl items-center justify-center text-xl font-bold transition-colors",
                    isPersonal ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400" : "bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400"
                )}>
                    {expense.description.charAt(0).toUpperCase()}
                </div>
                <div className="flex flex-col">
                    <h3 className="text-base font-semibold text-slate-800 dark:text-white group-hover:text-primary-700 dark:group-hover:text-primary-400 transition-colors">{expense.description}</h3>
                    <div className="flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
                        <span>{new Date(expense.date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}</span>
                        <span>•</span>
                        <span className="font-medium">{expense.category}</span>
                        {!isPersonal && (
                            <>
                                <span>•</span>
                                <span className="text-primary-600 dark:text-primary-400 font-medium bg-primary-50 dark:bg-primary-900/20 px-1.5 py-0.5 rounded-md">
                                    {expense.group_name || 'Group'}
                                </span>
                            </>
                        )}
                    </div>
                </div>
            </div>
            <div className="flex flex-col items-end">
                <span className={cn(
                    "text-lg font-bold tracking-tight",
                    isPayer ? "text-emerald-600 dark:text-emerald-400" : "text-rose-500 dark:text-rose-400"
                )}>
                    {isPayer ? "+" : "-"} ₹{expense.amount.toFixed(2)}
                </span>
                <span className="text-xs font-medium text-slate-400 dark:text-slate-500">
                    {isPayer ? "You paid" : "You owe"}
                </span>
            </div>
        </div>
    );
};
