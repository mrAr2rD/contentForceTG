import { Controller } from "@hotwired/stimulus"

// Контроллер для плавной анимации переходов в онбординге
export default class extends Controller {
  connect() {
    // Добавляем класс для fade-in анимации при подключении
    this.element.classList.add('fade-in')
  }

  // Можно использовать для дополнительных анимаций при выборе опции
  selectOption(event) {
    const button = event.currentTarget

    // Убираем selected со всех кнопок
    this.element.querySelectorAll('.onboarding-option').forEach(opt => {
      opt.classList.remove('selected')
    })

    // Добавляем selected на выбранную
    button.classList.add('selected')

    // Небольшая задержка перед отправкой формы для визуального feedback
    setTimeout(() => {
      button.closest('form').requestSubmit()
    }, 150)
  }
}
