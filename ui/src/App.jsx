import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import ProtectedRoute from './components/ProtectedRoute';
import Navbar from './components/Navbar';
import Landing from './pages/Landing';
import Login from './pages/Login';
import Register from './pages/Register';
import Notes from './pages/Notes';
import BackgroundSystem from './components/BackgroundSystem';
import './App.css';

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <div className="app">
            <BackgroundSystem />
            {/* Navigation Bar */}
            <Navbar />

            {/* Routes */}
            <Routes>
              <Route path="/" element={<Landing />} />
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />
              <Route
                path="/notes"
                element={
                  <ProtectedRoute>
                    <Notes />
                  </ProtectedRoute>
                }
              />
              {/* Redirect unknown routes to home */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </div>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
