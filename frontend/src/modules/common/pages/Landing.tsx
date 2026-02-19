import { motion } from 'framer-motion';
import {
    ArrowRight,
    Users,
    TrendingUp,
    Wallet,
    BarChart3,
    Sparkles,
    ArrowLeftRight,
} from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Landing() {
    return (
        <div className="min-h-screen bg-[#0f172a] text-white overflow-hidden selection:bg-purple-500/30">
            <div className="fixed inset-0 overflow-hidden pointer-events-none">
                <div className="absolute top-[-10%] left-[-10%] w-[600px] h-[600px] bg-purple-500/20 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] bg-blue-500/20 rounded-full blur-[120px]" />
                <div className="absolute top-[40%] left-[30%] w-[400px] h-[400px] bg-pink-500/10 rounded-full blur-[100px]" />
            </div>

            <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <nav className="flex justify-between items-center py-6 backdrop-blur-md sticky top-0 z-50">
                    <div className="flex items-center gap-2">
                        <div className="p-2 bg-gradient-to-tr from-blue-600 to-purple-600 rounded-lg">
                            <Wallet className="w-6 h-6 text-white" />
                        </div>
                        <span className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-400">
                            ExpenseTracker
                        </span>
                    </div>
                    <div className="flex items-center gap-4">
                        <Link
                            to="/auth"
                            className="hidden sm:block text-gray-300 hover:text-white transition-colors"
                        >
                            Log In
                        </Link>
                        <Link
                            to="/auth"
                            className="px-5 py-2.5 bg-white text-gray-900 font-medium rounded-full hover:bg-gray-100 transition-colors shadow-lg shadow-white/10"
                        >
                            Get Started
                        </Link>
                    </div>
                </nav>

                {/* Hero Section */}
                <div className="flex flex-col items-center justify-center pt-20 pb-32 text-center">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.6 }}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-white/5 border border-white/10 rounded-full mb-8 backdrop-blur-sm"
                    >
                        <span className="flex h-2 w-2 rounded-full bg-green-400 animate-pulse"></span>
                        <span className="text-sm font-medium text-gray-300">
                            New: Investment Tracking & Budgeting
                        </span>
                    </motion.div>

                    <motion.h1
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.1 }}
                        className="text-5xl md:text-7xl font-bold mb-8 leading-tight tracking-tight"
                    >
                        Smart Finance for <br />
                        <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400">
                            Modern Living
                        </span>
                    </motion.h1>

                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                        className="text-xl text-gray-400 mb-10 max-w-2xl leading-relaxed"
                    >
                        Track expenses, split bills, manage investments, and plan your budget. All
                        in one beautiful, secure place.
                    </motion.p>

                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.3 }}
                        className="flex flex-col sm:flex-row gap-4 mb-20"
                    >
                        <Link
                            to="/auth"
                            className="group relative inline-flex items-center justify-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full text-lg font-semibold hover:shadow-lg hover:shadow-blue-500/25 transition-all transform hover:scale-105"
                        >
                            Start for Free
                            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                        </Link>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 1, delay: 0.4 }}
                        className="relative w-full max-w-5xl mx-auto"
                    >
                        <div className="absolute inset-0 bg-gradient-to-t from-[#0f172a] via-transparent to-transparent z-10" />
                        <div className="rounded-xl overflow-hidden border border-white/10 shadow-2xl shadow-purple-500/20 ring-1 ring-white/10">
                            <img
                                src="/images/Dashboard.png"
                                alt="App Dashboard"
                                className="w-full h-auto object-cover transform hover:scale-[1.01] transition-transform duration-700 overflow-hidden"
                            />
                        </div>
                    </motion.div>
                </div>

                {/* Features Grid */}
                <div id="features" className="py-24 border-t border-white/5">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl md:text-4xl font-bold mb-4">Everything you need</h2>
                        <p className="text-gray-400 max-w-2xl mx-auto">
                            Comprehensive tools to take control of your financial life.
                        </p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                        <FeatureCard
                            icon={<BarChart3 className="w-8 h-8 text-blue-400" />}
                            title="Analytics & Reports"
                            description="Visualize spending patterns with interactive charts. Understand where your money goes at a glance."
                        />
                        <FeatureCard
                            icon={<Users className="w-8 h-8 text-purple-400" />}
                            title="Group Splitting"
                            description="Split bills with friends, roommates, or family. We calculate who owes what automatically."
                        />
                        <FeatureCard
                            icon={<TrendingUp className="w-8 h-8 text-green-400" />}
                            title="Investments"
                            description="Track your portfolio performance. Stocks, crypto, and assets all in one view."
                        />
                        <FeatureCard
                            icon={<Wallet className="w-8 h-8 text-pink-400" />}
                            title="Budget Planning"
                            description="Set monthly budgets for different categories. Get alerted when you're close to limits."
                        />
                        <FeatureCard
                            icon={<ArrowLeftRight className="w-8 h-8 text-indigo-400" />}
                            title="Loan Management"
                            description="Keep track of money lent to and borrowed from friends. Never forget a debt again."
                        />
                        <FeatureCard
                            icon={<Sparkles className="w-8 h-8 text-amber-400" />}
                            title="AI Insights"
                            description="Get personalized financial advice and spending analysis. (Coming Soon)"
                        />
                    </div>
                </div>

                <div className="py-24 text-center">
                    <div className="bg-gradient-to-r from-blue-600/20 to-purple-600/20 rounded-3xl p-12 border border-white/10 backdrop-blur-sm">
                        <h2 className="text-4xl font-bold mb-6">Ready to take control?</h2>
                        <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
                            Join some of users who are mastering their finances with Square and
                            Split.
                        </p>
                        <Link
                            to="/auth"
                            className="bg-white text-gray-900 px-8 py-4 rounded-full font-bold text-lg hover:bg-gray-100 transition-colors shadow-lg"
                        >
                            Create Free Account
                        </Link>
                    </div>
                </div>

                {/* Footer */}
                <footer className="border-t border-white/10 py-12 text-center text-gray-500 text-sm">
                    <div className="flex justify-center gap-8 mb-8">
                        <a href="#" className="hover:text-white transition-colors">
                            Privacy
                        </a>
                        <a href="#" className="hover:text-white transition-colors">
                            Terms
                        </a>
                        <a href="#" className="hover:text-white transition-colors">
                            Contact
                        </a>
                        <a href="#" className="hover:text-white transition-colors">
                            Twitter
                        </a>
                    </div>
                    <p>© 2024 ExpenseTracker. All rights reserved.</p>
                </footer>
            </div>
        </div>
    );
}

function FeatureCard({
    icon,
    title,
    description,
    image,
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
    image?: string;
}) {
    return (
        <div className="group p-8 bg-white/5 border border-white/10 rounded-2xl backdrop-blur-sm hover:bg-white/10 transition-all hover:-translate-y-1">
            <div className="mb-6 p-4 bg-white/5 rounded-xl w-fit group-hover:scale-110 transition-transform duration-300">
                {icon}
            </div>
            <h3 className="text-xl font-bold mb-3">{title}</h3>
            <p className="text-gray-400 leading-relaxed mb-6">{description}</p>
            {image && (
                <div className="mt-4 rounded-lg overflow-hidden border border-white/5 opacity-80 group-hover:opacity-100 transition-opacity">
                    <img src={image} alt={title} className="w-full h-40 object-cover object-top" />
                </div>
            )}
        </div>
    );
}
