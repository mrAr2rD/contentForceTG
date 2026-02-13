import { Controller } from "@hotwired/stimulus"

// Контроллер для графиков аналитики аудитории
export default class extends Controller {
  static values = {
    referralSources: Array,
    ageRanges: Array,
    occupations: Array,
    companySizes: Array,
    registrations: Array
  }

  static targets = [
    "referralChart",
    "ageChart",
    "occupationsChart",
    "companySizesChart",
    "registrationsChart"
  ]

  connect() {
    this.loadChartJs().then(() => {
      this.initCharts()
    })
  }

  disconnect() {
    // Уничтожаем графики при отключении
    if (this.charts) {
      this.charts.forEach(chart => chart.destroy())
    }
  }

  async loadChartJs() {
    if (window.Chart) return

    return new Promise((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js'
      script.onload = resolve
      document.head.appendChild(script)
    })
  }

  initCharts() {
    const isDarkMode = document.documentElement.classList.contains('dark')
    const textColor = isDarkMode ? '#A1A1AA' : '#71717A'
    const gridColor = isDarkMode ? '#27272A' : '#E4E4E7'

    const colors = [
      '#00D4AA', '#00A896', '#028090', '#05668D', '#02C39A',
      '#F0B429', '#F76C5E', '#A855F7', '#3B82F6', '#EF4444'
    ]

    this.charts = []

    // Referral Sources (Doughnut)
    if (this.hasReferralChartTarget && this.referralSourcesValue.length > 0) {
      const hasData = this.referralSourcesValue.some(i => i.count > 0)
      if (hasData) {
        this.charts.push(new Chart(this.referralChartTarget, {
          type: 'doughnut',
          data: {
            labels: this.referralSourcesValue.map(i => i.label),
            datasets: [{
              data: this.referralSourcesValue.map(i => i.count),
              backgroundColor: colors,
              borderWidth: 0
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: {
                position: 'right',
                labels: { color: textColor, boxWidth: 12, padding: 10 }
              }
            }
          }
        }))
      }
    }

    // Age Ranges (Doughnut)
    if (this.hasAgeChartTarget && this.ageRangesValue.length > 0) {
      const hasData = this.ageRangesValue.some(i => i.count > 0)
      if (hasData) {
        this.charts.push(new Chart(this.ageChartTarget, {
          type: 'doughnut',
          data: {
            labels: this.ageRangesValue.map(i => i.label),
            datasets: [{
              data: this.ageRangesValue.map(i => i.count),
              backgroundColor: colors,
              borderWidth: 0
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: {
                position: 'right',
                labels: { color: textColor, boxWidth: 12, padding: 10 }
              }
            }
          }
        }))
      }
    }

    // Occupations (Horizontal Bar)
    if (this.hasOccupationsChartTarget && this.occupationsValue.length > 0) {
      const hasData = this.occupationsValue.some(i => i.count > 0)
      if (hasData) {
        this.charts.push(new Chart(this.occupationsChartTarget, {
          type: 'bar',
          data: {
            labels: this.occupationsValue.map(i => i.label),
            datasets: [{
              data: this.occupationsValue.map(i => i.count),
              backgroundColor: '#00D4AA',
              borderRadius: 4
            }]
          },
          options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false }
            },
            scales: {
              x: {
                grid: { color: gridColor },
                ticks: { color: textColor }
              },
              y: {
                grid: { display: false },
                ticks: { color: textColor }
              }
            }
          }
        }))
      }
    }

    // Company Sizes (Bar)
    if (this.hasCompanySizesChartTarget && this.companySizesValue.length > 0) {
      const hasData = this.companySizesValue.some(i => i.count > 0)
      if (hasData) {
        this.charts.push(new Chart(this.companySizesChartTarget, {
          type: 'bar',
          data: {
            labels: this.companySizesValue.map(i => i.label),
            datasets: [{
              data: this.companySizesValue.map(i => i.count),
              backgroundColor: '#00A896',
              borderRadius: 4
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false }
            },
            scales: {
              x: {
                grid: { display: false },
                ticks: { color: textColor }
              },
              y: {
                grid: { color: gridColor },
                ticks: { color: textColor }
              }
            }
          }
        }))
      }
    }

    // Registrations by day (Line)
    if (this.hasRegistrationsChartTarget && this.registrationsValue.length > 0) {
      this.charts.push(new Chart(this.registrationsChartTarget, {
        type: 'line',
        data: {
          labels: this.registrationsValue.map(i => i.date),
          datasets: [{
            label: 'Регистрации',
            data: this.registrationsValue.map(i => i.count),
            borderColor: '#00D4AA',
            backgroundColor: 'rgba(0, 212, 170, 0.1)',
            fill: true,
            tension: 0.4,
            pointRadius: 3,
            pointBackgroundColor: '#00D4AA'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            x: {
              grid: { color: gridColor },
              ticks: { color: textColor, maxRotation: 45 }
            },
            y: {
              grid: { color: gridColor },
              ticks: { color: textColor, stepSize: 1 },
              beginAtZero: true
            }
          }
        }
      }))
    }
  }
}
