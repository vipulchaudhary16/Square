import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { CheckCircle2, XCircle, Loader2 } from 'lucide-react';
import useApiCall from '../../../hooks/useApiCall';
import { joinGroup } from '../../../api/groups';

export const JoinGroupPage: React.FC = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();
    const token = searchParams.get('token');
    const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
    const [message, setMessage] = useState('');
    const [groupId, setGroupId] = useState('');

    const { execute } = useApiCall({
        apiCall: joinGroup,
    });

    useEffect(() => {
        if (!token) {
            setStatus('error');
            setMessage('Invalid invitation link.');
            return;
        }

        const join = async () => {
            try {
                const res = await execute(token);
                setStatus('success');
                setMessage('You have successfully joined the group!');
                setGroupId(res.group_id);
            } catch (err: any) {
                setStatus('error');
                setMessage(
                    err.response?.data?.error || 'Failed to join group. The link may be expired.',
                );
            }
        };

        join();
    }, [token]);

    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900 p-4 transition-colors duration-300">
            <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-8 max-w-md w-full text-center border dark:border-slate-700">
                {status === 'loading' && (
                    <div className="flex flex-col items-center">
                        <Loader2 className="w-12 h-12 text-blue-600 animate-spin mb-4" />
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                            Joining Group...
                        </h2>
                        <p className="text-gray-500 dark:text-slate-400 mt-2">
                            Please wait while we verify your invitation.
                        </p>
                    </div>
                )}

                {status === 'success' && (
                    <div className="flex flex-col items-center">
                        <div className="w-16 h-16 bg-green-100 dark:bg-green-900/20 rounded-full flex items-center justify-center mb-4">
                            <CheckCircle2 className="w-8 h-8 text-green-600 dark:text-green-400" />
                        </div>
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                            Welcome!
                        </h2>
                        <p className="text-gray-600 dark:text-slate-300 mt-2 mb-6">{message}</p>
                        <button
                            onClick={() => navigate(`/groups/${groupId}`)}
                            className="w-full py-2 px-4 bg-blue-600 text-white rounded-md font-medium hover:bg-blue-700 transition-colors"
                        >
                            View Group
                        </button>
                    </div>
                )}

                {status === 'error' && (
                    <div className="flex flex-col items-center">
                        <div className="w-16 h-16 bg-red-100 dark:bg-red-900/20 rounded-full flex items-center justify-center mb-4">
                            <XCircle className="w-8 h-8 text-red-600 dark:text-red-400" />
                        </div>
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Oops!</h2>
                        <p className="text-gray-600 dark:text-slate-300 mt-2 mb-6">{message}</p>
                        <button
                            onClick={() => navigate('/dashboard')}
                            className="w-full py-2 px-4 bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-slate-300 rounded-md font-medium hover:bg-gray-200 dark:hover:bg-slate-600 transition-colors"
                        >
                            Go to Dashboard
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};
