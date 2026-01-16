import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content"]

  connect() {
    this.loadState()
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
