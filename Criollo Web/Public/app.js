import getStats from './stats.js'
import menu from './menu.js'

// import notificationCenter from './notifications.js'
// import login from './login.js'

window.onload = () => {
  // Footer info
  getStats(document.getElementById('stats-info'))

  // Menu
  menu.setup()

  // Setup notification center
  // const defaultNotificationCenter = notificationCenter($(document.body))

  // Login form
  // login.setup((payload) => {
  //   defaultNotificationCenter.confirm(`Welcome, ${payload.data['first-name']}!`)
  //   window.setTimeout(_ => {
  //     window.location.href = "/api"
  //   }, 1000)
  // }, (err) => {
  //   defaultNotificationCenter.error('Login failed', 'Check your username and password and try again.')
  // })

}
