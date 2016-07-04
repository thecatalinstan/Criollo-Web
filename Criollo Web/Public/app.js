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
    defaultNotificationCenter.confirm(`Welcome, ${user['first-name']}!`, 'You will be redirected in a moment ...', 1000, () => {
      window.location.href = "/api"
    })
  }, (err) => {
    defaultNotificationCenter.error('Login failed', 'Check your username and password and try again.')
  })

}
