import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Proxy all API routes to backend
      '/notes': {
        target: 'http://127.0.0.1:8004',
        changeOrigin: true,
      },
      '/tags': {
        target: 'http://127.0.0.1:8004',
        changeOrigin: true,
      },
    }
  }
})
