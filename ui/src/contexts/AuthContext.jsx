import React, { createContext, useContext, useState, useEffect } from 'react';
import authService from '../services/authService';

const AuthContext = createContext(null);

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [accessToken, setAccessToken] = useState(null);
    const [refreshToken, setRefreshToken] = useState(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    // Initialize auth state from localStorage
    useEffect(() => {
        const initAuth = async () => {
            try {
                const storedAccessToken = localStorage.getItem('accessToken');
                const storedRefreshToken = localStorage.getItem('refreshToken');
                const storedUser = localStorage.getItem('user');

                if (storedAccessToken && storedRefreshToken) {
                    setAccessToken(storedAccessToken);
                    setRefreshToken(storedRefreshToken);

                    // Try to fetch current user to validate token
                    try {
                        const userData = await authService.getCurrentUser();
                        setUser(userData); setIsAuthenticated(true);

                        // Update stored user data
                        localStorage.setItem('user', JSON.stringify(userData));
                    } catch (error) {
                        // Token invalid, clear everything
                        console.error('Token validation failed:', error);
                        clearAuth();
                    }
                } else if (storedUser) {
                    // Have user data but no tokens - clear it
                    localStorage.removeItem('user');
                }
            } catch (error) {
                console.error('Auth initialization error:', error);
                clearAuth();
            } finally {
                setIsLoading(false);
            }
        };

        initAuth();
    }, []);

    const clearAuth = () => {
        setUser(null);
        setAccessToken(null);
        setRefreshToken(null);
        setIsAuthenticated(false);
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
    };

    const login = async (email, password) => {
        try {
            const data = await authService.login(email, password);

            // Store tokens
            setAccessToken(data.access_token);
            setRefreshToken(data.refresh_token);
            localStorage.setItem('accessToken', data.access_token);
            localStorage.setItem('refreshToken', data.refresh_token);

            // Fetch and store user data
            const userData = await authService.getCurrentUser();
            setUser(userData);
            setIsAuthenticated(true);
            localStorage.setItem('user', JSON.stringify(userData));

            return { success: true };
        } catch (error) {
            console.error('Login error:', error);
            return {
                success: false,
                error: error.response?.data?.detail || 'Login failed. Please try again.',
            };
        }
    };

    const register = async (email, password, name) => {
        try {
            const data = await authService.register(email, password, name);

            // Store tokens
            setAccessToken(data.access_token);
            setRefreshToken(data.refresh_token);
            localStorage.setItem('accessToken', data.access_token);
            localStorage.setItem('refreshToken', data.refresh_token);

            // Fetch and store user data
            const userData = await authService.getCurrentUser();
            setUser(userData);
            setIsAuthenticated(true);
            localStorage.setItem('user', JSON.stringify(userData));

            return { success: true };
        } catch (error) {
            console.error('Registration error:', error);
            return {
                success: false,
                error: error.response?.data?.detail || 'Registration failed. Please try again.',
            };
        }
    };

    const logout = async () => {
        try {
            await authService.logout();
        } catch (error) {
            console.error('Logout error:', error);
        } finally {
            clearAuth();
        }
    };

    const value = {
        user,
        accessToken,
        refreshToken,
        isLoading,
        isAuthenticated,
        login,
        register,
        logout,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export default AuthContext;
