import $ from 'jquery'
import hljs from 'highlight.js'
import notificationCenter from './notifications.js'

hljs.initHighlightingOnLoad()

const getInfo = _ => {
  $.ajax({
    dataType: 'text',
    url: `/info?${Math.random()}`
  }).done((text) => {
    $($('.process-info .content p')[0]).text(text)
    setTimeout(getInfo, 3000)
  })
}

$(document).ready(_ => {

  // Setup notification center
  const defaultNotificationCenter = notificationCenter($(document.body))

  // Footer info
  // getInfo()

  // Menu
  let mastheadLogo = $('.masthead .logo')
  let mainMenu = $('nav.main-menu')
  if (mastheadLogo.length) {
    $(window).scroll(_ => {
      var scroll = $(window).scrollTop()
      if (scroll >= mastheadLogo.offset().top - mainMenu.height()) {
        if (!mainMenu.hasClass('scrolled')) {
          mainMenu.addClass('scrolled')
        }
        if (!$(document.body).hasClass('scrolled')) {
          $(document.body).addClass('scrolled')
        }
      } else {
        if (mainMenu.hasClass('scrolled')) {
          mainMenu.removeClass('scrolled')
        }
        if ($(document.body).hasClass('scrolled')) {
          $(document.body).removeClass('scrolled')
        }
      }
    })
  } else {
    if (!mainMenu.hasClass('scrolled')) {
      mainMenu.addClass('scrolled')
    }
    if (!$(document.body).hasClass('scrolled')) {
      $(document.body).addClass('scrolled')
    }
  }

  // Login form
  let loginForm = $('#login-form')
  if (loginForm) {
    $('#login-button').on('click', (e) => {
      let opts = {
        url: `/authenticate?${Math.random()}`,
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        method: 'post',
        data: JSON.stringify({
          username: $('#username').val(),
          password: $('#password').val()
        })
      };
      $.ajax(opts).done((text) => {
        defaultNotificationCenter.info(`Welcome, ${text}!`)
      }).fail((err) => {
        console.log()
        defaultNotificationCenter.error('Login failed')
      })
    })
  }
})
