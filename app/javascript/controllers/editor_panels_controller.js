import { Controller } from "@hotwired/stimulus"

// Контроллер для управления переключением панелей редактора на мобильных устройствах
// На мобилях (<1024px) показывается только одна панель за раз
// На desktop контроллер не вмешивается - используются CSS классы из HTML
export default class extends Controller {
  static targets = ["chatPanel", "settingsPanel", "previewPanel", "chatTab", "settingsTab", "previewTab"]

  static values = {
    activePanel: { type: String, default: "preview" }
  }

  // Сохраняем исходные классы панелей для восстановления
  originalClasses = new Map()

  connect() {
    // Сохраняем исходные классы панелей
    this.saveOriginalClasses()

    // Применяем мобильный layout только если мобильное устройство
    if (this.isMobile()) {
      this.applyMobileLayout()
    }

    // Отслеживаем изменение размера окна
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
  }

  saveOriginalClasses() {
    if (this.hasChatPanelTarget) {
      this.originalClasses.set("chat", this.chatPanelTarget.className)
    }
    if (this.hasSettingsPanelTarget) {
      this.originalClasses.set("settings", this.settingsPanelTarget.className)
    }
    if (this.hasPreviewPanelTarget) {
      this.originalClasses.set("preview", this.previewPanelTarget.className)
    }
  }

  isMobile() {
    return window.innerWidth < 1024
  }

  handleResize() {
    if (this.isMobile()) {
      this.applyMobileLayout()
    } else {
      this.restoreDesktopLayout()
    }
  }

  showChat(event) {
    event?.preventDefault()
    this.activePanelValue = "chat"
    this.applyMobileLayout()
  }

  showSettings(event) {
    event?.preventDefault()
    this.activePanelValue = "settings"
    this.applyMobileLayout()
  }

  showPreview(event) {
    event?.preventDefault()
    this.activePanelValue = "preview"
    this.applyMobileLayout()
  }

  applyMobileLayout() {
    // Показываем только активную панель на мобилях
    if (this.hasChatPanelTarget) {
      this.toggleMobilePanel(this.chatPanelTarget, this.activePanelValue === "chat")
    }
    if (this.hasSettingsPanelTarget) {
      this.toggleMobilePanel(this.settingsPanelTarget, this.activePanelValue === "settings")
    }
    if (this.hasPreviewPanelTarget) {
      this.toggleMobilePanel(this.previewPanelTarget, this.activePanelValue === "preview")
    }

    this.updateTabs()
  }

  toggleMobilePanel(panel, isActive) {
    if (!panel) return

    // Убираем все lg: классы и desktop-специфичные классы
    panel.classList.remove("lg:flex", "lg:block", "lg:w-[30%]", "lg:w-1/4")

    if (isActive) {
      panel.classList.remove("hidden")
      panel.classList.add("flex", "flex-col", "w-full", "h-full")
    } else {
      panel.classList.add("hidden")
      panel.classList.remove("flex", "flex-col", "w-full", "h-full")
    }
  }

  restoreDesktopLayout() {
    // Восстанавливаем исходные классы из HTML
    if (this.hasChatPanelTarget && this.originalClasses.has("chat")) {
      this.chatPanelTarget.className = this.originalClasses.get("chat")
    }
    if (this.hasSettingsPanelTarget && this.originalClasses.has("settings")) {
      this.settingsPanelTarget.className = this.originalClasses.get("settings")
    }
    if (this.hasPreviewPanelTarget && this.originalClasses.has("preview")) {
      this.previewPanelTarget.className = this.originalClasses.get("preview")
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
        target.classList.add("border-primary-500", "text-primary-600", "dark:text-primary-400")
        target.classList.remove("border-transparent", "text-zinc-500", "dark:text-zinc-400")
      } else {
        target.classList.remove("border-primary-500", "text-primary-600", "dark:text-primary-400")
        target.classList.add("border-transparent", "text-zinc-500", "dark:text-zinc-400")
      }
    })
  }
}
