import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "content", "contentEditor", "preview", "charCount", "titlePreview", "imagePreview"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    const content = this.contentEditorTarget.value

    // Extract title from first line if it starts with # or is in bold
    const lines = content.split('\n')
    let title = ''
    let bodyContent = content

    if (lines[0] && (lines[0].startsWith('#') || lines[0].startsWith('**'))) {
      title = lines[0].replace(/^#\s+/, '').replace(/^\*\*/, '').replace(/\*\*$/, '').trim()
      bodyContent = lines.slice(1).join('\n').trim()
    }

    // Update title preview
    if (this.hasTitlePreviewTarget) {
      if (title) {
        this.titlePreviewTarget.textContent = title
        this.titlePreviewTarget.classList.remove('hidden')
      } else {
        this.titlePreviewTarget.classList.add('hidden')
      }
    }

    // Format and update body content
    const formatted = this.formatContent(bodyContent)
    this.previewTarget.innerHTML = formatted
    this.charCountTarget.textContent = `${content.length} / 4096`

    // Update hidden field
    if (this.hasContentTarget) {
      this.contentTarget.value = content
    }
  }

  formatContent(content) {
    if (!content || content.trim() === '') {
      return '<p class="text-zinc-400 dark:text-zinc-500 italic">Начните писать или используйте AI для генерации...</p>'
    }

    return content
      .replace(/\*\*(.+?)\*\*/g, '<strong class="font-semibold">$1</strong>')
      .replace(/\*(.+?)\*/g, '<em class="italic">$1</em>')
      .replace(/`(.+?)`/g, '<code class="bg-zinc-200 dark:bg-zinc-700 px-1.5 py-0.5 rounded text-xs text-zinc-900 dark:text-zinc-100">$1</code>')
      .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" class="text-blue-600 dark:text-blue-400 hover:underline">$1</a>')
      .replace(/\n/g, '<br>')
  }

  handleImageUpload(event) {
    const file = event.target.files[0]
    if (file && this.hasImagePreviewTarget) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = this.imagePreviewTarget.querySelector('img')
        if (img) {
          img.src = e.target.result
          this.imagePreviewTarget.classList.remove('hidden')
        }
      }
      reader.readAsDataURL(file)
    }
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
