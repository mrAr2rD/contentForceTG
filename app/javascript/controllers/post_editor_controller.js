import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "content", "contentEditor", "preview", "charCount"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    const content = this.contentEditorTarget.value
    const formatted = this.formatContent(content)
    
    this.previewTarget.innerHTML = formatted
    this.charCountTarget.textContent = `${content.length} / 4096`
    
    // Update hidden field
    if (this.hasContentTarget) {
      this.contentTarget.value = content
    }
  }

  formatContent(content) {
    if (!content || content.trim() === '') {
      return '<p class="text-zinc-500 dark:text-zinc-400 italic">Начните писать или используйте AI для генерации...</p>'
    }

    return content
      .replace(/\*\*(.+?)\*\*/g, '<strong class="font-semibold">$1</strong>')
      .replace(/\*(.+?)\*/g, '<em class="italic">$1</em>')
      .replace(/`(.+?)`/g, '<code class="bg-zinc-100 dark:bg-zinc-800 px-1 rounded text-sm text-zinc-900 dark:text-zinc-100">$1</code>')
      .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" class="text-primary-600 dark:text-primary-400 hover:underline">$1</a>')
      .replace(/\n/g, '<br>')
  }

  save(event) {
    event.preventDefault()
    
    if (this.hasFormTarget) {
      // Update content before submit
      if (this.hasContentTarget && this.hasContentEditorTarget) {
        this.contentTarget.value = this.contentEditorTarget.value
      }
      
      this.formTarget.requestSubmit()
    }
  }
}
