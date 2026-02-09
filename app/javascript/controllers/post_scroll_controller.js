import { Controller } from "@hotwired/stimulus"

// Контроллер для подгрузки следующего поста при скролле
export default class extends Controller {
  static targets = ["nextPost", "sentinel"]
  static values = {
    url: String,
    slug: String,
    title: String,
    loading: { type: Boolean, default: false },
    loaded: { type: Boolean, default: false }
  }

  connect() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersect(entries),
      { rootMargin: "400px", threshold: 0 }
    )

    if (this.hasSentinelTarget) {
      this.observer.observe(this.sentinelTarget)
    }

    // Отслеживание текущего поста для обновления URL
    this.postObserver = new IntersectionObserver(
      entries => this.handlePostVisibility(entries),
      { rootMargin: "-50% 0px -50% 0px", threshold: 0 }
    )
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.postObserver) {
      this.postObserver.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && !this.loadingValue && !this.loadedValue && this.urlValue) {
        this.loadNextPost()
      }
    })
  }

  handlePostVisibility(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const slug = entry.target.dataset.postSlug
        const title = entry.target.dataset.postTitle

        if (slug && window.location.pathname !== `/post/${slug}`) {
          // Обновляем URL без перезагрузки страницы
          window.history.replaceState(
            { slug },
            title,
            `/post/${slug}`
          )

          // Обновляем title страницы
          if (title) {
            document.title = title
          }
        }
      }
    })
  }

  async loadNextPost() {
    if (this.loadingValue || this.loadedValue || !this.urlValue) return

    this.loadingValue = true
    this.showLoading()

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()

        // Вставляем HTML следующего поста
        if (this.hasNextPostTarget) {
          this.nextPostTarget.innerHTML = html
          this.loadedValue = true

          // Наблюдаем за новым постом для обновления URL
          const newPost = this.nextPostTarget.querySelector("[data-post-slug]")
          if (newPost) {
            this.postObserver.observe(newPost)
          }

          // Инициализируем вложенные контроллеры
          const nestedController = this.nextPostTarget.querySelector("[data-controller='post-scroll']")
          if (nestedController) {
            // Stimulus автоматически подхватит новый контроллер
          }
        }
      }
    } catch (error) {
      console.error("Post scroll error:", error)
    } finally {
      this.loadingValue = false
      this.hideLoading()
    }
  }

  showLoading() {
    if (this.hasSentinelTarget) {
      const loader = this.sentinelTarget.querySelector(".loading-indicator")
      if (loader) loader.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasSentinelTarget) {
      const loader = this.sentinelTarget.querySelector(".loading-indicator")
      if (loader) loader.classList.add("hidden")
    }
  }
}
