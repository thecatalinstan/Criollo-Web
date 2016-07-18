import api from './api.js'

const blog = {}

const titlePlaceholder = 'Post title'
const contentPlaceholder = 'Post content'

const displayValidationError = (element, message) => {
  if ( window.defaultNotificationCenter ) {
    window.defaultNotificationCenter.error('Unable to Save Post', message)
  } else {
    console.error(message)
  }
  if ( element ) {
    element.focus()
  }
}

const savePost = (post, success, failure) => {
  const postElement = document.querySelector('.content article.article')
  api({
    url: `/api/blog/posts?${Math.random()}`,
    method: post.uid ? 'post' : 'put',
    data: JSON.stringify(post)
  }, success, failure)
}

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

  element.addEventListener('click', (e) => {
    try {
      element.focus
    } catch(e) {}
  })

  element.addEventListener('blur', () => {
    if ( element.textContent.trim() == '') {
      element.style.opacity = 0.25
      element.innerHTML = placeholder
    }
  })
}

const setupEditor = () => {
  const postElement = document.querySelector('.content article.article')
  if ( !postElement ) {
    console.log(`There is no post element. Exiting.`)
    return
  }

  let postId = postElement.dataset.post
  if ( postId != '' ) {
    console.log(`Post id is ${postId}. Exiting.`)
    return
  }

  const titleElement = postElement.querySelector('h1.article-title')
  const authorElement = postElement.querySelector('span.article-author')
  const contentElement = postElement.querySelector('.article-content')
  const footerElement = postElement.querySelector('.article-footer')

  // Set the title as editable
  if ( titleElement ) {
    setupPlaceholder(titleElement, titlePlaceholder)
  }

  // Setup the post meta data (author and date)
  if ( authorElement ) {
    let authorDisplayName = `${window.currentUser['first-name']} ${window.currentUser['last-name']}`.trim()
    if ( authorDisplayName == '' ) {
      authorDisplayName = window.currentUser.username
    }
    authorElement.innerHTML = authorDisplayName
  }

  // Remove the (rendered) body of the post
  if ( contentElement ) {
    contentElement.parentNode.removeChild(contentElement)
  }

  // Create a 'pre' that we can edit the markdown in
  const contentEditor = document.createElement('textarea')
  contentEditor.className = 'article-content-editor'
  contentEditor.contentEditable = true
  postElement.insertBefore(contentEditor, footerElement)

  // Add the editor js and css
  const editorCss = document.createElement('link')
  editorCss.rel = 'stylesheet'
  editorCss.href = '//cdn.jsdelivr.net/simplemde/latest/simplemde.min.css'
  postElement.parentNode.appendChild(editorCss)

  let simpleMDE = undefined
  const editorJs = document.createElement('script')
  editorJs.src = '//cdn.jsdelivr.net/simplemde/latest/simplemde.min.js'
  editorJs.onload = (e) => {
    simpleMDE = new SimpleMDE( {
      element: contentEditor,
      placeholder: contentPlaceholder,
      forceSync: true,
    })
  }
  postElement.parentNode.appendChild(editorJs)

  // Clear the footer and add the save button at the bottom
  footerElement.innerHTML = ''
  const saveButton = document.createElement('button')
  saveButton.innerHTML = 'Save'
  saveButton.className = 'save-button'
  saveButton.id = saveButton.className
  saveButton.onclick = (e) => {
    const post = {
      content: contentEditor.value,
      title: titleElement.textContent
    }
    if ( postId ) {
      post.uid = postId
    }

    console.log(post)

    savePost(post, (data) => {
      console.log(data)
      window.defaultNotificationCenter.confirm('Post saved', data['public-path'])
      postId = data.uid
      postElement.dataset.post = postId
      postElement.id = `article-${postId.substr(postId.lastIndexOf('/') + 1)}`
    }, (error) => {
      console.error(error)
      window.defaultNotificationCenter.error('Unable to save post', error)
    })
  }
  footerElement.appendChild(saveButton)
}

blog.setup = () => {
  setupEditor()
}

export default blog
