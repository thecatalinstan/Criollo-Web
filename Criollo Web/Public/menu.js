const scrolledClass = 'scrolled'
const addScrolledClass = (menu) => {
  menu.classList.add(scrolledClass)
  document.body.classList.add(scrolledClass)
}

const removeScrolledClass = (menu) => {
  menu.classList.remove(scrolledClass)
  document.body.classList.remove(scrolledClass)
}

export default {
  setup: () => {
    let mastheadLogo = document.querySelector('.masthead .logo')
    let mainMenu = document.querySelector('nav.main-menu')
    if (!mastheadLogo) {
      addScrolledClass(mainMenu)
      return
    }
    
    document.body.onscroll = () => {
      let scroll = Math.max(parseInt(document.body.scrollTop, 10), parseInt(document.documentElement.scrollTop, 10))
      if (scroll >= mastheadLogo.offsetTop - mainMenu.offsetHeight) {
        addScrolledClass(mainMenu)
      } else {
        removeScrolledClass(mainMenu)
      }
    }
  }
}
