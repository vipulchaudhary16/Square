import React, { useEffect, useState } from 'react';
import { Tag, Plus, Trash2, Lock, Pencil, X, Check } from 'lucide-react';
import {
    getCategories,
    createCategory,
    updateCategory,
    deleteCategory,
    Category,
} from '../../../api/categories';

const TYPE_LABELS: Record<string, string> = {
    expense: 'Expense',
    income: 'Income',
    budget: 'Budget',
};

export const CategoriesPage: React.FC = () => {
    const [categories, setCategories] = useState<Category[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [newName, setNewName] = useState('');
    const [newAppliesTo, setNewAppliesTo] = useState<string[]>(['expense', 'income', 'budget']);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editName, setEditName] = useState('');
    const [editAppliesTo, setEditAppliesTo] = useState<string[]>([]);

    const load = async () => {
        try {
            const data = await getCategories();
            setCategories(data);
        } catch {
            setError('Failed to load categories');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newName.trim() || newAppliesTo.length === 0) return;
        try {
            await createCategory({ name: newName.trim(), applies_to: newAppliesTo });
            setNewName('');
            setNewAppliesTo(['expense', 'income', 'budget']);
            setShowForm(false);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to create category');
        }
    };

    const handleDelete = async (cat: Category) => {
        if (!confirm(`Deleting "${cat.name}" will move all its records to "Other". Continue?`)) return;
        try {
            await deleteCategory(cat.id);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to delete category');
        }
    };

    const startEdit = (cat: Category) => {
        setEditingId(cat.id);
        setEditName(cat.name);
        setEditAppliesTo([...cat.applies_to]);
    };

    const handleUpdate = async (cat: Category) => {
        if (!editName.trim() || editAppliesTo.length === 0) return;
        try {
            await updateCategory(cat.id, { name: editName.trim(), applies_to: editAppliesTo });
            setEditingId(null);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to update category');
        }
    };

    const toggleType = (types: string[], type: string, setter: (v: string[]) => void) => {
        setter(types.includes(type) ? types.filter((t) => t !== type) : [...types, type]);
    };

    if (loading) return <div className="p-6">Loading...</div>;

    return (
        <div className="max-w-2xl mx-auto p-6">
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-2">
                    <Tag className="w-5 h-5 text-primary-600" />
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Categories</h1>
                </div>
                <button
                    onClick={() => setShowForm(!showForm)}
                    className="flex items-center gap-2 bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
                >
                    <Plus className="w-4 h-4" />
                    Add Category
                </button>
            </div>

            {error && (
                <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-xl text-sm">
                    {error}
                </div>
            )}

            {showForm && (
                <form
                    onSubmit={handleCreate}
                    className="mb-6 p-4 bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm"
                >
                    <h2 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-3">
                        New Category
                    </h2>
                    <input
                        type="text"
                        required
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        placeholder="Category name"
                        className="w-full p-2 border rounded-lg mb-3 text-sm bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-900 dark:text-white"
                    />
                    <div className="flex gap-2 mb-3">
                        {['expense', 'income', 'budget'].map((type) => (
                            <button
                                key={type}
                                type="button"
                                onClick={() => toggleType(newAppliesTo, type, setNewAppliesTo)}
                                className={`px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                                    newAppliesTo.includes(type)
                                        ? 'bg-primary-100 dark:bg-primary-900/30 border-primary-400 text-primary-700 dark:text-primary-300'
                                        : 'bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-500'
                                }`}
                            >
                                {TYPE_LABELS[type]}
                            </button>
                        ))}
                    </div>
                    <div className="flex gap-2">
                        <button
                            type="submit"
                            className="flex-1 bg-primary-600 hover:bg-primary-700 text-white py-2 rounded-lg text-sm font-medium"
                        >
                            Create
                        </button>
                        <button
                            type="button"
                            onClick={() => setShowForm(false)}
                            className="px-4 py-2 text-sm text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg"
                        >
                            Cancel
                        </button>
                    </div>
                </form>
            )}

            <div className="space-y-2">
                {categories.map((cat) => (
                    <div
                        key={cat.id}
                        className="flex items-center gap-3 p-4 bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700"
                    >
                        {editingId === cat.id ? (
                            <div className="flex-1 flex flex-col gap-2">
                                <input
                                    type="text"
                                    value={editName}
                                    onChange={(e) => setEditName(e.target.value)}
                                    className="w-full p-1.5 border rounded-lg text-sm bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-900 dark:text-white"
                                />
                                <div className="flex gap-2">
                                    {['expense', 'income', 'budget'].map((type) => (
                                        <button
                                            key={type}
                                            type="button"
                                            onClick={() => toggleType(editAppliesTo, type, setEditAppliesTo)}
                                            className={`px-2 py-0.5 rounded-full text-xs font-medium border ${
                                                editAppliesTo.includes(type)
                                                    ? 'bg-primary-100 dark:bg-primary-900/30 border-primary-400 text-primary-700 dark:text-primary-300'
                                                    : 'bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-400'
                                            }`}
                                        >
                                            {TYPE_LABELS[type]}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        ) : (
                            <div className="flex-1">
                                <div className="flex items-center gap-2">
                                    <span className="font-medium text-slate-900 dark:text-white">
                                        {cat.name}
                                    </span>
                                    {cat.is_standard && (
                                        <Lock className="w-3 h-3 text-slate-400" />
                                    )}
                                </div>
                                <div className="flex gap-1 mt-1">
                                    {cat.applies_to.map((type) => (
                                        <span
                                            key={type}
                                            className="text-xs px-2 py-0.5 bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400 rounded-full"
                                        >
                                            {TYPE_LABELS[type]}
                                        </span>
                                    ))}
                                </div>
                            </div>
                        )}

                        {!cat.is_standard && (
                            <div className="flex gap-1">
                                {editingId === cat.id ? (
                                    <>
                                        <button
                                            onClick={() => handleUpdate(cat)}
                                            className="p-1.5 text-green-600 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg"
                                        >
                                            <Check className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => setEditingId(null)}
                                            className="p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg"
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                    </>
                                ) : (
                                    <>
                                        <button
                                            onClick={() => startEdit(cat)}
                                            className="p-1.5 text-slate-400 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/20 rounded-lg"
                                        >
                                            <Pencil className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(cat)}
                                            className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg"
                                        >
                                            <Trash2 className="w-4 h-4" />
                                        </button>
                                    </>
                                )}
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};
