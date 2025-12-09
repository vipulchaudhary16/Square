import React from 'react';
import { X } from 'lucide-react';
import { useBodyScrollLock } from '../../../../hooks/useBodyScrollLock';

interface ModalProps {
    isOpen: boolean;
    onClose: () => void;
    title: string;
    children: React.ReactNode;
    hideHeader?: boolean;
}

export const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, children, hideHeader }) => {
    useBodyScrollLock(isOpen);

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
            { }
            <div
                className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"
                onClick={onClose}
            ></div>

            { }
            <div className="relative w-full max-w-lg bg-white dark:bg-slate-900 rounded-2xl shadow-2xl ring-1 ring-slate-900/5 dark:ring-white/10 overflow-hidden transform transition-all animate-in fade-in zoom-in-95 duration-200">
                { }
                {!hideHeader && (
                    <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800">
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
                )}

                { }
                <div className={`px-6 py-4 max-h-[80vh] overflow-y-auto ${hideHeader ? 'p-0' : ''}`}>
                    {children}
                </div>
            </div>
        </div>
    );
};
