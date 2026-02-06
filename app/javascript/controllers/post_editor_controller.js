import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "content", "contentEditor", "preview", "charCount",
    "titlePreview", "imagePreview", "imagePreviewImg",
    "postType", "imageField", "buttonFields",
    "buttonPreview", "buttonTextPreview", "channelName", "botSelect"
  ]

  static values = {
    bots: Array,
    postId: String,
    removeImageUrl: String
  }

  connect() {
    this.updatePreview()
    this.toggleButtonFields()
    this.updateChannelName()
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

    // Update character count with better formatting and warnings
    this.updateCharCount(content.length)

    // Update hidden field
    if (this.hasContentTarget) {
      this.contentTarget.value = content
    }
  }

  updateCharCount(length) {
    // Telegram limits: 4096 for text messages, 1024 for photo captions
    const hasImage = this.hasImagePreviewTarget && !this.imagePreviewTarget.classList.contains('hidden')
    const limit = hasImage ? 1024 : 4096
    const limitType = hasImage ? 'подпись' : 'текст'

    // Calculate percentage
    const percentage = (length / limit) * 100

    // Update text
    this.charCountTarget.textContent = `${length} / ${limit} символов (${limitType})`

    // Update color based on usage
    this.charCountTarget.classList.remove('text-zinc-500', 'dark:text-zinc-400', 'text-yellow-600', 'dark:text-yellow-400', 'text-red-600', 'dark:text-red-400')

    if (length > limit) {
      // Over limit - red
      this.charCountTarget.classList.add('text-red-600', 'dark:text-red-400')
    } else if (percentage >= 90) {
      // 90-100% - yellow warning
      this.charCountTarget.classList.add('text-yellow-600', 'dark:text-yellow-400')
    } else {
      // Under 90% - normal
      this.charCountTarget.classList.add('text-zinc-500', 'dark:text-zinc-400')
    }
  }

  updateChannelName() {
    if (!this.hasChannelNameTarget || !this.hasBotSelectTarget) return

    const selectedBotId = this.botSelectTarget.value

    if (!selectedBotId) {
      this.channelNameTarget.textContent = "Выберите бота"
      return
    }

    // Find bot in the bots array
    const bot = this.botsValue.find(b => b.id === selectedBotId)

    if (bot && bot.channel_name) {
      this.channelNameTarget.textContent = bot.channel_name
    } else {
      this.channelNameTarget.textContent = "Канал бота"
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

    lines.forEach((line) => {
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

  // Toggle visibility of image and button fields based on post type
  toggleButtonFields() {
    if (!this.hasPostTypeTarget) return

    const postType = this.postTypeTarget.value

    // Show/hide image field
    if (this.hasImageFieldTarget) {
      if (postType === 'text') {
        this.imageFieldTarget.classList.add('hidden')
      } else {
        this.imageFieldTarget.classList.remove('hidden')
      }
    }

    // Show/hide button fields
    if (this.hasButtonFieldsTarget) {
      if (postType === 'image_button') {
        this.buttonFieldsTarget.classList.remove('hidden')
      } else {
        this.buttonFieldsTarget.classList.add('hidden')
      }
    }

    // Update button preview visibility
    if (this.hasButtonPreviewTarget) {
      if (postType === 'image_button') {
        this.buttonPreviewTarget.classList.remove('hidden')
      } else {
        this.buttonPreviewTarget.classList.add('hidden')
      }
    }
  }

  // Update button text in preview
  updateButtonText(event) {
    if (this.hasButtonTextPreviewTarget) {
      const text = event.target.value || 'Кнопка'
      this.buttonTextPreviewTarget.textContent = text
    }
  }

  // Update button URL in preview
  updateButtonUrl(event) {
    const buttonLink = this.element.querySelector('[data-post-editor-target="buttonPreview"] a')
    if (buttonLink) {
      buttonLink.href = event.target.value || '#'
    }
  }

  // Preview uploaded image with validation
  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    // Валидация размера файла (максимум 10MB)
    const maxSize = 10 * 1024 * 1024
    if (file.size > maxSize) {
      alert(`Файл слишком большой: ${(file.size / 1024 / 1024).toFixed(2)}MB (максимум: 10MB)`)
      event.target.value = ''
      return
    }

    // Валидация типа файла
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
    if (!allowedTypes.includes(file.type)) {
      alert(`Неподдерживаемый формат: ${file.type}. Допускаются только JPEG, PNG, WebP, GIF`)
      event.target.value = ''
      return
    }

    // Показываем превью
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasImagePreviewTarget) {
        let img = this.imagePreviewTarget.querySelector('img')
        if (!img && this.hasImagePreviewImgTarget) {
          img = this.imagePreviewImgTarget
        }

        if (img) {
          img.src = e.target.result
          this.imagePreviewTarget.classList.remove('hidden')
          this.updateCharCount(this.contentEditorTarget.value.length)
        }
      }
    }
    reader.readAsDataURL(file)
  }

  // Remove image
  async removeImage(event) {
    event.preventDefault()

    // Если пост сохранён и есть URL для удаления - вызываем сервер
    if (this.hasRemoveImageUrlValue && this.removeImageUrlValue) {
      try {
        const response = await fetch(this.removeImageUrlValue, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
            'Accept': 'application/json'
          }
        })

        if (!response.ok) {
          console.error('Failed to remove image on server')
        }
      } catch (error) {
        console.error('Error removing image:', error)
      }
    }

    // Обновляем UI
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.classList.add('hidden')
      this.updateCharCount(this.contentEditorTarget.value.length)
    }

    // Очищаем file input
    const fileInput = this.element.querySelector('input[type="file"]')
    if (fileInput) {
      fileInput.value = ''
    }

    // Переключаем тип поста на текстовый
    if (this.hasPostTypeTarget && this.postTypeTarget.value !== 'text') {
      this.postTypeTarget.value = 'text'
      this.toggleButtonFields()
    }
  }

  // Trigger image upload from quick action button
  triggerImageUpload() {
    const fileInput = this.element.querySelector('input[type="file"][accept="image/*"]')
    if (fileInput) {
      // Also change post type to 'image' if it's currently 'text'
      if (this.hasPostTypeTarget && this.postTypeTarget.value === 'text') {
        this.postTypeTarget.value = 'image'
        this.toggleButtonFields()
      }
      fileInput.click()
    }
  }

  // Add emoji to content
  addEmoji() {
    const commonEmojis = ['😊', '👍', '🔥', '❤️', '✨', '🎉', '💡', '⚡', '🚀', '💪']
    const emoji = commonEmojis[Math.floor(Math.random() * commonEmojis.length)]
    this.insertAtCursor(emoji + ' ')
  }

  // Add hashtags
  addHashtags() {
    const currentContent = this.contentEditorTarget.value
    const hashtags = '\n\n#тег1 #тег2 #тег3'
    this.contentEditorTarget.value = currentContent + hashtags
    this.contentEditorTarget.focus()
    this.updatePreview()
  }

  // Helper to insert text at cursor position
  insertAtCursor(text) {
    const textarea = this.contentEditorTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const content = textarea.value

    textarea.value = content.substring(0, start) + text + content.substring(end)
    textarea.selectionStart = textarea.selectionEnd = start + text.length
    textarea.focus()
    this.updatePreview()
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
