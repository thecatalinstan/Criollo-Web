const addScrolledClass = (menu) => {
  if (menu.className.indexOf('scrolled') < 0) {
    menu.className += ' scrolled'
  }
  if (document.body.className.indexOf('scrolled') < 0) {
    document.body.className += ' scrolled'
  }
}

const removeScrolledClass = (menu) => {
  if (menu.className.indexOf('scrolled') >= 0) {
    menu.className = menu.className.replace('scrolled', '')
  }
  if (document.body.className.indexOf('scrolled') >= 0) {
    document.body.className = document.body.className.replace('scrolled', '')
  }
}

export default {
  setup: () => {
    let mastheadLogo = document.querySelector('.masthead .logo')
    let mainMenu = document.querySelector('nav.main-menu')
    if (mastheadLogo) {
      document.body.onscroll = () => {
        var scroll = document.body.scrollTop
        if (scroll >= mastheadLogo.offsetTop - mainMenu.offsetHeight) {
          addScrolledClass(mainMenu)
        } else {
          removeScrolledClass(mainMenu)
        }
      }
    } else {
      addScrolledClass(mainMenu)
    }
  }
}
