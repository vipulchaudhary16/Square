import React, { useState } from 'react';
import { X, Delete, Check } from 'lucide-react';

interface CalculatorProps {
    initialValue?: number;
    onSave: (value: number) => void;
    onClose: () => void;
}

export const Calculator: React.FC<CalculatorProps> = ({ initialValue = 0, onSave, onClose }) => {
    const [display, setDisplay] = useState(initialValue.toString());
    const [equation, setEquation] = useState('');
    const [isNewNumber, setIsNewNumber] = useState(true);

    const handleNumber = (num: string) => {
        if (isNewNumber) {
            setDisplay(num);
            setIsNewNumber(false);
        } else {
            setDisplay(display === '0' ? num : display + num);
        }
    };

    const handleOperator = (op: string) => {
        if (isNewNumber && equation) {
            // If we just entered an operator (or computed a result) and want to change the operator
            // Check if the last part is an operator
            if (equation.trim().endsWith(op)) {
                return; // Same operator, do nothing
            }
            // Replace the last operator
            // Assuming format " ... op " (3 chars: space, op, space)
            setEquation(equation.slice(0, -3) + ' ' + op + ' ');
        } else {
            setEquation(equation + display + ' ' + op + ' ');
            setIsNewNumber(true);
        }
    };

    const handleEqual = () => {
        try {
            const fullEquation = equation + display;
            // eslint-disable-next-line no-new-func
            const result = new Function(
                'return ' + fullEquation.replace(/[^0-9+\-*/().\s]/g, ''),
            )();
            setDisplay(String(result));
            setEquation('');
            setIsNewNumber(true);
        } catch (error) {
            setDisplay('Error');
            setIsNewNumber(true);
        }
    };

    const handleClear = () => {
        setDisplay('0');
        setEquation('');
        setIsNewNumber(true);
    };

    const handleDelete = () => {
        if (display.length > 1) {
            setDisplay(display.slice(0, -1));
        } else {
            setDisplay('0');
            setIsNewNumber(true);
        }
    };

    const handleDecimal = () => {
        if (isNewNumber) {
            setDisplay('0.');
            setIsNewNumber(false);
        } else if (!display.includes('.')) {
            setDisplay(display + '.');
        }
    };

    const handleSave = () => {
        // If there's a pending equation, solve it first
        if (equation) {
            try {
                const fullEquation = equation + display;
                // eslint-disable-next-line no-new-func
                const result = new Function(
                    'return ' + fullEquation.replace(/[^0-9+\-*/().\s]/g, ''),
                )();
                onSave(Number(result));
            } catch (error) {
                onSave(Number(display));
            }
        } else {
            onSave(Number(display));
        }
    };

    const buttons = [
        {
            label: 'C',
            onClick: handleClear,
            className: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
        },
        {
            label: '(',
            onClick: () => handleOperator('('),
            className: 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300',
        },
        {
            label: ')',
            onClick: () => handleOperator(')'),
            className: 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300',
        },
        {
            label: '÷',
            onClick: () => handleOperator('/'),
            className: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
        },
        { label: '7', onClick: () => handleNumber('7') },
        { label: '8', onClick: () => handleNumber('8') },
        { label: '9', onClick: () => handleNumber('9') },
        {
            label: '×',
            onClick: () => handleOperator('*'),
            className: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
        },
        { label: '4', onClick: () => handleNumber('4') },
        { label: '5', onClick: () => handleNumber('5') },
        { label: '6', onClick: () => handleNumber('6') },
        {
            label: '-',
            onClick: () => handleOperator('-'),
            className: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
        },
        { label: '1', onClick: () => handleNumber('1') },
        { label: '2', onClick: () => handleNumber('2') },
        { label: '3', onClick: () => handleNumber('3') },
        {
            label: '+',
            onClick: () => handleOperator('+'),
            className: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
        },
        { label: '0', onClick: () => handleNumber('0'), className: 'col-span-2' },
        { label: '.', onClick: handleDecimal },
        { label: '=', onClick: handleEqual, className: 'bg-blue-600 text-white' },
    ];

    return (
        <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl border border-slate-200 dark:border-slate-700 w-full max-w-xs overflow-hidden">
            <div className="p-4 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-100 dark:border-slate-700">
                <div className="flex justify-between items-center mb-2">
                    <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">
                        Calculator
                    </h3>
                    <button
                        type="button"
                        onClick={onClose}
                        className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                    >
                        <X className="w-4 h-4" />
                    </button>
                </div>
                <div className="text-right">
                    <div className="h-6 text-xs text-slate-400 font-mono overflow-hidden">
                        {equation}
                    </div>
                    <div className="text-3xl font-bold text-slate-800 dark:text-white font-mono tracking-wider overflow-x-auto scrollbar-hide">
                        {display}
                    </div>
                </div>
            </div>

            <div className="p-4 grid grid-cols-4 gap-3">
                {buttons.map((btn, idx) => (
                    <button
                        key={idx}
                        type="button"
                        onClick={btn.onClick}
                        className={`
                            h-12 rounded-xl text-lg font-semibold transition-all active:scale-95 flex items-center justify-center
                            ${btn.className || 'bg-slate-50 dark:bg-slate-700/50 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700'}
                        `}
                    >
                        {btn.label}
                    </button>
                ))}
            </div>

            <div className="p-4 pt-0 flex gap-3">
                <button
                    type="button"
                    onClick={handleDelete}
                    className="flex-1 py-3 rounded-xl bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 font-medium flex items-center justify-center gap-2 hover:bg-slate-200 dark:hover:bg-slate-600 transition-colors"
                >
                    <Delete className="w-4 h-4" />
                </button>
                <button
                    type="button"
                    onClick={handleSave}
                    className="flex-1 py-3 rounded-xl bg-green-600 text-white font-medium flex items-center justify-center gap-2 hover:bg-green-700 transition-colors shadow-lg shadow-green-500/20"
                >
                    <Check className="w-4 h-4" />
                </button>
            </div>
        </div>
    );
};
