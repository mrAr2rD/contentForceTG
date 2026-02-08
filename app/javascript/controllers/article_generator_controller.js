import { Controller } from "@hotwired/stimulus"

// Контроллер для AI-генерации контента статей в админке
export default class extends Controller {
  static targets = ["topic", "style", "content", "generateButton", "buttonText", "error"]

  connect() {
    this.generating = false
  }

  async generate() {
    if (this.generating) return

    const topic = this.topicTarget.value.trim()
    if (!topic) {
      this.showError("Введите тему статьи")
      return
    }

    const style = this.styleTarget.value
    this.generating = true
    this.hideError()
    this.setLoading(true)

    try {
      const response = await fetch(this.generateUrl(), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ topic, style })
      })

      const data = await response.json()

      if (data.success) {
        this.contentTarget.value = data.content
        // Trigger input event for any listeners
        this.contentTarget.dispatchEvent(new Event("input", { bubbles: true }))
      } else {
        this.showError(data.error || "Ошибка генерации")
      }
    } catch (error) {
      console.error("Generation error:", error)
      this.showError("Ошибка сети. Попробуйте еще раз.")
    } finally {
      this.generating = false
      this.setLoading(false)
    }
  }

  generateUrl() {
    // Используем collection route для генерации
    return "/admin/articles/generate_content"
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }

  setLoading(loading) {
    if (loading) {
      this.generateButtonTarget.disabled = true
      this.generateButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.buttonTextTarget.textContent = "Генерация..."
    } else {
      this.generateButtonTarget.disabled = false
      this.generateButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.buttonTextTarget.textContent = "Сгенерировать с AI"
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
