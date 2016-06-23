import $ from 'jquery'

const defaultTimeout = 30000

const displayNotification = (center, notification) => {
  center.notifications.push(notification)

  let element = $('<div/>', {
    class: `notification ${notification.type}`,
    click: removeNotification.bind(null, center, notification, false),
  })
    .append($('<div/>', {
      class: 'notification-close',
      click: removeNotification.bind(null, center, notification, true),
      text: 'X'
    }))
    .append($('<div/>', {
      class: 'notification-title',
      text: notification.title
    }));

  if ( notification.text ) {
    element.append($('<div/>', {
      class: 'notification-text',
      text: notification.text
    }))
  }

  center.element.prepend(element)

  let timeout = notification.timeout
  if (isNaN(timeout)) {
    timeout = defaultTimeout
  }

  center.timeouts.push(window.setTimeout(() => {
    removeNotification(center, notification)
  }, timeout))
}

const removeNotification = (center, notification, dismiss) => {
  let notificationElements = center.element.find('.notification')
  let idx = center.notifications.indexOf(notification)

  center.notifications.splice(idx, 1)

  window.clearTimeout(center.timeouts[idx])
  center.timeouts.splice(idx, 1)

  const element = $(notificationElements[notificationElements.length - idx - 1])
  element.remove()

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
  }

  notification.element = displayNotification(center, notification)
}

export default (parent, id) => {

  const center = {
    notifications: [],
    timeouts: []
  }

  center.info = postNotification.bind(null, center, 'info')
  center.error = postNotification.bind(null, center, 'error')
  center.warn = postNotification.bind(null, center, 'warn')
  center.confirm = postNotification.bind(null, center, 'confirm')
  center.notification = postNotification.bind(null, center)

  center.element = $('<div/>', { id: id || 'notification-center-' + Math.floor(Math.random() * 1000), class: 'notification-center' })
  parent.append(center.element)

  return center
}
