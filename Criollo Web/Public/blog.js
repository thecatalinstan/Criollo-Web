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
  if ( element.textContent.trim() == '' ) {
    element.innerHTML = placeholder
    // element.style.opacity = 0.25
  }

  element.addEventListener('focus', () => {
      // element.style.opacity = 1
    if ( element.textContent.trim() == placeholder ) {
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
      element.innerHTML = placeholder
      // element.style.opacity = 0.25
    }
  })
}

const setupEditor = (postElement, post) => {
  const titleElement = postElement.querySelector('h1.article-title')
  const authorElement = postElement.querySelector('span.article-author')
  const contentElement = postElement.querySelector('.article-content')
  const footerElement = postElement.querySelector('.article-footer')

  console.log('receivedPost', post)

  // Set the title as editable
  if ( titleElement ) {
    setupPlaceholder(titleElement, titlePlaceholder)
    if ( post.title ) {
      titleElement.innerHTML = post.title
    }
  }

  // Setup the post meta data (author and date)
  if ( authorElement ) {
    let authorDisplayName = post.author ? post.author.displayName : `${window.currentUser.firstName} ${window.currentUser.lastName}`.trim()
    if ( authorDisplayName == '' ) {
      authorDisplayName = window.currentUser.username
    }
    authorElement.innerHTML = authorDisplayName
  }

  // Remove the (rendered) body of the post
  if ( contentElement ) {
    contentElement.parentNode.removeChild(contentElement)
  }

  // Create a 'textarea' that we can edit the markdown in
  const contentEditor = document.createElement('textarea')
  contentEditor.className = 'article-content-editor'
  contentEditor.contentEditable = true
  if ( post.content ) {
    contentEditor.value = post.content
  }
  postElement.insertBefore(contentEditor, footerElement)

  // Create the excerpt label and editor element
  const excerptLabel = document.createElement('label')
  excerptLabel.className = 'article-excerpt-editor-label'
  excerptLabel.innerHTML = 'Excerpt:'
  postElement.insertBefore(excerptLabel, footerElement)

  const excerptEditor = document.createElement('textarea')
  excerptEditor.className = 'article-excerpt-editor'
  excerptEditor.contentEditable = true
  if ( post.excerpt ) {
    excerptEditor.innerHTML = post.excerpt
  }
  postElement.insertBefore(excerptEditor, footerElement)

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
    post.title = titleElement.textContent
    post.content = contentEditor.value
    post.excerpt = excerptEditor.textContent
    console.log('saving post', post)
    savePost(post, (data) => {
      console.log(data)
      window.defaultNotificationCenter.confirm('Post saved', data.publicPath, null, () => {
        window.location.pathName = data.publicPath
      })
      post = data
      postElement.dataset.post = post.uid
      postElement.id = `article-${post.uid.substr(post.uid.lastIndexOf('/') + 1)}`
    }, (err) => {
      console.error(err)
      window.defaultNotificationCenter.error('Unable to save post', err.message)
    })
  }
  footerElement.appendChild(saveButton)
}

const getPost = (path, success, failure) => {
  api( { url: `/api/blog/posts${path}?${Math.random()}` }, success, failure)
}
blog.getPost = getPost

blog.setup = () => {
  const postElement = document.querySelector('.content article.article')
  if ( !postElement ) {
    console.log(`There is no post element. Exiting.`)
    return
  }

  const postId = postElement.dataset.post
  const lastPathComponent = location.pathname.substr(location.pathname.lastIndexOf('/') + 1);
  if ( postId != '' && lastPathComponent != 'edit' ) {
    console.log(`Post id is ${postId}. Pathname is ${lastPathComponent}. Exiting.`)
    return
  }

  if ( postId && lastPathComponent == 'edit' ) {
    const postPath = '/' + postId;
    getPost(postPath, (data) => {
      setupEditor(postElement, data)
    }, (err) => {})
  } else {
    setupEditor(postElement, {})
  }
}


export default blog
