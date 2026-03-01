import api from './api';

/**
 * Authentication Service
 * Handles all auth-related API calls
 */

export const authService = {
    /**
     * Register a new user
     * @param {string} email - User email
     * @param {string} password - User password
     * @param {string} name - User display name
     * @returns {Promise<{access_token, refresh_token, token_type}>}
     */
    async register(email, password, name) {
        const response = await api.post('auth/register', {
            email,
            password,
            name,
        });
        return response.data;
    },

    /**
     * Login user
     * @param {string} email - User email
     * @param {string} password - User password
     * @returns {Promise<{access_token, refresh_token, token_type}>}
     */
    async login(email, password) {
        const response = await api.post('auth/login', {
            email,
            password,
        });
        return response.data;
    },

    /**
     * Logout user
     * @returns {Promise<void>}
     */
    async logout() {
        try {
            await api.post('auth/logout');
        } catch (error) {
            // Even if logout fails on server, we still clear local tokens
            console.error('Logout error:', error);
        }
    },

    /**
     * Get current user info
     * @returns {Promise<{id, email, name, is_active}>}
     */
    async getCurrentUser() {
        const response = await api.get('auth/me');
        return response.data;
    },

    /**
     * Refresh access token
     * @param {string} refreshToken - Refresh token
     * @returns {Promise<{access_token, refresh_token, token_type}>}
     */
    async refreshToken(refreshToken) {
        const response = await api.post('auth/refresh', {
            refresh_token: refreshToken,
        });
        return response.data;
    },
};

export default authService;
