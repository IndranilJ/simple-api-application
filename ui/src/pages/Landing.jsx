import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './Landing.css';

const Landing = () => {
    const { isAuthenticated } = useAuth();

    return (
        <div className="landing-container">
            <div className="landing-content">
                {/* Hero Section */}
                <div className="hero">
                    <div className="hero-icon">🧠</div>
                    <h1 className="hero-title">Synapse</h1>
                    <p className="hero-subtitle">Your intelligent memory companion</p>
                    <p className="hero-description">
                        Capture your thoughts, organize your ideas, and let AI analyze your notes
                    </p>
                </div>

                {/* CTA Buttons */}
                <div className="cta-buttons">
                    {isAuthenticated ? (
                        <Link to="/notes" className="cta-button primary">
                            Go to Notes →
                        </Link>
                    ) : (
                        <>
                            <Link to="/register" className="cta-button primary">
                                Get Started
                            </Link>
                            <Link to="/login" className="cta-button secondary">
                                Sign In
                            </Link>
                        </>
                    )}
                </div>

                {/* Features */}
                <div className="features-grid">
                    <div className="feature-card">
                        <div className="feature-icon">✨</div>
                        <h3>Smart Notes</h3>
                        <p>Create and organize notes with tags and powerful search</p>
                    </div>
                    <div className="feature-card">
                        <div className="feature-icon">🤖</div>
                        <h3>AI Analysis</h3>
                        <p>Sentiment analysis powered by machine learning</p>
                    </div>
                    <div className="feature-card">
                        <div className="feature-icon">🔒</div>
                        <h3>Secure</h3>
                        <p>Your data is private and protected with authentication</p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Landing;
