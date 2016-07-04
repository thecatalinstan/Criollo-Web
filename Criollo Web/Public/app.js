import m from 'mithril'
import hljs from 'highlight.js'
import stats from './stats.js'
import menu from './menu.js'
// import notificationCenter from './notifications.js'
// import login from './login.js'

window.m = m
window.onload = () => {
  // Code highlighting
  hljs.initHighlighting()

  // Setup notification center
  // const defaultNotificationCenter = notificationCenter($(document.body))

  // Footer info
  m.mount(document.getElementById('stats-info'), stats)

  // Menu
  menu.setup()

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
