import $ from 'jquery'

const
  defaultTimeout = 3000,
  offscreenPoint = 320

const displayNotification = (center, notification) => {

  let element = $('<div/>', {
      id: `notification-${notification.id}`,
      class: `notification hidden ${notification.type}`,
      click: removeNotification.bind(null, center, notification, false),
    })
    .css('left', `${offscreenPoint}px`)
    .append($('<div/>', {
      class: 'notification-close',
      click: removeNotification.bind(null, center, notification, true),
      text: 'x'
    }))
    .append($('<div/>', {
      class: 'notification-title',
      text: notification.title
    }));

  if (notification.text) {
    element.append($('<div/>', {
      class: 'notification-text',
      text: notification.text
    }))
  }
  center.element.prepend(element)

  element.animate({ left: 0 }, () => {
    window.setTimeout(removeNotification.bind(null, center, notification), isNaN(notification.timeout) ? defaultTimeout : notification.timeout)
  })


  return element
}

const removeNotification = (center, notification, dismiss) => {
  if (!center.notifications[notification.id]) {
    return
  }

  notification.element.animate({ opacity: 0, left: offscreenPoint }, () => {
    notification.element.remove()
    delete center.notifications[notification.id]
  });

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

  center.element = $('<div/>', { id: id || 'notification-center-' + Math.floor(Math.random() * 1000), class: 'notification-center' })
  parent.append(center.element)

  return center
}
