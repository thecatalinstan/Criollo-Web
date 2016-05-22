import $ from 'jquery'
import hljs from 'highlight.js'

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

  // Footer info
  getInfo()

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
      } else {
        if (mainMenu.hasClass('scrolled')) {
          mainMenu.removeClass('scrolled')
        }
      }
    })
  } else {
    if (!mainMenu.hasClass('scrolled')) {
      mainMenu.addClass('scrolled')
    }
  }

  // Login form
  let loginForm = $('#login-form')
  if (loginForm) {
    console.log(loginForm)
    $('#login-button').on('click', (e) => {
      $.ajax({
        dataType: 'json',
        url: `/authenticate?${Math.random()}`,
        method: 'post',
        data: {
          username: $('#username').value,
          password: $('#password').value
        }
      }).done((text) => {
        console.log('cool')
      })
    })
  }

})
