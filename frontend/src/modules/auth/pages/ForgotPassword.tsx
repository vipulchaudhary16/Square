import { useState } from 'react';
import { motion } from 'framer-motion';
import { Mail, ArrowRight, Lock, Loader2, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import useApiCall from '../../../hooks/useApiCall';
import { forgotPassword } from '../../../api/auth';

export default function ForgotPassword() {
    const [email, setEmail] = useState('');
    const [successMessage, setSuccessMessage] = useState('');

    const { execute, loading, error } = useApiCall({
        apiCall: (email: string) => forgotPassword(email)
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const res = await execute(email);
            setSuccessMessage(res.message);
        } catch (err) {

        }
    };

    const errorMessage = (error as any)?.response?.data?.error;

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
                            Forgot Password?
                        </h2>
                        <p className="text-slate-500 dark:text-slate-400">
                            Enter your email and we'll send you instructions to reset your password
                        </p>
                    </div>

                    {!successMessage ? (
                        <form onSubmit={handleSubmit} className="space-y-5">
                            <div className="space-y-1.5">
                                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300 ml-1">Email Address</label>
                                <div className="relative group">
                                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                                    <input
                                        type="email"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        placeholder="you@example.com"
                                        className="w-full bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl py-3.5 pl-12 pr-4 text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 transition-all font-medium"
                                        required
                                    />
                                </div>
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
                                disabled={loading}
                                className="w-full bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-500 hover:to-primary-600 text-white font-bold py-3.5 rounded-xl transition-all transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg shadow-primary-500/30"
                            >
                                {loading ? (
                                    <Loader2 className="w-5 h-5 animate-spin" />
                                ) : (
                                    <>
                                        Send Reset Link <ArrowRight className="w-5 h-5" />
                                    </>
                                )}
                            </button>
                        </form>
                    ) : (
                        <motion.div
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            className="bg-green-50 dark:bg-green-900/20 border border-green-100 dark:border-green-900/30 rounded-xl p-4 text-center"
                        >
                            <p className="text-green-700 dark:text-green-300 font-medium">
                                {successMessage}
                            </p>
                        </motion.div>
                    )}

                    <div className="text-center pt-6">
                        <Link
                            to="/auth"
                            className="inline-flex items-center text-slate-500 dark:text-slate-400 text-sm hover:text-primary-600 dark:hover:text-primary-400 transition-colors font-medium"
                        >
                            <ArrowLeft className="w-4 h-4 mr-1" /> Back to Login
                        </Link>
                    </div>
                </div>
            </motion.div>
        </div>
    );
}
