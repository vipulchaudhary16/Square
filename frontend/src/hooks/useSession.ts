import { useState, useEffect } from 'react';
import { getMe, logout as apiLogout } from '../api/auth';
import { tokenStorage } from '../api/tokenStorage';

interface User {
    id: string;
    username: string;
    email: string;
    first_name: string;
    last_name: string;
}

export const useSession = () => {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (tokenStorage.hasSession()) {
            getMe()
                .then((userData) => {
                    setUser(userData);
                })
                .catch(() => {
                    tokenStorage.clear();
                    setUser(null);
                })
                .finally(() => {
                    setLoading(false);
                });
        } else {
            setLoading(false);
        }
    }, []);

    const login = (userData: User, accessToken: string, refreshToken: string) => {
        tokenStorage.setTokens(accessToken, refreshToken);
        setUser(userData);
    };

    const logout = () => {
        apiLogout(tokenStorage.getRefreshToken()).catch(() => {});
        tokenStorage.clear();
        setUser(null);
    };

    return { user, loading, login, logout, isAuthenticated: !!user };
};
