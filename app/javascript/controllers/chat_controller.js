import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages", "submitButton", "modelSelect"]
  static values = {
    projectId: String,
    aiModel: String
  }

  connect() {
    const postEditorElement = this.element.closest('[data-controller*="post-editor"]') ||
                              document.querySelector('[data-controller*="post-editor"]')
    if (postEditorElement) {
      this.postEditorController = this.application.getControllerForElementAndIdentifier(
        postEditorElement,
        "post-editor"
      )
    }

    // Set initial model from value
    this.currentModel = this.aiModelValue
  }

  changeModel(event) {
    this.currentModel = event.target.value
    console.log('AI Model changed to:', this.currentModel)
  }

  async sendMessage(event) {
    event.preventDefault()
    
    const prompt = this.inputTarget.value.trim()
    if (!prompt) return

    // Disable input
    this.inputTarget.disabled = true
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Генерирую..."

    // Add user message
    this.addMessage(prompt, "user")

    try {
      const response = await fetch('/api/v1/ai/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          prompt: prompt,
          project_id: this.projectIdValue || this.getProjectId(),
          model: this.currentModel
        })
      })

      const data = await response.json()
      console.log('AI API response:', data)

      if (data.success) {
        this.addMessage(data.content, "assistant")

        // Update post editor content
        if (this.postEditorController) {
          if (this.postEditorController.hasContentEditorTarget) {
            this.postEditorController.contentEditorTarget.value = data.content
          }
          if (this.postEditorController.hasContentTarget) {
            this.postEditorController.contentTarget.value = data.content
          }
          // Trigger preview update if method exists
          if (typeof this.postEditorController.updatePreview === 'function') {
            this.postEditorController.updatePreview()
          }
        }
      } else {
        const errorMessage = data.error || 'Неизвестная ошибка'
        console.error('AI generation error:', errorMessage)
        this.addMessage(`Ошибка: ${errorMessage}`, "error")
      }
    } catch (error) {
      console.error('AI request failed:', error)
      this.addMessage(`Ошибка соединения: ${error.message}`, "error")
    } finally {
      // Re-enable input
      this.inputTarget.disabled = false
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Отправить"
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  addMessage(text, type = "assistant") {
    const messageDiv = document.createElement('div')
    messageDiv.className = `rounded-lg p-3 text-sm leading-relaxed ${
      type === "user"
        ? "bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800 text-primary-900 dark:text-primary-100 ml-auto max-w-[80%]"
        : type === "error"
        ? "bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-900 dark:text-red-100"
        : "bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-50"
    }`

    const formattedText = text
      .replace(/\*\*(.+?)\*\*/g, '<strong class="font-semibold text-zinc-900 dark:text-zinc-50">$1</strong>')
      .replace(/\*(.+?)\*/g, '<em class="italic">$1</em>')
      .replace(/`(.+?)`/g, '<code class="bg-white dark:bg-zinc-900 px-1.5 py-0.5 rounded text-xs font-mono text-zinc-900 dark:text-zinc-100">$1</code>')
      .replace(/\n/g, '<br>')

    messageDiv.innerHTML = formattedText
    this.messagesTarget.appendChild(messageDiv)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  getProjectId() {
    const select = document.querySelector('[name="post[project_id]"]')
    return select ? select.value : null
  }
}
