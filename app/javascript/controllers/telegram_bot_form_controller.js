import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["existingBotSelector", "botSelect", "tokenInput", "usernameInput", "tokenField", "usernameField"]

  toggleBotType(event) {
    const isExisting = event.target.value === "existing"

    if (this.hasExistingBotSelectorTarget) {
      if (isExisting) {
        this.existingBotSelectorTarget.classList.remove("hidden")
        // Make token and username fields readonly when using existing bot
        if (this.hasTokenInputTarget) {
          this.tokenInputTarget.setAttribute("readonly", "readonly")
          this.tokenInputTarget.classList.add("bg-zinc-100", "dark:bg-zinc-800", "cursor-not-allowed")
        }
        if (this.hasUsernameInputTarget) {
          this.usernameInputTarget.setAttribute("readonly", "readonly")
          this.usernameInputTarget.classList.add("bg-zinc-100", "dark:bg-zinc-800", "cursor-not-allowed")
        }
      } else {
        this.existingBotSelectorTarget.classList.add("hidden")
        // Clear selection and make fields editable
        if (this.hasBotSelectTarget) {
          this.botSelectTarget.value = ""
        }
        if (this.hasTokenInputTarget) {
          this.tokenInputTarget.removeAttribute("readonly")
          this.tokenInputTarget.classList.remove("bg-zinc-100", "dark:bg-zinc-800", "cursor-not-allowed")
          this.tokenInputTarget.value = ""
        }
        if (this.hasUsernameInputTarget) {
          this.usernameInputTarget.removeAttribute("readonly")
          this.usernameInputTarget.classList.remove("bg-zinc-100", "dark:bg-zinc-800", "cursor-not-allowed")
          this.usernameInputTarget.value = ""
        }
      }
    }
  }

  selectBot(event) {
    const selectedOption = event.target.selectedOptions[0]

    if (selectedOption && selectedOption.value) {
      const botUsername = selectedOption.value
      const botToken = selectedOption.dataset.token

      // Autofill token and username
      if (this.hasTokenInputTarget) {
        this.tokenInputTarget.value = botToken
      }
      if (this.hasUsernameInputTarget) {
        this.usernameInputTarget.value = botUsername
      }
    } else {
      // Clear fields if "-- Выберите бота --" is selected
      if (this.hasTokenInputTarget) {
        this.tokenInputTarget.value = ""
      }
      if (this.hasUsernameInputTarget) {
        this.usernameInputTarget.value = ""
      }
    }
  }
}
