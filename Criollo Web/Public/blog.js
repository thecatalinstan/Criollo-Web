const blog = {}

const titlePlaceholder = 'Post title'
const contentPlaceholder = 'Post content'

const setupPlaceholder = (element, placeholder) => {

  element.contentEditable = true
  element.style.opacity = 0.25
  element.innerHTML = placeholder

  element.addEventListener('focus', () => {
    if ( element.textContent.trim() == placeholder ) {
      element.style.opacity = 1
      element.innerHTML = ''
    }
  })

  element.addEventListener('blur', () => {
    if ( element.textContent.trim() == '') {
      element.style.opacity = 0.25
      element.innerHTML = placeholder
    }
  })
}

const setupContentEditable = () => {
  const postElement = document.querySelector('.content article.article')
  if ( !postElement ) {
    return
  }

  const postId = postElement.dataset.post
  if ( postId != '' ) {
    return
  }

  // Set the title as editable
  const titleElement = postElement.querySelector('h1.article-title')
  if ( titleElement ) {
    setupPlaceholder(titleElement, titlePlaceholder)
  }

  // Setup the post meta data (author and date)
  const authorElement = postElement.querySelector('span.article-author')
  if ( authorElement ) {
    let authorDisplayName = `${window.currentUser['first-name']} ${window.currentUser['last-name']}`.trim()
    if ( authorDisplayName == '' ) {
      authorDisplayName = window.currentUser.username
    }
    authorElement.innerHTML = authorDisplayName
  }

  // Hide the (rendered) body of the post
  const contentElement = postElement.querySelector('.article-content')
  if ( contentElement ) {
    contentElement.style.display = 'none'
  }

  // Create a 'pre' that we can edit the markdown in
  const contentEditor = document.createElement('pre')
  contentEditor.className = 'article-body-editor'
  contentEditor.contentEditable = true
  setupPlaceholder(contentEditor, contentPlaceholder)
  postElement.insertBefore(contentEditor, contentElement)
}

blog.setup = () => {
  setupContentEditable()
}

export default blog
