import React, { useState } from 'react';
import { Plus, ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import useFetchData from '../../../hooks/useFetchData';
import { getUserGroups, Group } from '../../../api/groups';
import { CreateGroupModal } from '../components/CreateGroupModal';
import { EmptyState } from '../../common/components/ui/EmptyState';

export const GroupsPage: React.FC = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    const {
        data: groups,
        loading,
        error,
        refetch,
    } = useFetchData({
        apiCall: getUserGroups,
    });
    console.log(groups);

    return (
        <div>
            <div className="flex flex-row justify-between items-center gap-4 mb-6">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Your Groups
                    </h1>
                    <p className="text-gray-500 dark:text-slate-400 hidden sm:block">
                        Manage your shared expenses.
                    </p>
                </div>
                <button
                    onClick={() => setIsModalOpen(true)}
                    className="flex items-center justify-center gap-2 px-3 py-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm whitespace-nowrap"
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
            ) : groups?.length === 0 || !groups ? (
                <EmptyState
                    title="No groups yet"
                    description="Create a group to start splitting bills with friends, roommates, or family members."
                />
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {groups?.map((group: Group) => (
                        <Link
                            key={group.id}
                            to={`/groups/${group.id}`}
                            className="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-gray-200 dark:border-slate-700 hover:shadow-md transition-shadow block"
                        >
                            <div className="flex justify-between items-start">
                                <div className="flex-1 min-w-0 mr-4">
                                    <div className="flex items-center gap-3 mb-1">
                                        <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex-shrink-0 flex items-center justify-center text-white font-bold text-base">
                                            {group.name.charAt(0).toUpperCase()}
                                        </div>
                                        <h3 className="text-base font-bold text-gray-900 dark:text-white truncate">
                                            {group.name}
                                        </h3>
                                    </div>
                                    <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-2 pl-11">
                                        {group.description || 'No description'}
                                    </p>
                                </div>
                                <div className="flex flex-col items-end gap-2 flex-shrink-0">
                                    <div className="bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded text-xs font-medium text-gray-600 dark:text-slate-300 whitespace-nowrap">
                                        {group.members.length} members
                                    </div>
                                    <div className="flex items-center text-blue-600 dark:text-blue-400 text-xs font-medium whitespace-nowrap">
                                        View <ArrowRight className="w-3 h-3 ml-1" />
                                    </div>
                                </div>
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
