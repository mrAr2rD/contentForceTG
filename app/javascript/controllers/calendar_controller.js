import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthView", "listView", "calendarGrid", "monthLabel", "listContainer"]
  static values = {
    events: Array
  }

  connect() {
    this.currentDate = new Date()
    this.currentView = "month"
    this.renderCalendar()
  }

  // Switch between month and list views
  switchView(event) {
    const view = event.currentTarget.dataset.view
    this.currentView = view

    // Update button states
    event.currentTarget.parentElement.querySelectorAll("button").forEach(btn => {
      if (btn.dataset.view === view) {
        btn.classList.add("bg-primary", "text-primary-foreground")
        btn.classList.remove("text-muted-foreground", "hover:text-foreground")
      } else {
        btn.classList.remove("bg-primary", "text-primary-foreground")
        btn.classList.add("text-muted-foreground", "hover:text-foreground")
      }
    })

    // Show/hide views
    if (view === "month") {
      this.monthViewTarget.classList.remove("hidden")
      this.listViewTarget.classList.add("hidden")
      this.renderCalendar()
    } else {
      this.monthViewTarget.classList.add("hidden")
      this.listViewTarget.classList.remove("hidden")
      this.renderList()
    }
  }

  // Filter by project
  filterProject(event) {
    const projectId = event.target.value
    const url = projectId ? `/calendar?project_id=${projectId}` : '/calendar'
    window.location.href = url
  }

  // Navigate months
  previousMonth() {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1)
    this.renderCalendar()
  }

  nextMonth() {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1)
    this.renderCalendar()
  }

  goToToday() {
    this.currentDate = new Date()
    this.renderCalendar()
  }

  // Render calendar grid
  renderCalendar() {
    const year = this.currentDate.getFullYear()
    const month = this.currentDate.getMonth()

    // Update month label
    const monthNames = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                       "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    this.monthLabelTarget.textContent = `${monthNames[month]} ${year}`

    // Get first day of month and total days
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const totalDays = lastDay.getDate()

    // Adjust for Monday as first day (0 = Monday, 6 = Sunday)
    let startDay = firstDay.getDay() - 1
    if (startDay === -1) startDay = 6

    // Clear grid
    this.calendarGridTarget.innerHTML = ''

    // Add empty cells for days before month starts
    for (let i = 0; i < startDay; i++) {
      this.calendarGridTarget.appendChild(this.createEmptyDay())
    }

    // Add days of the month
    for (let day = 1; day <= totalDays; day++) {
      const date = new Date(year, month, day)
      this.calendarGridTarget.appendChild(this.createDay(date))
    }
  }

  createEmptyDay() {
    const div = document.createElement('div')
    div.className = 'min-h-24 bg-muted/20 rounded-lg'
    return div
  }

  createDay(date) {
    const div = document.createElement('div')
    const isToday = this.isToday(date)
    const dateString = this.formatDate(date)

    // Get events for this day
    const dayEvents = this.eventsValue.filter(event => {
      const eventDate = new Date(event.start)
      return eventDate.toDateString() === date.toDateString()
    })

    div.className = `min-h-24 p-2 rounded-lg border transition-all cursor-pointer ${
      isToday
        ? 'border-primary bg-primary/5'
        : 'border-border bg-card hover:border-primary/50 hover:shadow-sm'
    }`

    // Day number
    const dayNumber = document.createElement('div')
    dayNumber.className = `text-xs font-medium mb-2 ${
      isToday ? 'text-primary' : 'text-foreground'
    }`
    dayNumber.textContent = date.getDate()
    div.appendChild(dayNumber)

    // Events for this day
    const eventsContainer = document.createElement('div')
    eventsContainer.className = 'space-y-1'

    dayEvents.slice(0, 3).forEach(event => {
      const eventEl = document.createElement('a')
      eventEl.href = event.url
      eventEl.className = 'block px-2 py-1 rounded text-xs truncate transition-colors'
      eventEl.style.backgroundColor = `${event.color}15`
      eventEl.style.borderLeft = `2px solid ${event.color}`
      eventEl.textContent = event.title
      eventEl.addEventListener('mouseenter', () => {
        eventEl.style.backgroundColor = `${event.color}25`
      })
      eventEl.addEventListener('mouseleave', () => {
        eventEl.style.backgroundColor = `${event.color}15`
      })
      eventsContainer.appendChild(eventEl)
    })

    // Show "+N more" if there are more events
    if (dayEvents.length > 3) {
      const moreEl = document.createElement('div')
      moreEl.className = 'text-xs text-muted-foreground px-2'
      moreEl.textContent = `+${dayEvents.length - 3} еще`
      eventsContainer.appendChild(moreEl)
    }

    div.appendChild(eventsContainer)

    return div
  }

  // Render list view
  renderList() {
    if (!this.hasListContainerTarget) return

    this.listContainerTarget.innerHTML = ''

    // Group events by date
    const eventsByDate = {}
    this.eventsValue.forEach(event => {
      const date = new Date(event.start).toDateString()
      if (!eventsByDate[date]) {
        eventsByDate[date] = []
      }
      eventsByDate[date].push(event)
    })

    // Sort dates
    const sortedDates = Object.keys(eventsByDate).sort((a, b) => {
      return new Date(a) - new Date(b)
    })

    if (sortedDates.length === 0) {
      const emptyState = document.createElement('div')
      emptyState.className = 'p-12 text-center'
      emptyState.innerHTML = `
        <div class="w-16 h-16 bg-muted rounded-full flex items-center justify-center mx-auto mb-3">
          <svg class="w-8 h-8 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
          </svg>
        </div>
        <p class="text-sm text-muted-foreground">Нет постов для отображения</p>
      `
      this.listContainerTarget.appendChild(emptyState)
      return
    }

    // Render each date group
    sortedDates.forEach(dateStr => {
      const events = eventsByDate[dateStr]
      const date = new Date(dateStr)

      // Date header
      const dateHeader = document.createElement('div')
      dateHeader.className = 'px-4 py-3 bg-muted/30 border-b border-border'
      dateHeader.innerHTML = `
        <h3 class="text-sm font-semibold text-foreground">
          ${this.formatDateLong(date)}
        </h3>
      `
      this.listContainerTarget.appendChild(dateHeader)

      // Events for this date
      events.forEach(event => {
        const eventEl = document.createElement('a')
        eventEl.href = event.url
        eventEl.className = 'flex items-center gap-3 p-4 hover:bg-accent transition-colors border-b border-border group'

        const statusColors = {
          published: 'bg-green-500',
          scheduled: 'bg-blue-500',
          draft: 'bg-gray-500',
          failed: 'bg-red-500'
        }

        eventEl.innerHTML = `
          <div class="flex-shrink-0">
            <div class="w-3 h-3 rounded-full ${statusColors[event.status] || 'bg-gray-500'}"></div>
          </div>
          <div class="flex-1 min-w-0">
            <h4 class="text-sm font-medium text-foreground group-hover:text-primary transition-colors">
              ${event.title}
            </h4>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-xs text-muted-foreground">
                ${new Date(event.start).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })}
              </span>
              ${event.telegram_bot ? `
                <span class="text-xs text-muted-foreground">
                  • ${event.telegram_bot}
                </span>
              ` : ''}
            </div>
          </div>
          <div class="flex-shrink-0">
            <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium ${this.getStatusBadgeClass(event.status)}">
              ${this.getStatusText(event.status)}
            </span>
          </div>
        `
        this.listContainerTarget.appendChild(eventEl)
      })
    })
  }

  // Helper methods
  isToday(date) {
    const today = new Date()
    return date.toDateString() === today.toDateString()
  }

  formatDate(date) {
    return date.toISOString().split('T')[0]
  }

  formatDateLong(date) {
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
    return date.toLocaleDateString('ru-RU', options)
  }

  getStatusBadgeClass(status) {
    const classes = {
      published: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      scheduled: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      draft: 'bg-gray-50 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400',
      failed: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    }
    return classes[status] || classes.draft
  }

  getStatusText(status) {
    const texts = {
      published: 'Опубликован',
      scheduled: 'Запланирован',
      draft: 'Черновик',
      failed: 'Ошибка'
    }
    return texts[status] || status
  }
}
