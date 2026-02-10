import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './Navbar.css';

const Navbar = () => {
    const { user, isAuthenticated, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        await logout();
        navigate('/');
    };

    return (
        <nav className="navbar">
            <div className="navbar-content">
                <Link to="/" className="navbar-brand">
                    <span className="brand-icon">🧠</span>
                    Synapse
                </Link>

                <div className="navbar-right">
                    {isAuthenticated ? (
                        <>
                            <Link to="/notes" className="nav-link">
                                Notes
                            </Link>
                            <div className="user-menu">
                                <span className="user-name">{user?.name}</span>
                                <button onClick={handleLogout} className="logout-button">
                                    Logout
                                </button>
                            </div>
                        </>
                    ) : (
                        <>
                            <Link to="/login" className="nav-link">
                                Sign In
                            </Link>
                            <Link to="/register" className="nav-button">
                                Get Started
                            </Link>
                        </>
                    )}
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
