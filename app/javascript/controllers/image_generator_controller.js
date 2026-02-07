import { Controller } from "@hotwired/stimulus"

// Контроллер для генерации изображений с помощью AI
// Управляет формой ввода промпта, отправкой запроса и применением результата
export default class extends Controller {
  static targets = [
    "promptInput",      // Textarea для ввода промпта
    "aspectRatio",      // Select для выбора соотношения сторон
    "generateButton",   // Кнопка генерации
    "preview",          // Контейнер превью
    "generatedImage",   // Img для отображения результата
    "applyButton",      // Кнопка применения
    "loading",          // Индикатор загрузки
    "error"             // Блок ошибки
  ]

  static values = {
    projectId: String,     // ID текущего проекта
    generateUrl: { type: String, default: "/api/v1/ai/generate_image" }
  }

  // Outlets для связи с post-editor контроллером
  static outlets = ["post-editor"]

  connect() {
    this.generatedImageData = null
    this.generatedContentType = null
  }

  // Генерация изображения
  async generate(event) {
    event.preventDefault()

    const prompt = this.promptInputTarget.value.trim()
    if (!prompt) {
      this.showError("Введите описание изображения")
      return
    }

    const aspectRatio = this.hasAspectRatioTarget ? this.aspectRatioTarget.value : "1:1"

    // Показываем загрузку
    this.showLoading()
    this.hideError()
    this.hidePreview()

    try {
      const response = await fetch(this.generateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          prompt: prompt,
          aspect_ratio: aspectRatio,
          project_id: this.projectIdValue
        })
      })

      const data = await response.json()

      if (data.success) {
        // Сохраняем данные изображения
        this.generatedImageData = data.image_data
        this.generatedContentType = data.content_type || "image/png"

        // Показываем превью
        this.showPreview(data.image_data, data.content_type)
      } else {
        this.showError(data.error || "Ошибка генерации изображения")

        // Если лимит исчерпан, показываем специальное сообщение
        if (data.limit_reached) {
          this.showError("Лимит AI генераций исчерпан. Обновите тариф для продолжения.")
        }
      }
    } catch (error) {
      console.error("Image generation error:", error)
      this.showError("Произошла ошибка при генерации. Попробуйте ещё раз.")
    } finally {
      this.hideLoading()
    }
  }

  // Применение сгенерированного изображения к посту
  applyImage(event) {
    event.preventDefault()

    if (!this.generatedImageData) {
      this.showError("Сначала сгенерируйте изображение")
      return
    }

    // Вызываем метод в post-editor контроллере через outlet
    if (this.hasPostEditorOutlet) {
      this.postEditorOutlet.applyGeneratedImage(
        this.generatedImageData,
        this.generatedContentType
      )

      // Очищаем форму после успешного применения
      this.reset()
    } else {
      // Fallback: ищем контроллер через DOM
      const postEditor = document.querySelector('[data-controller~="post-editor"]')
      if (postEditor) {
        const controller = this.application.getControllerForElementAndIdentifier(
          postEditor,
          "post-editor"
        )
        if (controller && typeof controller.applyGeneratedImage === "function") {
          controller.applyGeneratedImage(
            this.generatedImageData,
            this.generatedContentType
          )
          this.reset()
        } else {
          this.showError("Не удалось применить изображение")
        }
      }
    }
  }

  // Сброс формы
  reset() {
    this.promptInputTarget.value = ""
    this.generatedImageData = null
    this.generatedContentType = null
    this.hidePreview()
    this.hideError()
  }

  // Показать превью изображения
  showPreview(imageData, contentType) {
    if (this.hasPreviewTarget && this.hasGeneratedImageTarget) {
      const dataUrl = `data:${contentType || 'image/png'};base64,${imageData}`
      this.generatedImageTarget.src = dataUrl
      this.previewTarget.classList.remove("hidden")
    }
  }

  // Скрыть превью
  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
  }

  // Показать индикатор загрузки
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
    if (this.hasGenerateButtonTarget) {
      this.generateButtonTarget.disabled = true
      this.generateButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }

  // Скрыть индикатор загрузки
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
    if (this.hasGenerateButtonTarget) {
      this.generateButtonTarget.disabled = false
      this.generateButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  // Показать ошибку
  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  // Скрыть ошибку
  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  // CSRF токен
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
