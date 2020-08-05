import api from './api.js'

const blog = {}

const titlePlaceholder = 'Post title'
const contentPlaceholder = 'Enter the post content as markdown here'
const excerptPlaceholder = 'The post excerpt (leave blank to autogenerate)'
const tagsPlaceholder = 'Enter some tags'

const displayValidationError = (element, message) => {
  if (window.notifier) {
    window.notifier.error('Unable to Save Post', message)
  } else {
    console.error(message)
  }
  if (element) {
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
  if (element.textContent.trim() == '') {
    element.innerHTML = placeholder
  }

  element.addEventListener('focus', () => {
    if (element.textContent.trim() == placeholder) {
      element.innerHTML = ''
    }
  })

  element.addEventListener('click', (e) => {
    try {
      element.focus()
    } catch(e) {}
  })

  element.addEventListener('blur', () => {
    if (element.textContent.trim() == '') {
      element.innerHTML = placeholder
    }
  })
}

const setupEditor = (postElement, post) => {
  console.log('Received post:', post)

  // Set the title as editable
  const titleElement = postElement.querySelector('h1.article-title')
  setupPlaceholder(titleElement, titlePlaceholder)
  if (post.title) {
    titleElement.innerHTML = post.title
  }
  titleElement.addEventListener('paste', (e) => {
    e.preventDefault()
    const text = e.clipboardData.getData('text/plain')
    document.execCommand('insertHTML', false, text)
  })

  // Setup the post meta data (author and date)
  const authorElement = postElement.querySelector('span.article-author')
  let authorDisplayName = post.author ? post.author.displayName : `${window.currentUser.firstName} ${window.currentUser.lastName}`.trim()
  if (authorDisplayName == '') {
    authorDisplayName = window.currentUser.username
  }
  authorElement.innerHTML = authorDisplayName

  // Edit the handle
  const handleContainer = document.createElement('div')
  handleContainer.className = 'article-handle-container'
  if (!post.uid) {
    handleContainer.style.display = 'none'
  }

  const handleEditor = document.createElement('input')
  handleEditor.type = 'text'
  handleEditor.className = 'article-handle-editor'
  handleEditor.id = 'article-handle-editor-' + post.uid
  handleEditor.value = post.handle

  const handleLabel = document.createElement('label')
  handleLabel.htmlFor = handleEditor.id
  handleLabel.className = 'article-handle-editor-label'
  if (post.publicPath) {
    handleLabel.innerHTML = `${location.protocol}//${location.host}${post.publicPath.substr(0, post.publicPath.lastIndexOf('/') + 1)}`
  } else {
    handleLabel.innerHTML = `${location.protocol}//${location.host}/blog/${(new Date()).getFullYear()}/${(new Date()).getMonth()}/`
  }

  handleContainer.appendChild(handleLabel)
  handleContainer.appendChild(handleEditor)

  titleElement.parentNode.appendChild(handleContainer)

  if (!post.uid) {
      titleElement.onblur = (e) => {
        makeHandle(e.target.textContent, (data) => {
          if (!data) {
            return
          }
          handleEditor.value = data
          handleContainer.style.display = 'initial'
          titleElement.onblur = null
        }, (err) => {
          console.error(err)
        })
      }
    }

  // Remove the (rendered) body of the post
  const contentElement = postElement.querySelector('.article-content')
  contentElement.innerHTML = ''

  // Create a 'textarea' that we can edit the markdown in
  const contentEditor = document.createElement('textarea')
  contentEditor.className = 'article-content-editor'
  contentEditor.contentEditable = true
  if (post.content) {
    contentEditor.value = post.content    
  }
  contentElement.appendChild(contentEditor)
  contentEditor.style.height = contentEditor.scrollHeight + 'px'

  // Create the excerpt label and editor element
  const excerptLabel = document.createElement('label')
  excerptLabel.className = 'article-excerpt-editor-label'
  excerptLabel.innerHTML = 'Excerpt:'  
  contentElement.appendChild(excerptLabel)

  const excerptEditor = document.createElement('textarea')
  excerptEditor.className = 'article-excerpt-editor'
  excerptEditor.contentEditable = true
  if (post.excerpt) {
    excerptEditor.innerHTML = post.excerpt
  }
  excerptEditor.placeholder = excerptPlaceholder
  contentElement.appendChild(excerptEditor)

  // Create the tags label and editor element
  const tagsLabel = document.createElement('label')
  tagsLabel.className = 'article-tags-editor-label'
  tagsLabel.innerHTML = 'Tags:'
  contentElement.appendChild(tagsLabel)

  const tagsEditor = document.createElement('input')
  tagsEditor.type = 'text'
  tagsEditor.className = 'article-tags-editor'
  tagsEditor.contentEditable = true
  if (post.tags) {
    tagsEditor.innerHTML = post.tags
  }
  contentElement.appendChild(tagsEditor)

  // Clear the footer
  const footerElement = postElement.querySelector('.article-footer')
  footerElement.innerHTML = ''

  // Create the published checkbox and label
  const publishedContainer = document.createElement('div')
  publishedContainer.className = 'article-published-container'

  const publishedPermalink = document.createElement('a')
  publishedPermalink.className = 'article-published-editor-permalink'
  if (!post.uid) {
    publishedPermalink.style.display = 'none'
  }
  publishedPermalink.href = `${location.protocol}//${location.host}${post.publicPath}`
  publishedPermalink.innerHTML = `${location.protocol}//${location.host}${post.publicPath}`
  publishedPermalink.target = '_blank'
  publishedContainer.appendChild(publishedPermalink)

  const publishedEditor = document.createElement('input')
  publishedEditor.type = 'checkbox'
  publishedEditor.className = 'article-published-editor'
  publishedEditor.id = 'article-published-editor-' + post.uid
  publishedEditor.checked = post.published
  publishedContainer.appendChild(publishedEditor)

  const publishedLabel = document.createElement('label')
  publishedLabel.htmlFor = publishedEditor.id
  publishedLabel.className = 'article-published-editor-label'
  publishedLabel.innerHTML = 'Published'
  publishedContainer.appendChild(publishedLabel)
  
  footerElement.appendChild(publishedContainer)

  const saveButton = document.createElement('button')
  saveButton.innerHTML = 'Save'
  saveButton.className = 'save-button'
  saveButton.id = saveButton.className
  saveButton.onclick = (e) => {
    post.title = titleElement.textContent
    if (post.uid) {
      post.handle = handleEditor.value
    }
    post.content = contentEditor.value
    post.excerpt = excerptEditor.value
    post.tags = tokenField.getItems().map ( (item) => {
      if (item.isNew) {
        return { 'name': item.name }
      } else {
        return item
      }
    })
    post.published = publishedEditor.checked
    console.log('Saving post:', post)

    savePost(post, (data) => {
      console.log('Saved post:', data)

      window.notifier.confirm('Post saved', data.publicPath)

      if (!post.uid) {
        window.location.href = data.publicPath + '/edit'
        return
      }

      post = data
      postElement.dataset.post = post.uid
      postElement.id = `article-${post.uid.substr(post.uid.lastIndexOf('/') + 1)}`

      handleLabel.innerHTML = `${location.protocol}//${location.host}${post.publicPath.substr(0, post.publicPath.lastIndexOf('/') + 1)}`
      handleEditor.value = post.handle

      tokenField.setItems(post.tags)
      publishedPermalink.href = `${location.protocol}//${location.host}${post.publicPath}`
      publishedPermalink.innerHTML = `${location.protocol}//${location.host}${post.publicPath}`

      window.history.pushState('', '', post.publicPath + '/edit')
    }, (err) => {
      console.error(err)
      window.notifier.error('Unable to save post', err.message)
    })
  }
  footerElement.appendChild(saveButton)

  // // Add the editor js and css
  // const excerptEditorCss = document.createElement('link')
  // excerptEditorCss.rel = 'stylesheet'
  // excerptEditorCss.href = '/editor.css'
  // postElement.parentNode.appendChild(excerptEditorCss)

  // let simpleMDE = undefined
  // const excerptEditorJs = document.createElement('script')
  // excerptEditorJs.src = '//cdn.jsdelivr.net/simplemde/latest/simplemde.min.js'
  // excerptEditorJs.onload = (e) => {
  //   simpleMDE = new SimpleMDE({
  //     element: contentEditor,
  //     placeholder: contentPlaceholder,
  //     forceSync: true,
  //   })
  // }
  // postElement.parentNode.appendChild(excerptEditorJs)

  // Add tags editorjs and css
  const tagsEditorCss = document.createElement('link')
  tagsEditorCss.rel = 'stylesheet'
  tagsEditorCss.href = '/tokenfield.css'
  postElement.parentNode.appendChild(tagsEditorCss)

  let tokenField = undefined
  const tagsEditorJs = document.createElement('script')
  tagsEditorJs.src = '/static/tokenfield.min.js'
  tagsEditorJs.onload = (e) => {
    tokenField = new Tokenfield({
      el: document.querySelector('.article-tags-editor'),
      setItems: post.tags || [],
      placeholder: tagsPlaceholder,
      newItems: true,
      itemValue: 'uid',
      remote: {
        type: 'GET',
        url: '/api/blog/tags/search',
        queryParam: 'q',
        delay: 300,
        timestampParam: 't'
      },
      minWidth: 60
    })
    tokenField.remapData = (data) => {
      return data.data
    }    
  }
  postElement.parentNode.appendChild(tagsEditorJs)

  postElement.classList.add("editing")
}

const getPost = (path, success, failure) => {
  api( { url: `/api/blog/posts${path}?${Math.random()}` }, success, failure)
}
blog.getPost = getPost

const makeHandle = (input, success, failure) => {
  api( { url: `/api/blog/make-handle?input=${escape(input.trim())}` }, success, failure)
}
blog.getPost = getPost

blog.setup = () => {
  const postElement = document.querySelector('.blog article.article.single')
  if (!postElement) {
    console.log(`There is no post element. Exiting.`)
    return
  }

  const postId = postElement.dataset.post
  const lastPathComponent = location.pathname.substr(location.pathname.lastIndexOf('/') + 1)
  if (postId != '' && lastPathComponent != 'edit') {
    console.log(`Post id is ${postId}. Pathname is ${lastPathComponent}. Exiting.`)
    return
  }

  if (postId && lastPathComponent == 'edit') {
    const postPath = '/' + postId
    getPost(postPath, (data) => {
      setupEditor(postElement, data)
    }, (err) => {})
  } else {
    setupEditor(postElement, {})
  }
}

blog.relatedPosts = () => {
  const postElement = document.querySelector('.content article.article')
  if (!postElement) {
    console.log(`There is no post element. Exiting.`)
    return
  }

  const postId = postElement.dataset.post
  if (!postId) {
    return
  }

  api( { url: `/api/blog/related/${postId}?${Math.random()}` },
    (data) => {
      console.log('data', data)
    },
    (err) => {
      console.error('error', err)
    }
  )
}

export default blog
