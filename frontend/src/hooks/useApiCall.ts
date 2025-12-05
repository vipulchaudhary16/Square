import { useState } from 'react';

interface Props<T extends (...args: any[]) => Promise<any>> {
    apiCall: T;
}

const useApiCall = <T extends (...args: any[]) => Promise<any>>({ apiCall }: Props<T>) => {
    const [data, setData] = useState<Awaited<ReturnType<T>> | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<any>(null);

    const execute = async (...args: Parameters<T>) => {
        try {
            setLoading(true);
            setError(null);
            const response = await apiCall(...args);
            setData(response);
            return response;
        } catch (err) {
            setError(err);
            console.error(err);
            throw err;
        } finally {
            setLoading(false);
        }
    };

    return { data, loading, error, execute };
};

export default useApiCall;
