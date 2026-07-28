import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// GitHub Pages serves this repo at /nyaya-agent/, so assets must be
// referenced with that base path in production.
export default defineConfig({
  plugins: [react()],
  base: '/nyaya-agent/',
})
