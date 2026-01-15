import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages", "submitButton"]

  connect() {
    const postEditorElement = this.element.closest('[data-controller*="post-editor"]') || 
                              document.querySelector('[data-controller*="post-editor"]')
    if (postEditorElement) {
      this.postEditorController = this.application.getControllerForElementAndIdentifier(
        postEditorElement,
        "post-editor"
      )
    }
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
          project_id: this.getProjectId()
        })
      })

      const data = await response.json()

      if (data.success) {
        this.addMessage(data.content, "assistant")
        
        // Update post editor content
        if (this.postEditorController && this.postEditorController.hasContentEditorTarget) {
          this.postEditorController.contentEditorTarget.value = data.content
          this.postEditorController.updatePreview()
        }
      } else {
        this.addMessage(`Ошибка: ${data.error}`, "error")
      }
    } catch (error) {
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
    messageDiv.className = `rounded-lg p-3 text-sm ${
      type === "user" 
        ? "bg-blue-50 text-blue-900 ml-auto max-w-[80%]" 
        : type === "error"
        ? "bg-red-50 text-red-900"
        : "bg-violet-50 text-slate-700"
    }`
    
    const formattedText = text
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/`(.+?)`/g, '<code class="bg-white px-1 rounded">$1</code>')
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
