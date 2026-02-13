import { Controller } from "@hotwired/stimulus"

// Подключается к элементу с data-controller="sponsor-banner"
// Логика показа:
// - Публичные страницы: sessionStorage (показывается при новом визите)
// - Dashboard: localStorage с таймером 30 минут
export default class extends Controller {
  static values = {
    bannerId: String,
    context: { type: String, default: "public" } // "public" или "dashboard"
  }

  // Время в миллисекундах, через которое баннер снова покажется в dashboard
  static RESHOW_DELAY = 30 * 60 * 1000 // 30 минут

  connect() {
    if (this.shouldHideBanner()) {
      this.element.remove()
      return
    }

    // Показываем баннер с анимацией
    this.show()
  }

  shouldHideBanner() {
    const isDashboard = this.contextValue === "dashboard"

    if (isDashboard) {
      // Dashboard: проверяем localStorage с таймером
      return this.isClosedRecently()
    } else {
      // Публичные страницы: проверяем sessionStorage
      return this.isClosedThisSession()
    }
  }

  // Проверка для dashboard — закрыт менее 30 минут назад
  isClosedRecently() {
    try {
      const stored = localStorage.getItem("sponsorBannerClosedAt")
      if (!stored) return false

      const closedData = JSON.parse(stored)
      const closedAt = closedData[this.bannerIdValue]

      if (!closedAt) return false

      const elapsed = Date.now() - closedAt
      return elapsed < this.constructor.RESHOW_DELAY
    } catch (error) {
      console.error("Ошибка чтения localStorage:", error)
      return false
    }
  }

  // Проверка для публичных страниц — закрыт в этой сессии
  isClosedThisSession() {
    try {
      const stored = sessionStorage.getItem("closedSponsorBanners")
      const closedBanners = stored ? JSON.parse(stored) : []
      return closedBanners.includes(this.bannerIdValue)
    } catch (error) {
      console.error("Ошибка чтения sessionStorage:", error)
      return false
    }
  }

  show() {
    this.element.classList.remove("opacity-0", "translate-y-4")
    this.element.classList.add("opacity-100", "translate-y-0")
  }

  close(event) {
    event.preventDefault()
    event.stopPropagation()

    // Анимация исчезновения
    this.element.classList.remove("opacity-100", "translate-y-0")
    this.element.classList.add("opacity-0", "translate-y-4")

    // Сохраняем информацию о закрытии
    this.saveClosedBanner()

    // Удаляем элемент после завершения анимации
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  saveClosedBanner() {
    const isDashboard = this.contextValue === "dashboard"

    if (isDashboard) {
      // Dashboard: сохраняем timestamp в localStorage
      this.saveWithTimestamp()
    } else {
      // Публичные страницы: сохраняем в sessionStorage
      this.saveToSession()
    }
  }

  saveWithTimestamp() {
    try {
      const stored = localStorage.getItem("sponsorBannerClosedAt")
      const closedData = stored ? JSON.parse(stored) : {}
      closedData[this.bannerIdValue] = Date.now()
      localStorage.setItem("sponsorBannerClosedAt", JSON.stringify(closedData))
    } catch (error) {
      console.error("Ошибка записи в localStorage:", error)
    }
  }

  saveToSession() {
    try {
      const stored = sessionStorage.getItem("closedSponsorBanners")
      const closedBanners = stored ? JSON.parse(stored) : []

      if (!closedBanners.includes(this.bannerIdValue)) {
        closedBanners.push(this.bannerIdValue)
        sessionStorage.setItem("closedSponsorBanners", JSON.stringify(closedBanners))
      }
    } catch (error) {
      console.error("Ошибка записи в sessionStorage:", error)
    }
  }

  // Метод для очистки истории (для отладки)
  static clearHistory() {
    localStorage.removeItem("sponsorBannerClosedAt")
    sessionStorage.removeItem("closedSponsorBanners")
  }
}
