import React, { useEffect } from 'react';
import { X } from 'lucide-react';






function classNames(...classes: (string | undefined | null | false)[]) {
    return classes.filter(Boolean).join(' ');
}

interface DrawerProps {
    isOpen: boolean;
    onClose: () => void;
    title: string;
    children: React.ReactNode;
    footer?: React.ReactNode;
}

export const Drawer: React.FC<DrawerProps> = ({ isOpen, onClose, title, children, footer }) => {
    
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isOpen]);

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex justify-end sm:justify-end items-end sm:items-stretch">
            {}
            <div
                className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity animate-in fade-in duration-200"
                onClick={onClose}
            ></div>

            {}
            <div className={classNames(
                "relative w-full sm:max-w-md bg-white dark:bg-slate-900 shadow-2xl ring-1 ring-slate-900/5 dark:ring-white/10 flex flex-col h-[85vh] sm:h-full rounded-t-2xl sm:rounded-none sm:rounded-l-2xl transform transition-transform animate-in slide-in-from-bottom sm:slide-in-from-right duration-300 ease-out"
            )}>
                {}
                <div className="sm:hidden flex justify-center pt-3 pb-1" onClick={onClose}>
                    <div className="w-12 h-1.5 bg-gray-300 dark:bg-slate-700 rounded-full"></div>
                </div>

                {}
                <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 shrink-0">
                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                        {title}
                    </h3>
                    <button
                        onClick={onClose}
                        className="p-2 rounded-full text-slate-400 hover:text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {}
                <div className="flex-1 px-6 py-4 overflow-y-auto">
                    {children}
                </div>

                {}
                {footer && (
                    <div className="px-6 py-4 border-t border-slate-100 dark:border-slate-800 bg-gray-50 dark:bg-slate-900/50 shrink-0 pb-8 sm:pb-4">
                        {footer}
                    </div>
                )}
            </div>
        </div>
    );
};
