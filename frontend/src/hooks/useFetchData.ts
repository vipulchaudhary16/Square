import { useEffect, useState } from 'react';

interface Props<T> {
    apiCall: (payload: any) => Promise<T>;
    dependencies?: any[];
    payload?: any;
}

interface UseFetchDataReturn<T> {
    data: T | null;
    loading: boolean;
    error: any;
    refetch: (payload: any) => Promise<void>;
}

const useFetchData = <T,>(props: Props<T>): UseFetchDataReturn<T> => {
    const [data, setData] = useState<T | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<any>(null);

    const { apiCall, dependencies = [], payload } = props;

    const fetchData = async () => {
        try {
            setLoading(true);
            const result = await apiCall(payload);
            setData(result);
        } catch (err) {
            setError(err);
        } finally {
            setLoading(false);
        }
    };

    const refetch = async (newPayload: any) => {
        try {
            setLoading(true);
            const result = await apiCall(newPayload);
            setData(result);
        } catch (err) {
            setError(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
        
    }, dependencies);

    return { data, loading, error, refetch };
};

export default useFetchData;
