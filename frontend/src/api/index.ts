import axios from 'axios';
import { tokenStorage } from './tokenStorage';

// Endpoints that must never go through the auto-attach/auto-refresh
// machinery below — login/signup have no token yet, and refresh's own
// 401s mean "the refresh token is dead," not "go refresh and retry".
const UNAUTHENTICATED_PATHS = [
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
];

const api = axios.create({
    baseURL: import.meta.env.VITE_BACKEND_URL + '/api',
    headers: {
        'Content-Type': 'application/json',
    },
});

api.interceptors.request.use((config) => {
    const path = config.url ?? '';
    if (!UNAUTHENTICATED_PATHS.some((p) => path.startsWith(p))) {
        const token = tokenStorage.getAccessToken();
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
    }
    return config;
});

// Single-flight guard so N concurrent 401s trigger exactly one refresh
// call instead of a stampede of parallel ones.
let refreshing: Promise<string> | null = null;

async function refreshAccessToken(): Promise<string> {
    if (refreshing) return refreshing;

    refreshing = (async () => {
        try {
            const refreshToken = tokenStorage.getRefreshToken();
            if (!refreshToken) throw new Error('No refresh token available');

            const response = await api.post('/auth/refresh', { refresh_token: refreshToken });
            const { access_token, refresh_token } = response.data;
            tokenStorage.setTokens(access_token, refresh_token);
            return access_token as string;
        } finally {
            refreshing = null;
        }
    })();

    return refreshing;
}

api.interceptors.response.use(
    (response) => response,
    async (error) => {
        const { config, response } = error;
        const path = config?.url ?? '';

        if (
            response?.status !== 401 ||
            UNAUTHENTICATED_PATHS.some((p) => path.startsWith(p)) ||
            config?._retried
        ) {
            return Promise.reject(error);
        }

        try {
            const newAccessToken = await refreshAccessToken();
            config._retried = true;
            config.headers = config.headers ?? {};
            config.headers.Authorization = `Bearer ${newAccessToken}`;
            return api(config);
        } catch (refreshError) {
            tokenStorage.clear();
            if (window.location.pathname !== '/auth') {
                window.location.href = '/auth';
            }
            return Promise.reject(refreshError);
        }
    },
);

export default api;
