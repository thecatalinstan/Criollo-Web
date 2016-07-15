import api from './api.js'

const blog = {}

const titlePlaceholder = 'Post title'
const contentPlaceHolder = 'Post content'

const setupPlaceholder = (element, placeholder) => {

  element.style.opacity = 0.25
  element.innerHTML = placeholder
  element.style.backgroundColor = 'red'

  element.onfocus = () => {
    if ( element.textContent.trim() == placeholder ) {
      element.style.opacity = 1
      element.innerHTML = ''
    }
  }

  element.onblur = () => {
    if ( element.textContent.trim() == '') {
      element.style.opacity = 0.25
      element.innerHTML = placeholder
    }
  }
}

const setupContentEditable = () => {
  let postElement = document.querySelector('.content article.article')
  if ( !postElement ) {
    return
  }

  // Set the title as editable
  let titleElement = postElement.querySelector('h1.article-title')
  if ( titleElement ) {
    titleElement.contentEditable = true
    titleElement.style.outline = 'none'
    setupPlaceholder(titleElement, titlePlaceholder)
  }

  // Set the body as editable
  let contentElement = postElement.querySelector('.article-content')
  if ( contentElement ) {
    contentElement.style.width = '100%'
    contentElement.style.minHeight = '300px'
    contentElement.style.height = 'auto'
    contentElement.contentEditable = true
    contentElement.style.outline = 'none'
    setupPlaceholder(contentElement, contentPlaceholder)
  }
}

blog.setup = () => {
  setupContentEditable()
}

export default blog
