import React, { useState, useEffect, useRef } from 'react';
import { Calculator as CalculatorIcon } from 'lucide-react';
import { Calculator } from './Calculator';

interface AmountInputProps {
    value: number | undefined;
    onChange: (value: number) => void;
    placeholder?: string;
    className?: string;
    error?: boolean;
}

export const AmountInput: React.FC<AmountInputProps> = ({ value, onChange, placeholder, className, error }) => {
    const [inputValue, setInputValue] = useState(value?.toString() || '');
    const [showCalculator, setShowCalculator] = useState(false);
    const containerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        // Only update input value from prop if it's different and we are not currently editing (handled by local state)
        // But here we want to sync if parent changes it (e.g. initial load or reset)
        // To avoid cursor jumping or fighting, we might need to be careful.
        // For now, simple sync when value changes significantly or on mount.
        if (value !== undefined && value !== null && !isNaN(value)) {
            // Check if the current input evaluates to the value, if so don't overwrite to preserve "20+5" visual
            // But if value changed externally, we should update.
            // Let's just update if the parsed input value is different from prop value.
            const currentParsed = parseFloat(inputValue);
            if (currentParsed !== value) {
                setInputValue(value.toString());
            }
        }
    }, [value]);

    const evaluateExpression = (expression: string): number | null => {
        try {
            // Remove all non-allowed characters
            const sanitized = expression.replace(/[^0-9+\-*/().\s]/g, '');
            if (!sanitized) return null;
            // eslint-disable-next-line no-new-func
            const result = new Function('return ' + sanitized)();
            return isNaN(result) ? null : result;
        } catch (e) {
            return null;
        }
    };

    const handleBlur = () => {
        const result = evaluateExpression(inputValue);
        if (result !== null) {
            onChange(result);
            setInputValue(result.toString());
        } else {
            // If invalid, revert to previous value or keep as is?
            // Let's revert to current prop value if invalid
            setInputValue(value?.toString() || '');
        }
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            handleBlur();
        }
        // Allow navigation, backspace, delete, etc.
        // Allow numbers and math operators
        const allowedKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab', 'Enter', 'Home', 'End', '.', '+', '-', '*', '/', '(', ')', ' '];
        if (!allowedKeys.includes(e.key) && !/^[0-9]$/.test(e.key)) {
            // If it's not a number or allowed key, prevent default?
            // The user specifically asked to prevent alphabets before.
            // But now they want calculator. So we allow math chars.
            // We should block alphabets.
            if (/^[a-zA-Z]$/.test(e.key)) {
                e.preventDefault();
            }
        }
    };

    const handleCalculatorSave = (newValue: number) => {
        onChange(newValue);
        setInputValue(newValue.toString());
        setShowCalculator(false);
    };

    // Click outside to close calculator
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setShowCalculator(false);
            }
        };

        if (showCalculator) {
            document.addEventListener('mousedown', handleClickOutside);
        }
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showCalculator]);

    // Check if we should open upwards
    const [openUpwards, setOpenUpwards] = useState(false);

    useEffect(() => {
        if (showCalculator && containerRef.current) {
            const rect = containerRef.current.getBoundingClientRect();
            const spaceBelow = window.innerHeight - rect.bottom;
            // If less than 400px space below, open upwards
            setOpenUpwards(spaceBelow < 400);
        }
    }, [showCalculator]);

    return (
        <div className="relative" ref={containerRef}>
            <div className="relative rounded-md shadow-sm">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                    <span className="text-gray-500 dark:text-slate-400 sm:text-sm">₹</span>
                </div>
                <input
                    type="text"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    onBlur={handleBlur}
                    onKeyDown={handleKeyDown}
                    className={`block w-full rounded-xl md:rounded-md border-gray-300 dark:border-slate-600 pl-7 pr-10 focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border bg-white dark:bg-slate-700 text-gray-900 dark:text-white ${className} ${error ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : ''}`}
                    placeholder={placeholder || "10 + 5"}
                />
                <div className="absolute inset-y-0 right-0 flex items-center pr-2">
                    <button
                        type="button"
                        onClick={() => setShowCalculator(!showCalculator)}
                        className="p-1 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-slate-600 transition-colors"
                    >
                        <CalculatorIcon className="w-4 h-4" />
                    </button>
                </div>
            </div>

            {showCalculator && (
                <div className={`absolute right-0 ${openUpwards ? 'bottom-full mb-2' : 'top-full mt-2'} z-[60] w-72 origin-top-right`}>
                    <Calculator
                        initialValue={parseFloat(inputValue) || 0}
                        onSave={handleCalculatorSave}
                        onClose={() => setShowCalculator(false)}
                    />
                </div>
            )}
        </div>
    );
};
