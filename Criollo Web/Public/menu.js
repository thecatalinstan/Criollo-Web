import $ from 'jquery'

const addScrolledClass = (menu) => {
  if (!menu.hasClass('scrolled')) {
    menu.addClass('scrolled')
  }
  if (!$(document.body).hasClass('scrolled')) {
    $(document.body).addClass('scrolled')
  }
}

const removeScrolledClass = (menu) => {
  if (menu.hasClass('scrolled')) {
    menu.removeClass('scrolled')
  }
  if ($(document.body).hasClass('scrolled')) {
    $(document.body).removeClass('scrolled')
  }
}

export default {
  setup: () => {
    let mastheadLogo = $('.masthead .logo')
    let mainMenu = $('nav.main-menu')
    if (mastheadLogo.length) {
      $(window).scroll(() => {
        var scroll = $(window).scrollTop()
        if (scroll >= mastheadLogo.offset().top - mainMenu.height()) {
          addScrolledClass(mainMenu)
        } else {
          removeScrolledClass(mainMenu)
        }
      })
    } else {
      addScrolledClass(mainMenu)
    }
  }
}
