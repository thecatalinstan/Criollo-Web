import getStats from './stats.js'
import menu from './menu.js'
import login from './login.js'
import notificationCenter from './notifications.js'
import blog from './blog.js'

window.onload = () => {

  // Setup notification center
  const notifier = notificationCenter(document.body)
  window.notifier = notifier

  // Menu
  menu.setup()

  // Login form
  login.setup((user) => {
    notifier.confirm(`Welcome, ${user.firstName}!`, 'You will be redirected in a moment ...', 1000, () => {
      window.location.href = window.redirect.length > 0 ? window.redirect : "/blog"
    })
  }, (err) => {
    notifier.error('Login failed', 'Check your username and password and try again.')
  })

  // Blog
  login.confirm( (data) => {
    window.currentUser = data
    blog.setup()
  }, (err) => {
    window.currentUser = null
  } )

  // Footer info
  getStats(document.getElementById('stats-info'))
}
