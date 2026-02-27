# 🎨 Synapse: Frontend Developer & UI/UX Blueprint

Welcome to the visual heart of Synapse. This guide explains how we achieve a "Premium SaaS" aesthetic using modern Web technologies, focusing on performance, themeability, and state management.

---

## 💎 The Synapse Design System (`index.css`)

We do not use messy utility classes. We use a **Variable-Driven Design System**.

### 1. Variables Over Hardcoding
- **The Core**: All colors, blurs, and border-radii are defined in `:root`.
- **Theme Switching**: Light mode is handled by re-defining those same variables inside `:root[data-theme="light"]`.
- **Junior Tip**: Never use `#hex` or `rgb()` in your component CSS. Always use `var(--color-name)`.

### 2. Glassmorphism Patterns
Our signature look is "Synapse Glass 2.0".
- **Implementation**: Combine `backdrop-filter: var(--glass-blur)` with a semi-transparent `background`.
- **Performance**: We reduced the blur from `20px` to `12px` to ensure the UI stays snappy—even on low-end GPUs.

---

## 🏗️ Core Architecture (`src/`)

### 1. State Management (`contexts/`)
We use React Context for cross-cutting concerns:
- **`AuthContext`**: Tracks the user ID, JWT token, and login status. It provides a `useAuth` hook.
- **`ThemeContext`**: Manages the dark/light state and persists it to `localStorage`.

### 2. Animated Background Engine (`BackgroundSystem.jsx`)
The "Dancing Orbs" are the soul of our UI.
- **Route-Awareness**: The background knows if you are on the Landing page or the Dashboard and "dances" to new positions.
- **Optimization**: We use `translate3d(x, y, 0)` instead of `top/left`. This moves rendering from the CPU to the **GPU**, which is why it runs at 60fps.
- **Senior Tip**: We use `radial-gradient` instead of `filter: blur()`. Gradients are much cheaper for the browser to render during motion.

### 3. Component Hierarchy
- **`NoteCard.jsx`**: A complex, memoized component that handles sentiment icons, tags, and hover triggers.
- **`Navbar.jsx`**: An adaptive floating bar that switches layout based on whether the user is logged in.

---

## 🚀 "How Do I..." Tutorial

### **"How do I add a new 'Statistics' page to the Dashboard?"**

1.  **Create the Component (`pages/Stats.jsx`)**: 
    Wrap it in the global layout. Ensure it has an `animate-in` class for smooth entry.
2.  **Define Styles (`pages/Stats.css`)**: 
    Import your styles and use the design system variables (`--bg-surface`, etc.).
3.  **Add the Route (`App.jsx`)**:
    Register the route inside the `Routes` block. If it's private, wrap it in `<ProtectedRoute>`.
4.  **Update Background (`BackgroundSystem.jsx`)**:
    Add a new case in the `useEffect` to define where the orbs should "dance" when on the stats page.

---

## 💡 Top UI/UX Performance Tips

1.  **GPU Acceleration**: Always use `will-change: transform` for elements that move frequently.
2.  **Z-Index Strategy**: 
    - `BackgroundSystem`: `-1`
    - `Content`: `1`
    - `Navbar`: `100`
    - `Modals`: `1000`
3.  **Memoization**: Use `React.memo` for repeated items (like `NoteCard`) to prevent unnecessary re-renders when the background orbs move.
4.  **Asset Handling**: Don't use heavy 4K images. Use **CSS Gradients** or **SVG** icons whenever possible to keep initial load times under 1 second.

---

*This guide is part of the Synapse Technical Blueprint. For backend details, please refer to the `BACKEND_DEV_GUIDE.md`.*
