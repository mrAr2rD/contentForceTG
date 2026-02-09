import { Controller } from "@hotwired/stimulus"

// Контроллер для бесконечной прокрутки с Turbo Frames
export default class extends Controller {
  static targets = ["sentinel", "loading"]
  static values = {
    url: String,
    loading: { type: Boolean, default: false }
  }

  connect() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersect(entries),
      { rootMargin: "200px" }
    )

    if (this.hasSentinelTarget) {
      this.observer.observe(this.sentinelTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && !this.loadingValue && this.urlValue) {
        this.loadMore()
      }
    })
  }

  async loadMore() {
    if (this.loadingValue || !this.urlValue) return

    this.loadingValue = true
    this.showLoading()

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Infinite scroll error:", error)
    } finally {
      this.loadingValue = false
      this.hideLoading()
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  // Обновление URL для следующей страницы
  updateUrl(url) {
    this.urlValue = url
    if (!url && this.hasSentinelTarget) {
      this.observer.unobserve(this.sentinelTarget)
      this.sentinelTarget.remove()
    }
  }
}
