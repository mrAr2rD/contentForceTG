import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["lightButton", "darkButton"]

  connect() {
    this.loadTheme()
    this.updateButtons()
  }

  toggle() {
    const isDark = document.documentElement.classList.contains('dark')

    if (isDark) {
      this.setLight()
    } else {
      this.setDark()
    }
  }

  setLight() {
    document.documentElement.classList.remove('dark')
    localStorage.setItem('theme', 'light')
    this.updateButtons()
  }

  setDark() {
    document.documentElement.classList.add('dark')
    localStorage.setItem('theme', 'dark')
    this.updateButtons()
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

  updateButtons() {
    const isDark = document.documentElement.classList.contains('dark')

    // Update button styles if targets exist
    if (this.hasLightButtonTarget && this.hasDarkButtonTarget) {
      if (isDark) {
        this.lightButtonTarget.classList.remove('border-primary', 'bg-primary-50', 'dark:bg-primary-900/20')
        this.lightButtonTarget.classList.add('border-border')
        this.darkButtonTarget.classList.remove('border-border')
        this.darkButtonTarget.classList.add('border-primary', 'bg-primary-50', 'dark:bg-primary-900/20')
      } else {
        this.darkButtonTarget.classList.remove('border-primary', 'bg-primary-50', 'dark:bg-primary-900/20')
        this.darkButtonTarget.classList.add('border-border')
        this.lightButtonTarget.classList.remove('border-border')
        this.lightButtonTarget.classList.add('border-primary', 'bg-primary-50', 'dark:bg-primary-900/20')
      }
    }
  }
}
