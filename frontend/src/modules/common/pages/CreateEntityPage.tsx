import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FormLayout } from '../components/ui/FormLayout';
import { AddExpenseForm } from '../../expense/components/AddExpenseForm';
import { InvestmentForm } from '../../investment/components/InvestmentForm';
import { LoanForm } from '../../loan/components/LoanForm';
import { IncomeForm } from '../../income/components/IncomeForm';

export const CreateEntityPage: React.FC = () => {
    const { type } = useParams<{ type: string }>();
    const navigate = useNavigate();

    const handleSuccess = () => {
        navigate(-1);
    };

    const handleCancel = () => {
        navigate(-1);
    };

    const renderForm = () => {
        switch (type) {
            case 'expense':
                return (
                    <AddExpenseForm
                        onSuccess={handleSuccess}
                        onCancel={handleCancel}
                        hideHeader={true}
                        formId="expense-form"
                    />
                );
            case 'investment':
                return (
                    <InvestmentForm
                        onSuccess={handleSuccess}
                        onCancel={handleCancel}
                    />
                );
            case 'loan':
                return (
                    <LoanForm
                        onSuccess={handleSuccess}
                        onCancel={handleCancel}
                    />
                );
            case 'income':
                return (
                    <IncomeForm
                        onSuccess={handleSuccess}
                        onCancel={handleCancel}
                    />
                );
            default:
                return <div>Invalid type</div>;
        }
    };

    const getTitle = () => {
        switch (type) {
            case 'expense': return 'Add New Expense';
            case 'investment': return 'Add New Investment';
            case 'loan': return 'Add New Loan';
            case 'income': return 'Add New Income';
            default: return 'Create New';
        }
    };

    const getSubmitButtonText = () => {
        switch (type) {
            default: return 'Save';
        }
    };

    return (
        <FormLayout
            title={getTitle()}
            onClose={handleCancel}
            actions={
                <button
                    type="submit"
                    form={`${type}-form`}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium shadow-sm shadow-blue-600/20"
                >
                    {getSubmitButtonText()}
                </button>
            }
        >
            {renderForm()}
        </FormLayout>
    );
};
