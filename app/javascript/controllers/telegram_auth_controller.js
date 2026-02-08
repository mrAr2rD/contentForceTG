import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["phone", "submit"]

  connect() {
    this.formatPhoneNumber()
  }

  formatPhoneNumber() {
    if (this.hasPhoneTarget) {
      this.phoneTarget.addEventListener("input", (e) => {
        let value = e.target.value.replace(/[^\d+]/g, "")

        // Добавляем + в начало если его нет
        if (value.length > 0 && !value.startsWith("+")) {
          value = "+" + value
        }

        e.target.value = value
      })
    }
  }
}
