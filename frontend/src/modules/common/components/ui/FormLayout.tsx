import React from 'react';
import { ArrowLeft } from 'lucide-react';

interface FormLayoutProps {
    title: string;
    children: React.ReactNode;
    actions?: React.ReactNode;
    onClose: () => void;
}

export const FormLayout: React.FC<FormLayoutProps> = ({ title, children, actions, onClose }) => {
    return (
        <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
            <div className="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-100 dark:border-slate-700 px-4 py-4 flex items-center justify-between shadow-sm">
                <div className="flex items-center gap-4">
                    <button
                        onClick={onClose}
                        className="p-2 -ml-2 rounded-full text-slate-500 hover:text-slate-700 hover:bg-slate-100 dark:text-slate-400 dark:hover:text-slate-200 dark:hover:bg-slate-700 transition-colors"
                        aria-label="Go back"
                    >
                        <ArrowLeft className="w-6 h-6" />
                    </button>
                    <h2 className="text-l font-semibold text-gray-900 dark:text-white">{title}</h2>
                </div>
                <div className="flex items-center gap-3">
                    {actions}
                </div>
            </div>

            <div className="max-w-3xl mx-auto p-6">
                {children}
            </div>
        </div>
    );
};
