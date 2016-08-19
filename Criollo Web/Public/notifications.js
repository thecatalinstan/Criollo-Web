const
  defaultTimeout = 3000,
  offscreenPoint = 320

const displayNotification = (center, notification) => {

  let element = document.createElement('div')
  element.id = `notification-${notification.id}`
  element.className = `notification ${notification.type}`
  element.onclick = removeNotification.bind(null, center, notification, false)
  element.style.left = `${offscreenPoint}px`
  element.style.opacity = 0

  let closeButton = document.createElement('div')
  closeButton.className = 'notification-close'
  closeButton.onclick = removeNotification.bind(null, center, notification, true)
  closeButton.innerHTML = 'x'
  element.appendChild(closeButton)

  let titleDiv = document.createElement('div')
  titleDiv.className = 'notification-title'
  titleDiv.innerHTML = notification.title
  element.appendChild(titleDiv)

  if (notification.text) {
    let textDiv = document.createElement('div')
    textDiv.className = 'notification-text'
    textDiv.innerHTML = notification.text
    element.appendChild(textDiv);
  }

  center.element.insertBefore(element, center.element.firstChild)

  window.setTimeout(() => {
    element.style.left = 0
    element.style.opacity = 1
  }, 50)
  window.setTimeout(removeNotification.bind(null, center, notification), isNaN(notification.timeout) ? defaultTimeout : notification.timeout)

  return element
}

const removeNotification = (center, notification, dismiss) => {
  if (!center.notifications[notification.id]) {
    return
  }

  notification.element.style.opacity = 0;
  notification.element.style.left = `${offscreenPoint}px`
  window.setTimeout(() => {
    center.element.removeChild(notification.element)
    delete center.notifications[notification.id]
  }, 300)

  if (!dismiss && notification.cb) {
    notification.cb(notification)
  }
}

const postNotification = (center, type, title, text, timeout, cb) => {
  let notification = {
    type: type,
    title: title,
    text: text,
    timeout: parseInt(timeout, 10),
    cb: cb,
    id: Math.round(Math.random() * 1000000)
  }

  notification.element = displayNotification(center, notification)

  center.notifications[notification.id] = notification
}

export default (parent, id) => {

  const center = {
    notifications: {}
  }

  center.info = postNotification.bind(null, center, 'info')
  center.error = postNotification.bind(null, center, 'error')
  center.warn = postNotification.bind(null, center, 'warn')
  center.confirm = postNotification.bind(null, center, 'confirm')
  center.notification = postNotification.bind(null, center)

  center.element = document.createElement('div')
  center.element.id = id || 'notification-center-' + Math.floor(Math.random() * 1000)
  center.element.className = 'notification-center'
  parent.appendChild(center.element)

  return center
}
