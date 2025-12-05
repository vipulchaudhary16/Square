import React, { useState } from 'react';
import { Users, Plus, ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import useFetchData from '../../../hooks/useFetchData';
import { getUserGroups, Group } from '../../../api/groups';
import { CreateGroupModal } from '../components/CreateGroupModal';

export const GroupsPage: React.FC = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    const { data: groups, loading, error, refetch } = useFetchData({
        apiCall: getUserGroups
    });

    return (
        <div>
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Your Groups</h1>
                    <p className="text-gray-500 dark:text-slate-400">Manage your shared expenses and groups.</p>
                </div>
                <button
                    onClick={() => setIsModalOpen(true)}
                    className="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors w-full md:w-auto"
                >
                    <Plus className="w-4 h-4" />
                    Create Group
                </button>
            </div>

            {loading ? (
                <div className="flex justify-center p-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                </div>
            ) : error ? (
                <div className="text-center text-red-500 p-12">Failed to load groups.</div>
            ) : groups?.length === 0 ? (
                <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 p-6 md:p-12 text-center">
                    <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Users className="w-8 h-8 text-blue-500 dark:text-blue-400" />
                    </div>
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No groups yet</h3>
                    <p className="text-gray-500 dark:text-slate-400 max-w-sm mx-auto mb-6">
                        Create a group to start splitting bills with friends, roommates, or family members.
                    </p>
                    <button
                        onClick={() => setIsModalOpen(true)}
                        className="text-blue-600 dark:text-blue-400 font-medium hover:text-blue-700 dark:hover:text-blue-300"
                    >
                        Create your first group &rarr;
                    </button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {groups?.map((group: Group) => (
                        <Link
                            key={group.id}
                            to={`/groups/${group.id}`}
                            className="bg-white dark:bg-slate-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 hover:shadow-md transition-shadow block"
                        >
                            <div className="flex justify-between items-start mb-4">
                                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center text-white font-bold text-lg">
                                    {group.name.charAt(0).toUpperCase()}
                                </div>
                                <div className="bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded text-xs font-medium text-gray-600 dark:text-slate-300">
                                    {group.members.length} members
                                </div>
                            </div>
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-1">{group.name}</h3>
                            <p className="text-sm text-gray-500 dark:text-slate-400 mb-4 line-clamp-2">{group.description || "No description"}</p>
                            <div className="flex items-center text-blue-600 dark:text-blue-400 text-sm font-medium">
                                View Details <ArrowRight className="w-4 h-4 ml-1" />
                            </div>
                        </Link>
                    ))}
                </div>
            )}

            <CreateGroupModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                onSuccess={() => refetch(undefined)}
            />
        </div>
    );
};
