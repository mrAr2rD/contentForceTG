import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content"]

  connect() {
    this.loadState()

    // Автоматически закрывать мобильный сайдбар при навигации
    this.boundCloseMobileOnNavigation = this.closeMobileOnNavigation.bind(this)
    document.addEventListener("turbo:before-visit", this.boundCloseMobileOnNavigation)

    // Закрывать по Escape
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.boundCloseMobileOnNavigation)
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeMobile()
    }
  }

  closeMobileOnNavigation() {
    // Закрываем сайдбар только на мобильных (когда overlay виден)
    if (this.hasOverlayTarget && !this.overlayTarget.classList.contains('hidden')) {
      this.closeMobile()
    }
  }

  toggle() {
    const isCollapsed = this.sidebarTarget.classList.contains('collapsed')

    if (isCollapsed) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  collapse() {
    this.sidebarTarget.classList.add('collapsed')
    localStorage.setItem('sidebar-collapsed', 'true')
  }

  expand() {
    this.sidebarTarget.classList.remove('collapsed')
    localStorage.setItem('sidebar-collapsed', 'false')
  }

  loadState() {
    const isCollapsed = localStorage.getItem('sidebar-collapsed') === 'true'
    if (isCollapsed) {
      this.sidebarTarget.classList.add('collapsed')
    }
  }

  // Mobile specific methods
  openMobile() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden')
      this.sidebarTarget.classList.remove('-translate-x-full')
      document.body.style.overflow = 'hidden'
    }
  }

  closeMobile() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden')
      this.sidebarTarget.classList.add('-translate-x-full')
      document.body.style.overflow = ''
    }
  }
}
