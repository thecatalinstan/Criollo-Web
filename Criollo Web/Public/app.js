import getStats from './stats.js'
import menu from './menu.js'
import login from './login.js'
import notificationCenter from './notifications.js'

window.onload = () => {
  // Footer info
  getStats(document.getElementById('stats-info'))

  // Menu
  menu.setup()

  // Setup notification center
  const defaultNotificationCenter = notificationCenter(document.body)

  // Login form
  login.setup((user) => {
    defaultNotificationCenter.confirm(`Welcome, ${user['first-name']}!`)
    window.setTimeout(_ => {
      window.location.href = "/api"
    }, 1000)
  }, (err) => {
    defaultNotificationCenter.error('Login failed', 'Check your username and password and try again.')
  })

}
