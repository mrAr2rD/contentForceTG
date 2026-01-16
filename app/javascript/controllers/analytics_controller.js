import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Wait for Chart.js to load
    if (typeof Chart === 'undefined') {
      setTimeout(() => this.initializeCharts(), 100)
    } else {
      this.initializeCharts()
    }
  }

  initializeCharts() {
    this.initializeViewsChart()
    this.initializeSubscribersChart()
    this.initializeEngagementChart()
  }

  initializeViewsChart() {
    const canvas = document.getElementById('viewsChart')
    if (!canvas) return

    const data = JSON.parse(canvas.dataset.chartData || '[]')
    if (data.length === 0) return

    const ctx = canvas.getContext('2d')
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.map(d => d.date),
        datasets: [{
          label: 'Просмотры',
          data: data.map(d => d.views),
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            padding: 12,
            cornerRadius: 8
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  initializeSubscribersChart() {
    const canvas = document.getElementById('subscribersChart')
    if (!canvas) return

    const data = JSON.parse(canvas.dataset.chartData || '[]')
    if (data.length === 0) return

    const ctx = canvas.getContext('2d')
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.map(d => d.date),
        datasets: [{
          label: 'Подписчики',
          data: data.map(d => d.subscribers),
          borderColor: 'rgb(34, 197, 94)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            padding: 12,
            cornerRadius: 8
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  initializeEngagementChart() {
    const canvas = document.getElementById('engagementChart')
    if (!canvas) return

    const data = JSON.parse(canvas.dataset.chartData || '[]')
    if (data.length === 0) return

    const ctx = canvas.getContext('2d')
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.map(d => d.date),
        datasets: [{
          label: 'Вовлеченность (%)',
          data: data.map(d => d.rate),
          backgroundColor: 'rgba(249, 115, 22, 0.6)',
          borderColor: 'rgb(249, 115, 22)',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            padding: 12,
            cornerRadius: 8,
            callbacks: {
              label: function(context) {
                return `Вовлеченность: ${context.parsed.y.toFixed(2)}%`
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: function(value) {
                return value + '%'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }
}
