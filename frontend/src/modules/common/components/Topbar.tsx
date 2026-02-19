import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
    LayoutDashboard,
    Users,
    BarChart3,
    LogOut,
    ChevronDown,
    User as UserIcon,
    DollarSign,
    TrendingUp,
    ArrowLeftRight,
    Wallet,
    Table2,
    Plus,
} from 'lucide-react';
import { useSession } from '../../../hooks/useSession';

import { useTheme } from '../../../context/ThemeContext';
import { Sun, Moon } from 'lucide-react';

import logo from '../../../assets/square.png';

export const Topbar: React.FC = () => {
    const { user, logout } = useSession();
    const { theme, toggleTheme } = useTheme();
    const location = useLocation();
    const navigate = useNavigate();
    const [isProfileOpen, setIsProfileOpen] = useState(false);
    const [isVisible, setIsVisible] = useState(true);
    const [lastScrollY, setLastScrollY] = useState(0);

    const navItems = [
        { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Transactions', path: '/transactions', icon: Table2 },
        { name: 'Income', path: '/income', icon: DollarSign },
        { name: 'Budgets', path: '/budgets', icon: Wallet },
        { name: 'Investments', path: '/investments', icon: TrendingUp },
        { name: 'Loans', path: '/loans', icon: ArrowLeftRight },
        { name: 'Groups', path: '/groups', icon: Users },
        { name: 'Reports', path: '/reports', icon: BarChart3 },
    ];

    const handleLogout = () => {
        logout();
        navigate('/auth');
    };

    const isActive = (path: string) => location.pathname === path;

    React.useEffect(() => {
        const controlNavbar = () => {
            if (typeof window !== 'undefined') {
                if (window.scrollY > lastScrollY && window.scrollY > 100) {
                    setIsVisible(false);
                } else {
                    setIsVisible(true);
                }
                setLastScrollY(window.scrollY);
            }
        };

        window.addEventListener('scroll', controlNavbar);

        return () => {
            window.removeEventListener('scroll', controlNavbar);
        };
    }, [lastScrollY]);

    return (
        <nav
            className={`hidden md:block bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200/60 dark:border-slate-800/60 sticky top-0 z-50 transition-transform duration-300 ${isVisible ? 'translate-y-0' : '-translate-y-full md:translate-y-0'}`}
        >
            <div className="mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between h-16">
                    <div className="flex items-center">
                        <Link
                            to="/dashboard"
                            className="flex-shrink-0 flex items-center gap-2 group"
                        >
                            <img
                                src={logo}
                                alt="Square Logo"
                                className="w-9 h-9 rounded-xl group-hover:scale-105 transition-transform duration-200"
                            />
                            <span className="hidden 2xl:block text-xl font-bold text-slate-800 dark:text-white tracking-tight">
                                Square
                            </span>
                        </Link>
                    </div>

                    <div className="hidden xl:flex items-center space-x-0.5">
                        {navItems.map((item) => {
                            const Icon = item.icon;
                            const active = isActive(item.path);
                            return (
                                <Link
                                    key={item.path}
                                    to={item.path}
                                    className={`flex items-center gap-1.5 px-3 py-2 rounded-xl text-[13px] font-medium transition-all duration-200 ${
                                        active
                                            ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-400 shadow-sm'
                                            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white'
                                    }`}
                                >
                                    <Icon
                                        className={`w-4 h-4 ${active ? 'text-primary-600 dark:text-primary-400' : 'text-slate-400'}`}
                                    />
                                    {item.name}
                                </Link>
                            );
                        })}
                    </div>

                    <div className="hidden md:flex items-center ml-4 gap-2">
                        <Link
                            to="/expenses"
                            className="flex items-center gap-2 bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors shadow-sm shadow-primary-500/20"
                        >
                            <Plus className="w-4 h-4" />
                            <span className="hidden lg:inline">Add Expense</span>
                        </Link>

                        <button
                            onClick={toggleTheme}
                            className="p-2 rounded-full text-slate-500 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800 transition-colors"
                        >
                            {theme === 'light' ? (
                                <Moon className="w-5 h-5" />
                            ) : (
                                <Sun className="w-5 h-5" />
                            )}
                        </button>

                        <div className="relative">
                            <button
                                onClick={() => setIsProfileOpen(!isProfileOpen)}
                                className="flex items-center gap-3 pl-2 pr-1 py-1 rounded-full hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors focus:outline-none group"
                            >
                                <div className="w-9 h-9 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 rounded-full flex items-center justify-center border border-white dark:border-slate-700 shadow-sm ring-2 ring-transparent group-hover:ring-primary-100 dark:group-hover:ring-primary-900 transition-all">
                                    <UserIcon className="w-5 h-5 text-slate-500 dark:text-slate-400" />
                                </div>
                                <div className="flex flex-col items-start mr-1">
                                    <span className="text-sm font-semibold text-slate-700 dark:text-slate-200 leading-none">
                                        {user?.first_name + ' ' + user?.last_name}
                                    </span>
                                </div>
                                <ChevronDown
                                    className={`w-4 h-4 text-slate-400 transition-transform duration-200 ${isProfileOpen ? 'rotate-180' : ''}`}
                                />
                            </button>

                            <AnimatePresence>
                                {isProfileOpen && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        transition={{ duration: 0.1 }}
                                        className="absolute right-0 mt-2 w-56 bg-white dark:bg-slate-800 rounded-2xl shadow-xl border border-slate-100 dark:border-slate-700 py-2 ring-1 ring-black ring-opacity-5 focus:outline-none origin-top-right overflow-hidden"
                                    >
                                        <div className="px-4 py-3 border-b border-slate-50 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-800/50">
                                            <p className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                                Signed in as
                                            </p>
                                            <p className="text-sm font-semibold text-slate-900 dark:text-white truncate mt-0.5">
                                                {user?.email}
                                            </p>
                                        </div>
                                        <div className="p-1">
                                            <button
                                                onClick={handleLogout}
                                                className="w-full text-left px-3 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-xl flex items-center gap-2 transition-colors"
                                            >
                                                <LogOut className="w-4 h-4" />
                                                Sign out
                                            </button>
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </div>
        </nav>
    );
};
