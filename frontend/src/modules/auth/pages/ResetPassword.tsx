import { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Lock, Loader2, CheckCircle, Eye, EyeOff } from 'lucide-react';
import { useNavigate, useSearchParams, Link } from 'react-router-dom';
import useApiCall from '../../../hooks/useApiCall';
import { resetPassword } from '../../../api/auth';

export default function ResetPassword() {
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [success, setSuccess] = useState(false);

    const [searchParams] = useSearchParams();
    const token = searchParams.get('token');
    const navigate = useNavigate();

    const { execute, loading, error } = useApiCall({
        apiCall: (token: string, pass: string) => resetPassword(token, pass),
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (password !== confirmPassword) {
            return;
        }

        if (!token) return;

        try {
            await execute(token, password);
            setSuccess(true);
            setTimeout(() => {
                navigate('/auth');
            }, 3000);
        } catch (err) {}
    };

    const errorMessage = (error as any)?.response?.data?.error;
    const passwordsMatch = password === confirmPassword;

    if (!token) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900 p-4">
                <div className="text-center">
                    <h2 className="text-xl font-bold text-slate-900 dark:text-white mb-2">
                        Invalid Link
                    </h2>
                    <p className="text-slate-500 dark:text-slate-400 mb-4">
                        This password reset link is invalid or missing a token.
                    </p>
                    <Link to="/auth" className="text-primary-600 hover:underline">
                        Back to Login
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900 p-4 overflow-hidden relative transition-colors duration-300">
            <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] bg-primary-200/40 dark:bg-primary-900/20 rounded-full blur-[120px]" />
            <div className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] bg-purple-200/40 dark:bg-purple-900/20 rounded-full blur-[120px]" />

            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="w-full max-w-md bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl border border-white/50 dark:border-slate-700/50 rounded-3xl shadow-xl overflow-hidden relative z-10"
            >
                <div className="p-8">
                    <div className="text-center mb-8">
                        <motion.div
                            initial={{ scale: 0.5, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            transition={{ delay: 0.2 }}
                            className="w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-700 rounded-2xl mx-auto flex items-center justify-center mb-4 shadow-lg shadow-primary-500/30"
                        >
                            <Lock className="w-8 h-8 text-white" />
                        </motion.div>
                        <h2 className="text-3xl font-bold text-slate-900 dark:text-white mb-2 tracking-tight">
                            Reset Password
                        </h2>
                        <p className="text-slate-500 dark:text-slate-400">
                            Enter your new password below
                        </p>
                    </div>

                    {!success ? (
                        <form onSubmit={handleSubmit} className="space-y-5">
                            <div className="space-y-1.5">
                                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300 ml-1">
                                    New Password
                                </label>
                                <div className="relative group">
                                    <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                                    <input
                                        type={showPassword ? 'text' : 'password'}
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        placeholder="••••••••"
                                        className="w-full bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl py-3.5 pl-12 pr-12 text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 transition-all font-medium"
                                        required
                                        minLength={6}
                                    />
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(!showPassword)}
                                        className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 transition-colors"
                                    >
                                        {showPassword ? (
                                            <EyeOff className="w-5 h-5" />
                                        ) : (
                                            <Eye className="w-5 h-5" />
                                        )}
                                    </button>
                                </div>
                            </div>

                            <div className="space-y-1.5">
                                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300 ml-1">
                                    Confirm Password
                                </label>
                                <div className="relative group">
                                    <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                                    <input
                                        type={showConfirmPassword ? 'text' : 'password'}
                                        value={confirmPassword}
                                        onChange={(e) => setConfirmPassword(e.target.value)}
                                        placeholder="••••••••"
                                        className={`w-full bg-slate-50 dark:bg-slate-900 border ${!passwordsMatch && confirmPassword ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20' : 'border-slate-200 dark:border-slate-700 focus:border-primary-500 focus:ring-primary-500/20'} rounded-xl py-3.5 pl-12 pr-12 text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 transition-all font-medium`}
                                        required
                                        minLength={6}
                                    />
                                    <button
                                        type="button"
                                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                        className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 transition-colors"
                                    >
                                        {showConfirmPassword ? (
                                            <EyeOff className="w-5 h-5" />
                                        ) : (
                                            <Eye className="w-5 h-5" />
                                        )}
                                    </button>
                                </div>
                                {!passwordsMatch && confirmPassword && (
                                    <p className="text-xs text-red-500 ml-1">
                                        Passwords do not match
                                    </p>
                                )}
                            </div>

                            {errorMessage && (
                                <motion.p
                                    initial={{ opacity: 0, y: -10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    className="text-red-600 dark:text-red-400 text-sm text-center bg-red-50 dark:bg-red-900/20 py-2 rounded-lg border border-red-100 dark:border-red-900/30 font-medium"
                                >
                                    {errorMessage}
                                </motion.p>
                            )}

                            <button
                                type="submit"
                                disabled={loading || !passwordsMatch || !password}
                                className="w-full bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-500 hover:to-primary-600 text-white font-bold py-3.5 rounded-xl transition-all transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg shadow-primary-500/30"
                            >
                                {loading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : (
                                    <>
                                        Reset Password <ArrowRight className="w-5 h-5" />
                                    </>
                                )}
                            </button>
                        </form>
                    ) : (
                        <div className="text-center py-8">
                            <motion.div
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                className="w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mx-auto mb-4"
                            >
                                <CheckCircle className="w-8 h-8 text-green-600 dark:text-green-400" />
                            </motion.div>
                            <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-2">
                                Password Reset Successful!
                            </h3>
                            <p className="text-slate-500 dark:text-slate-400 mb-6">
                                You can now login with your new password. Redirecting...
                            </p>
                        </div>
                    )}
                </div>
            </motion.div>
        </div>
    );
}
