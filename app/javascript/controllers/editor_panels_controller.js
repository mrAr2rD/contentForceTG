import { Controller } from "@hotwired/stimulus"

// Контроллер для управления переключением панелей редактора на мобильных устройствах
// На мобилях (<1024px) показывается только одна панель за раз
// На desktop все панели видны одновременно
export default class extends Controller {
  static targets = ["chatPanel", "settingsPanel", "previewPanel", "chatTab", "settingsTab", "previewTab"]

  static values = {
    activePanel: { type: String, default: "preview" }
  }

  connect() {
    // На мобилях по умолчанию показываем редактор (preview)
    this.updatePanelVisibility()

    // Отслеживаем изменение размера окна
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
  }

  handleResize() {
    // При изменении размера окна обновляем видимость панелей
    this.updatePanelVisibility()
  }

  showChat(event) {
    event?.preventDefault()
    this.activePanelValue = "chat"
    this.updatePanelVisibility()
  }

  showSettings(event) {
    event?.preventDefault()
    this.activePanelValue = "settings"
    this.updatePanelVisibility()
  }

  showPreview(event) {
    event?.preventDefault()
    this.activePanelValue = "preview"
    this.updatePanelVisibility()
  }

  updatePanelVisibility() {
    const isMobile = window.innerWidth < 1024

    if (isMobile) {
      // Мобильный режим: показываем только активную панель
      if (this.hasChatPanelTarget) {
        this.togglePanel(this.chatPanelTarget, this.activePanelValue === "chat")
      }
      if (this.hasSettingsPanelTarget) {
        this.togglePanel(this.settingsPanelTarget, this.activePanelValue === "settings")
      }
      if (this.hasPreviewPanelTarget) {
        this.togglePanel(this.previewPanelTarget, this.activePanelValue === "preview")
      }

      // Обновляем активные табы
      this.updateTabs()
    } else {
      // Desktop режим: показываем все панели согласно их исходным классам
      this.resetDesktopLayout()
    }
  }

  togglePanel(panel, isActive) {
    if (!panel) return

    if (isActive) {
      // Показываем панель на мобилях
      panel.classList.remove("hidden", "lg:hidden", "lg:flex", "lg:block")
      panel.classList.add("flex", "flex-col", "mobile-panel-active")
    } else {
      // Скрываем панель на мобилях
      panel.classList.add("hidden")
      panel.classList.remove("flex", "flex-col", "mobile-panel-active")
    }
  }

  resetDesktopLayout() {
    // AI Chat: hidden на мобилях, flex на desktop
    if (this.hasChatPanelTarget) {
      this.chatPanelTarget.classList.remove("mobile-panel-active", "flex-col")
      this.chatPanelTarget.classList.add("hidden", "lg:flex")
    }

    // Settings: hidden на мобилях, block на desktop
    if (this.hasSettingsPanelTarget) {
      this.settingsPanelTarget.classList.remove("mobile-panel-active", "flex", "flex-col")
      this.settingsPanelTarget.classList.add("hidden", "lg:block")
    }

    // Preview: всегда показан, flex-1
    if (this.hasPreviewPanelTarget) {
      this.previewPanelTarget.classList.remove("mobile-panel-active", "hidden", "flex-col")
    }
  }

  updateTabs() {
    const tabs = [
      { target: this.hasChatTabTarget ? this.chatTabTarget : null, panel: "chat" },
      { target: this.hasSettingsTabTarget ? this.settingsTabTarget : null, panel: "settings" },
      { target: this.hasPreviewTabTarget ? this.previewTabTarget : null, panel: "preview" }
    ]

    tabs.forEach(({ target, panel }) => {
      if (!target) return

      if (this.activePanelValue === panel) {
        // Активный таб
        target.classList.add("border-primary-500", "text-primary-600", "dark:text-primary-400")
        target.classList.remove("border-transparent", "text-zinc-500", "dark:text-zinc-400")
      } else {
        // Неактивный таб
        target.classList.remove("border-primary-500", "text-primary-600", "dark:text-primary-400")
        target.classList.add("border-transparent", "text-zinc-500", "dark:text-zinc-400")
      }
    })
  }
}
