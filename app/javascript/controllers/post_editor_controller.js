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

    // Process line by line for better paragraph handling
    const lines = content.split('\n')
    const formattedLines = []
    let inQuote = false
    let quoteLines = []

    lines.forEach((line, index) => {
      // Handle quotes (lines starting with >)
      if (line.trim().startsWith('>')) {
        inQuote = true
        quoteLines.push(line.replace(/^>\s*/, ''))
      } else {
        // If we were in a quote and now we're not, close it
        if (inQuote) {
          const quoteContent = this.formatLine(quoteLines.join('<br>'))
          formattedLines.push(
            `<div class="border-l-4 border-blue-500 bg-blue-50 dark:bg-blue-950/20 pl-3 py-2 my-2 rounded-r">${quoteContent}</div>`
          )
          inQuote = false
          quoteLines = []
        }

        // Empty line creates paragraph spacing
        if (line.trim() === '') {
          formattedLines.push('<div class="h-2"></div>')
        } else {
          // Regular line with inline formatting
          const formattedLine = this.formatLine(line)

          // Check if line is a header (starts with emoji and bold text)
          if (/^[\p{Emoji}]/u.test(line) && line.includes('**')) {
            formattedLines.push(`<p class="font-bold text-base mb-1">${formattedLine}</p>`)
          } else {
            formattedLines.push(`<p>${formattedLine}</p>`)
          }
        }
      }
    })

    // Close any remaining quote
    if (inQuote) {
      const quoteContent = this.formatLine(quoteLines.join('<br>'))
      formattedLines.push(
        `<div class="border-l-4 border-blue-500 bg-blue-50 dark:bg-blue-950/20 pl-3 py-2 my-2 rounded-r">${quoteContent}</div>`
      )
    }

    return formattedLines.join('')
  }

  formatLine(line) {
    return line
      // Bold text **text**
      .replace(/\*\*(.+?)\*\*/g, '<strong class="font-semibold text-zinc-900 dark:text-zinc-50">$1</strong>')
      // Italic text *text*
      .replace(/(?<!\*)\*([^\*]+?)\*(?!\*)/g, '<em class="italic">$1</em>')
      // Inline code `code`
      .replace(/`(.+?)`/g, '<code class="bg-zinc-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded text-[13px] font-mono text-zinc-900 dark:text-zinc-100">$1</code>')
      // Links [text](url)
      .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" class="text-blue-600 dark:text-blue-400 hover:underline font-medium">$1</a>')
      // Preserve emoji (they should already be in the text)
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
