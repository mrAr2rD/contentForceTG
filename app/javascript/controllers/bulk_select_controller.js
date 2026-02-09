import { Controller } from "@hotwired/stimulus"

// Контроллер для массового выбора и действий над постами
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "actionBar", "selectedCount", "form"]
  static values = {
    url: String
  }

  connect() {
    this.updateUI()
  }

  // Выбрать/снять выбор со всех
  toggleAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateUI()
  }

  // Обработка изменения отдельного checkbox
  toggle() {
    this.updateUI()
  }

  // Обновить UI (показать/скрыть action bar, обновить счётчик)
  updateUI() {
    const selected = this.selectedIds
    const count = selected.length
    const total = this.checkboxTargets.length

    // Обновить состояние "Выбрать все"
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = count === total && total > 0
      this.selectAllTarget.indeterminate = count > 0 && count < total
    }

    // Показать/скрыть action bar
    if (this.hasActionBarTarget) {
      if (count > 0) {
        this.actionBarTarget.classList.remove("hidden", "translate-y-full", "opacity-0")
        this.actionBarTarget.classList.add("translate-y-0", "opacity-100")
      } else {
        this.actionBarTarget.classList.add("hidden", "translate-y-full", "opacity-0")
        this.actionBarTarget.classList.remove("translate-y-0", "opacity-100")
      }
    }

    // Обновить счётчик
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = count
    }
  }

  // Получить массив выбранных ID
  get selectedIds() {
    return this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)
  }

  // Выполнить действие над выбранными постами
  async performAction(event) {
    event.preventDefault()

    const action = event.currentTarget.dataset.action.split("#")[0] === "bulk-select"
      ? event.params.type
      : event.currentTarget.dataset.bulkSelectTypeParam

    const ids = this.selectedIds

    if (ids.length === 0) return

    const formData = new FormData()
    ids.forEach(id => formData.append("ids[]", id))
    formData.append("action_type", action)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        // Turbo Stream обработает ответ автоматически
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // Сбросить выбор
        this.checkboxTargets.forEach(checkbox => checkbox.checked = false)
        if (this.hasSelectAllTarget) {
          this.selectAllTarget.checked = false
        }
        this.updateUI()
      } else {
        console.error("Bulk action failed:", response.status)
      }
    } catch (error) {
      console.error("Bulk action error:", error)
    }
  }

  // Действие "Показать"
  show(event) {
    event.params = { type: "show" }
    this.performAction(event)
  }

  // Действие "Скрыть"
  hide(event) {
    event.params = { type: "hide" }
    this.performAction(event)
  }

  // Действие "В избранное"
  feature(event) {
    event.params = { type: "feature" }
    this.performAction(event)
  }

  // Действие "Убрать из избранного"
  unfeature(event) {
    event.params = { type: "unfeature" }
    this.performAction(event)
  }
}
