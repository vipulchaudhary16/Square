import { motion } from 'framer-motion';
import { ArrowRight, PieChart, Users, Shield } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Landing() {
    return (
        <div className="min-h-screen bg-[#0f172a] text-white overflow-hidden relative">
            {}
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0">
                <div className="absolute top-[-10%] left-[-10%] w-[600px] h-[600px] bg-purple-500/20 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] bg-blue-500/20 rounded-full blur-[120px]" />
            </div>

            <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                {}
                <nav className="flex justify-between items-center py-6">
                    <div className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-400">
                        ExpenseTracker
                    </div>
                    <Link
                        to="/auth"
                        className="px-6 py-2 bg-white/10 hover:bg-white/20 border border-white/10 rounded-full transition-all backdrop-blur-sm"
                    >
                        Sign In
                    </Link>
                </nav>

                {}
                <div className="flex flex-col items-center justify-center min-h-[80vh] text-center">
                    <motion.h1
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8 }}
                        className="text-5xl md:text-7xl font-bold mb-6 leading-tight"
                    >
                        Master Your Money <br />
                        <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400">
                            Split with Ease
                        </span>
                    </motion.h1>

                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                        className="text-xl text-gray-400 mb-10 max-w-2xl"
                    >
                        The modern way to track personal expenses and split bills with friends.
                        Simple, secure, and beautiful.
                    </motion.p>

                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.4 }}
                    >
                        <Link
                            to="/auth"
                            className="group relative inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full text-lg font-semibold hover:shadow-lg hover:shadow-blue-500/25 transition-all transform hover:scale-105"
                        >
                            Get Started Free
                            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                        </Link>
                    </motion.div>

                    {}
                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.6 }}
                        className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-20 w-full"
                    >
                        <FeatureCard
                            icon={<PieChart className="w-8 h-8 text-blue-400" />}
                            title="Smart Analytics"
                            description="Visualize your spending habits with beautiful charts and insights."
                        />
                        <FeatureCard
                            icon={<Users className="w-8 h-8 text-purple-400" />}
                            title="Group Splitting"
                            description="Split bills with friends and family. We handle the math for you."
                        />
                        <FeatureCard
                            icon={<Shield className="w-8 h-8 text-pink-400" />}
                            title="Secure & Private"
                            description="Your financial data is encrypted and secure. Privacy first."
                        />
                    </motion.div>
                </div>
            </div>
        </div>
    );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
    return (
        <div className="p-6 bg-white/5 border border-white/10 rounded-2xl backdrop-blur-sm hover:bg-white/10 transition-colors text-left">
            <div className="mb-4 p-3 bg-white/5 rounded-xl w-fit">{icon}</div>
            <h3 className="text-xl font-semibold mb-2">{title}</h3>
            <p className="text-gray-400">{description}</p>
        </div>
    );
}
