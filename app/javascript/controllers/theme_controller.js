import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  connect() {
    this.loadTheme()
  }

  toggle() {
    const isDark = document.documentElement.classList.contains('dark')

    if (isDark) {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    } else {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    }
  }

  loadTheme() {
    // Only use manually set theme from localStorage
    // Default to light theme if nothing is set (no auto-detection)
    const theme = localStorage.getItem('theme') || 'light'

    if (theme === 'dark') {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }

    // Set initial theme in localStorage if not already set
    if (!localStorage.getItem('theme')) {
      localStorage.setItem('theme', 'light')
    }
  }
}
