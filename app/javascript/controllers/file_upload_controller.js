import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "status"]

  connect() {
    this.dragCounter = 0
  }

  dragover(event) {
    event.preventDefault()
  }

  dragenter(event) {
    event.preventDefault()
    this.dragCounter++
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50", "dark:bg-blue-900/20")
  }

  dragleave(event) {
    event.preventDefault()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50", "dark:bg-blue-900/20")
    }
  }

  drop(event) {
    event.preventDefault()
    this.dragCounter = 0
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50", "dark:bg-blue-900/20")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.handleFile(files[0])
    }
  }

  fileSelected(event) {
    const files = event.target.files
    if (files.length > 0) {
      this.handleFile(files[0])
    }
  }

  handleFile(file) {
    const allowedExtensions = [".txt", ".md", ".markdown"]
    const extension = file.name.substring(file.name.lastIndexOf(".")).toLowerCase()

    if (!allowedExtensions.includes(extension)) {
      this.showError("Разрешены только .txt и .md файлы")
      return
    }

    if (file.size > 1024 * 1024) {
      this.showError("Файл слишком большой (макс. 1 MB)")
      return
    }

    // Создаём DataTransfer для установки файла в input
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    // Отправляем форму
    this.inputTarget.form.requestSubmit()
  }

  showError(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.innerHTML = `
        <div class="p-3 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 rounded-lg">
          <p class="text-sm text-red-600 dark:text-red-400">${message}</p>
        </div>
      `
    }
  }
}
