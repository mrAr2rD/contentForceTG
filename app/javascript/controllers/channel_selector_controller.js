import { Controller } from "@hotwired/stimulus"

// Контроллер для переключения между select и custom input
export default class extends Controller {
  static targets = ["select", "customInput"]

  connect() {
    this.toggleCustomInput()
  }

  toggleCustomInput() {
    const value = this.selectTarget.value

    if (value === "custom") {
      this.customInputTarget.classList.remove("hidden")
    } else {
      this.customInputTarget.classList.add("hidden")
    }
  }
}
