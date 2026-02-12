import { Controller } from "@hotwired/stimulus"

// Подключается к элементу с data-controller="sponsor-banner"
export default class extends Controller {
  static values = {
    bannerId: String
  }

  connect() {
    // Проверяем, был ли баннер закрыт ранее
    const closedBanners = this.getClosedBanners()

    if (closedBanners.includes(this.bannerIdValue)) {
      // Баннер был закрыт, не показываем его
      this.element.remove()
      return
    }

    // Показываем баннер с анимацией
    this.show()
  }

  show() {
    // Добавляем классы для анимации появления
    this.element.classList.remove("opacity-0", "translate-y-4")
    this.element.classList.add("opacity-100", "translate-y-0")
  }

  close(event) {
    event.preventDefault()
    event.stopPropagation()

    // Анимация исчезновения
    this.element.classList.remove("opacity-100", "translate-y-0")
    this.element.classList.add("opacity-0", "translate-y-4")

    // Сохраняем ID закрытого баннера в localStorage
    this.saveClosedBanner()

    // Удаляем элемент после завершения анимации
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  saveClosedBanner() {
    const closedBanners = this.getClosedBanners()

    if (!closedBanners.includes(this.bannerIdValue)) {
      closedBanners.push(this.bannerIdValue)
      localStorage.setItem("closedSponsorBanners", JSON.stringify(closedBanners))
    }
  }

  getClosedBanners() {
    try {
      const stored = localStorage.getItem("closedSponsorBanners")
      return stored ? JSON.parse(stored) : []
    } catch (error) {
      console.error("Ошибка чтения localStorage:", error)
      return []
    }
  }

  // Метод для очистки истории закрытых баннеров (для отладки)
  static clearHistory() {
    localStorage.removeItem("closedSponsorBanners")
  }
}
