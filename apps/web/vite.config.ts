import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Two deploy targets share this config:
// - Vercel (primary — serves the /api proxy too) sets VERCEL=1 during build, root path "/"
// - GitHub Pages serves this repo at /nyaya-agent/ (static-only mirror, no /api backend)
export default defineConfig({
  plugins: [react()],
  base: process.env.VERCEL ? '/' : '/nyaya-agent/',
})
