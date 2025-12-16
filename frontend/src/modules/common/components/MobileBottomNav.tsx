import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
    LayoutDashboard,
    Table2,
    Plus,
    BarChart3,
    MoreHorizontal,
    DollarSign,
    Wallet,
    TrendingUp,
    ArrowLeftRight,
    Users,
    LogOut,
    Sun,
    Moon,
    X
} from 'lucide-react';
import { useSession } from '../../../hooks/useSession';
import { useTheme } from '../../../context/ThemeContext';
import logo from '../../../assets/square.png';

export const MobileBottomNav: React.FC = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { user, logout } = useSession();
    const { theme, toggleTheme } = useTheme();
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    const isActive = (path: string) => location.pathname === path;

    const handleLogout = () => {
        logout();
        navigate('/auth');
    };

    const mainNavItems = [
        { name: 'Home', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Groups', path: '/groups', icon: Users },
    ];

    const secondaryNavItems = [
        { name: 'Transactions', path: '/transactions', icon: Table2 },
        { name: 'Income', path: '/income', icon: DollarSign },
        { name: 'Budgets', path: '/budgets', icon: Wallet },
        { name: 'Investments', path: '/investments', icon: TrendingUp },
        { name: 'Loans', path: '/loans', icon: ArrowLeftRight },
    ];

    return (
        <>
            <div className="xl:hidden fixed bottom-0 left-0 right-0 bg-white/90 dark:bg-slate-900/90 backdrop-blur-lg border-t border-slate-200 dark:border-slate-800 pb-safe z-50">
                <div className="flex justify-around items-center h-16 px-2">

                    {mainNavItems.map((item) => {
                        const Icon = item.icon;
                        const active = isActive(item.path);
                        return (
                            <Link
                                key={item.path}
                                to={item.path}
                                className={`flex flex-col items-center justify-center w-16 h-full space-y-1 ${active ? 'text-primary-600 dark:text-primary-400' : 'text-slate-500 dark:text-slate-400'
                                    }`}
                            >
                                <Icon className={`w-6 h-6 ${active ? 'fill-current opacity-20' : ''}`} strokeWidth={active ? 2.5 : 2} />
                                <span className="text-[10px] font-medium">{item.name}</span>
                            </Link>
                        );
                    })}


                    <div className="relative -top-5">
                        <Link
                            to="/expenses"
                            className="w-14 h-14 bg-gradient-to-tr from-primary-600 to-primary-500 rounded-full flex items-center justify-center text-white shadow-lg shadow-primary-500/40 transform transition-transform active:scale-95"
                        >
                            <Plus className="w-8 h-8" />
                        </Link>
                    </div>


                    <Link
                        to="/reports"
                        className={`flex flex-col items-center justify-center w-16 h-full space-y-1 ${isActive('/reports') ? 'text-primary-600 dark:text-primary-400' : 'text-slate-500 dark:text-slate-400'
                            }`}
                    >
                        <BarChart3 className={`w-6 h-6 ${isActive('/reports') ? 'fill-current opacity-20' : ''}`} strokeWidth={isActive('/reports') ? 2.5 : 2} />
                        <span className="text-[10px] font-medium">Reports</span>
                    </Link>


                    <button
                        onClick={() => setIsMenuOpen(true)}
                        className={`flex flex-col items-center justify-center w-16 h-full space-y-1 ${isMenuOpen ? 'text-primary-600 dark:text-primary-400' : 'text-slate-500 dark:text-slate-400'
                            }`}
                    >
                        <MoreHorizontal className="w-6 h-6" />
                        <span className="text-[10px] font-medium">Menu</span>
                    </button>
                </div>
            </div>


            <AnimatePresence>
                {isMenuOpen && (
                    <>
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            onClick={() => setIsMenuOpen(false)}
                            className="xl:hidden fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
                        />
                        <motion.div
                            initial={{ x: '100%' }}
                            animate={{ x: 0 }}
                            exit={{ x: '100%' }}
                            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                            className="xl:hidden fixed inset-y-0 right-0 w-3/4 max-w-xs bg-white dark:bg-slate-900 shadow-2xl z-50 overflow-y-auto"
                        >
                            <div className="p-5 space-y-6">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-2">
                                        <img src={logo} alt="Square Logo" className="w-8 h-8 rounded-lg" />
                                        <h2 className="text-xl font-bold text-slate-900 dark:text-white">Square</h2>
                                    </div>
                                    <button
                                        onClick={() => setIsMenuOpen(false)}
                                        className="p-2 bg-slate-100 dark:bg-slate-800 rounded-full text-slate-500"
                                    >
                                        <X className="w-5 h-5" />
                                    </button>
                                </div>


                                <div className="bg-slate-50 dark:bg-slate-800/50 p-2 rounded-2xl border border-slate-100 dark:border-slate-700">
                                    <div className="flex items-center gap-3">
                                        <div className="w-12 h-12 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center text-primary-600 dark:text-primary-400 font-bold text-lg">
                                            {user?.first_name?.charAt(0).toUpperCase()}
                                        </div>
                                        <div>
                                            <div className="font-bold text-slate-900 dark:text-white">{user?.first_name + ' ' + user?.last_name}</div>
                                        </div>
                                    </div>

                                </div>


                                <div className="space-y-1">
                                    <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2 px-2">Apps</h3>
                                    {secondaryNavItems.map((item) => {
                                        const Icon = item.icon;
                                        return (
                                            <Link
                                                key={item.path}
                                                to={item.path}
                                                onClick={() => setIsMenuOpen(false)}
                                                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${isActive(item.path)
                                                    ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-400'
                                                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
                                                    }`}
                                            >
                                                <Icon className="w-5 h-5" />
                                                {item.name}
                                            </Link>
                                        );
                                    })}
                                </div>

                                <div className="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-3">
                                    <button
                                        onClick={toggleTheme}
                                        className="w-full flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700 text-sm font-medium text-slate-600 dark:text-slate-300"
                                    >
                                        <div className="flex items-center gap-2">
                                            {theme === 'light' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
                                            <span>{theme === 'light' ? 'Light Mode' : 'Dark Mode'}</span>
                                        </div>
                                        <div className={`w-9 h-5 bg-slate-200 dark:bg-slate-700 rounded-full relative transition-colors ${theme === 'dark' ? 'bg-primary-600' : ''}`}>
                                            <div className={`absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow-sm transition-transform ${theme === 'dark' ? 'translate-x-4' : ''}`} />
                                        </div>
                                    </button>
                                    <button
                                        onClick={handleLogout}
                                        className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                                    >
                                        <LogOut className="w-5 h-5" />
                                        Sign out
                                    </button>
                                </div>
                            </div>
                        </motion.div>
                    </>
                )}
            </AnimatePresence>
        </>
    );
};
