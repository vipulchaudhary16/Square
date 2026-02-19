import React from 'react';

interface EmptyStateProps {
    title: string;
    description: string;
    className?: string;
}

export const EmptyState: React.FC<EmptyStateProps> = ({ title, description, className = '' }) => {
    return (
        <div
            className={`text-center py-12 bg-white dark:bg-slate-800 rounded-2xl border border-slate-100 dark:border-slate-700 border-dashed ${className}`}
        >
            <p className="text-slate-500 dark:text-slate-400 font-medium">{title}</p>
            <p className="text-slate-400 dark:text-slate-500 text-sm mt-1">{description}</p>
        </div>
    );
};
