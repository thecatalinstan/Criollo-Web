import $ from 'jquery'
import hljs from 'highlight.js'
import notificationCenter from './notifications.js'
import menu from './menu.js'
import stats from './stats.js'
import login from './login.js'

$(document).ready(_ => {
  // Setup notification center
  const defaultNotificationCenter = notificationCenter($(document.body))

  // Code highlighting
  hljs.initHighlighting()

  // Footer info
  stats.getInfo()

  // Menu
  menu.setup()

  // Login form
  login.setup((payload) => {
    defaultNotificationCenter.confirm(`Welcome, ${payload.data['first-name']}!`)
    window.setTimeout(_ => {
      window.location.href = "/api"
    }, 1000)
  }, (err) => {
    defaultNotificationCenter.error('Login failed', 'Check your username and password and try again.')
  })

})
