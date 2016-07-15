import getStats from './stats.js'
import menu from './menu.js'
import login from './login.js'
import notificationCenter from './notifications.js'
import blog from './blog.js'

window.onload = () => {

  // Setup notification center
  const defaultNotificationCenter = notificationCenter(document.body)

  // Menu
  menu.setup()

  // Login form
  login.setup((user) => {
    defaultNotificationCenter.confirm(`Welcome, ${user['first-name']}!`, 'You will be redirected in a moment ...', 1000, () => {
      window.location.href = "/blog"
    })
  }, (err) => {
    defaultNotificationCenter.error('Login failed', 'Check your username and password and try again.')
  })

  // Blog
  login.confirm( (data) => {
    window.currentUser = data
    blog.setup()
  }, (err) => {
    window.currentUser = null
    console.error(err)
  } )

  // Footer info
  // getStats(document.getElementById('stats-info'))
}
