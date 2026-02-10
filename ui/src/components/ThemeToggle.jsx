import { useTheme } from '../contexts/ThemeContext';
import './ThemeToggle.css';

const ThemeToggle = () => {
    const { theme, toggleTheme } = useTheme();

    return (
        <button className="theme-toggle-button" onClick={toggleTheme} aria-label="Toggle theme">
            <span className="theme-icon">
                {theme === 'dark' ? '☀️' : '🌙'}
            </span>
        </button>
    );
};

export default ThemeToggle;
