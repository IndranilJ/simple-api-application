import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import './BackgroundSystem.css';

/**
 * BackgroundSystem Component
 * Manages floating, route-aware "Dancing Orbs" that shift position based on the current page.
 * Strictly adheres to CSS variables for all styling.
 */
const BackgroundSystem = () => {
    const location = useLocation();
    const [pageClass, setPageClass] = useState('page-home');

    useEffect(() => {
        // Map current route to specific background positioning classes
        const path = location.pathname;
        if (path === '/') setPageClass('page-landing');
        else if (path === '/login' || path === '/register') setPageClass('page-auth');
        else if (path === '/notes') setPageClass('page-dashboard');
        else setPageClass('page-default');
    }, [location]);

    return (
        <div className={`background-system ${pageClass}`}>
            <div className="orb orb-1"></div>
            <div className="orb orb-2"></div>
            <div className="orb orb-3"></div>
            <div className="background-overlay"></div>
        </div>
    );
};

export default BackgroundSystem;
