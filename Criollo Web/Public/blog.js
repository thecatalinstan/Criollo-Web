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

const saveImage = (file, success, failure) => {
  const image = {
    "filename" : file.name,
    "filesize" : file.size,
    "mimeType" : file.type
  }
  api({
    url: `/api/blog/images?${Math.random()}`,
    method: 'put',
    data: JSON.stringify(image)
  }, success, failure)
}

const uploadImage = (iid, file, success, failure, progress) => {
  api({
    url: `/api/blog/images/${iid}?${Math.random()}`,
    method: 'post',
    data: file,
    dontSetContentType: true
  }, success, failure, progress)
}

const savePost = (post, success, failure) => {
  api({
    url: `/api/blog/posts?${Math.random()}`,
    method: post.uid ? 'post' : 'put',
    data: JSON.stringify(post)
  }, success, failure)
}

const deletePost = (uid, success, failure) => {
  api({
    url: `/api/blog/posts/${uid}?${Math.random()}`,
    method: 'delete',
  }, success, failure)
}

const autosize = (element) => {
  const scrollOffset = document.scrollingElement.scrollTop
  const minHeight = parseInt(window.getComputedStyle(element,null).getPropertyValue("min-height"), 10)   
  element.style.height = 'auto'
  element.style.height = `${Math.max(minHeight || 138, element.scrollHeight)}px`
  document.scrollingElement.scrollTop = scrollOffset
}

const setupAutosize = (element) => {
  autosize(element)
  element.addEventListener('change', autosize.bind(null, element))
  element.addEventListener('cut', window.setTimeout.bind(null, autosize.bind(null, element), 0), false)
  element.addEventListener('paste', window.setTimeout.bind(null, autosize.bind(null, element), 0), false)
  element.addEventListener('drop', window.setTimeout.bind(null, autosize.bind(null, element), 0), false)
  element.addEventListener('keydown', window.setTimeout.bind(null, autosize.bind(null, element), 0), false)
  element.addEventListener('focus', window.setTimeout.bind(null, autosize.bind(null, element), 0), false)
}

const setupEditor = (postElement, post) => {
  console.log('Received post:', post)

  // Set the title as editable
  const titleElement = postElement.querySelector('h1.article-title')
  titleElement.contentEditable = true
  titleElement.dataset.placeholder = titlePlaceholder
  if (post.title) {
    titleElement.innerHTML = post.title
  }
  titleElement.addEventListener('paste', (e) => {
    e.preventDefault()
    document.execCommand('insertHTML', false, e.clipboardData.getData('text/plain'))
  })
  titleElement.addEventListener('keyup', (e) => {
    if (!e.target.textContent.trim().length) {
      e.target.innerHTML = ''
    }
  })

  // Setup the post meta data (author and date)
  const authorElement = postElement.querySelector('span.article-author')
  let authorDisplayName = post.author ? post.author.displayName : `${window.currentUser.firstName} ${window.currentUser.lastName}`.trim()
  if (authorDisplayName == '') {
    authorDisplayName = window.currentUser.username
  }
  authorElement.innerHTML = authorDisplayName

  // 24 aug 2020 at 08:52
  // publishedDateElement.innerHTML = `, ${date.toLocaleDateString(['en-DK'], { year: 'numeric', month: 'short', day: 'numeric' })} at ${date.toLocaleTimeString(['en-DK'], { hour: '2-digit', minute: '2-digit', hour12: false })}`    
  const publishedDateElement = postElement.querySelector('span.article-date')
  let date;
  if (!(date = post.publishedDate)) {
    date  = (new Date()).toISOString()
  }
  publishedDateElement.innerHTML = date
  publishedDateElement.contentEditable = true
  publishedDateElement.addEventListener('keydown', (e) => {
    var charCode = (e.which) ? e.which : evt.keyCode    
    if (charCode == 8 || (charCode >= 37 && charCode <= 40)) {
      return
    }

    if (/^[0-9:\-TtZz+]{1}$/.test(e.key)) {
      return
    }

    e.preventDefault()
  })

  if (!post.uid) {
    const toolbar = postElement.querySelector('span.article-toolbar')
    toolbar.parentNode.removeChild(toolbar)    
  } else {
    const editLink = postElement.querySelector('span.article-toolbar a:first-of-type')
    editLink.parentNode.removeChild(editLink.nextSibling)
    editLink.parentNode.removeChild(editLink)    
  }

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

  // Enable image editor
  const imageContainer = document.querySelector('.article-image-container');
  imageContainer.classList.remove('hidden')
  
  const imageEditor = document.querySelector('.article-image')

  let selectedFile;

  const imageUploadFile = document.createElement('input')
  imageUploadFile.type = 'file'
  imageUploadFile.multiple = false
  imageUploadFile.className = 'image-upload-file'
  imageUploadFile.accept = 'image/*'
  imageUploadFile.style.display = 'none'
  imageUploadFile.onchange = (e) => {
    e.preventDefault()
    if(imageUploadFile.files.length) {
      selectedFile = imageUploadFile.files[0]    
      imageEditor.style.backgroundImage = `url('${URL.createObjectURL(selectedFile)}')`
    }
  }
  imageEditor.appendChild(imageUploadFile)

  const imageSelector = document.createElement('div')
  imageSelector.className = 'image-selector'
  imageSelector.innerHTML = 'Select Image'
  imageSelector.onclick = (e) => {
    e.preventDefault()
    imageUploadFile.click()
  }
  imageEditor.appendChild(imageSelector)

  const imageUploadProgress = document.createElement('div')
  imageUploadProgress.className = 'image-upload-progress'
  imageUploadProgress.innerHTML = ''

  const imageUploadProgressIndicator = document.createElement('div')
  imageUploadProgressIndicator.className = 'progress-indicator'
  imageUploadProgressIndicator.innerHTML = ''
  imageUploadProgress.appendChild(imageUploadProgressIndicator)

  imageEditor.appendChild(imageUploadProgress)

  // Remove the (rendered) body of the post
  const contentElement = postElement.querySelector('.article-content')
  contentElement.innerHTML = ''

  // Create a 'textarea' that we can edit the markdown in
  const contentEditor = document.createElement('textarea')
  contentEditor.className = 'article-content-editor'
  if (post.content) {
    contentEditor.value = post.content    
  }
  contentEditor.placeholder = contentPlaceholder
  contentElement.appendChild(contentEditor)
  setupAutosize(contentEditor)

  // Create the excerpt label and editor element
  const excerptLabel = document.createElement('label')
  excerptLabel.className = 'article-excerpt-editor-label'
  excerptLabel.innerHTML = 'Excerpt:'  
  contentElement.appendChild(excerptLabel)

  const excerptEditor = document.createElement('textarea')
  excerptEditor.className = 'article-excerpt-editor'
  if (post.excerpt) {
    excerptEditor.value = post.excerpt
  }
  excerptEditor.placeholder = excerptPlaceholder
  contentElement.appendChild(excerptEditor)
  setupAutosize(excerptEditor)

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

  // <div class="checkbox-container">
  const publishedEditorContainer = document.createElement('div')
  publishedEditorContainer.className = 'checkbox-container'
  publishedContainer.appendChild(publishedEditorContainer)

  //   <label class="checkbox-label">
  const publishedEditorContainerLabel = document.createElement('label')
  publishedEditorContainerLabel.className = 'checkbox-label'
  publishedEditorContainer.appendChild(publishedEditorContainerLabel)

  //       <input type="checkbox">
  const publishedEditor = document.createElement('input')
  publishedEditor.type = 'checkbox'
  publishedEditor.className = 'article-published-editor'
  publishedEditor.id = 'article-published-editor-' + post.uid
  publishedEditor.checked = post.published
  publishedEditorContainerLabel.appendChild(publishedEditor)

  //       <span class="checkbox-custom rectangular"></span>
  const publishedEditorCheckboxOverlay = document.createElement('span')
  publishedEditorCheckboxOverlay.className = 'checkbox-custom rectangular'
  publishedEditorContainerLabel.appendChild(publishedEditorCheckboxOverlay)  

  //   <label class="input-title">Published</label>
  const publishedLabel = document.createElement('label')
  publishedLabel.htmlFor = publishedEditor.id
  publishedLabel.className = 'article-published-editor-label input-title'
  publishedLabel.innerHTML = 'Published'
  publishedEditorContainer.appendChild(publishedLabel)
  
  footerElement.appendChild(publishedContainer)

  const saveButton = document.createElement('button')
  saveButton.innerHTML = 'Save'
  saveButton.className = 'save-button'
  saveButton.id = saveButton.className
  saveButton.onclick = (e) => {
    const submitPost = () => {
      post.title = titleElement.textContent
      if (post.uid) {
        post.handle = handleEditor.value
      }
      post.publishedDate = publishedDateElement.textContent
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

        imageSelector.classList.remove('hidden') 

        window.history.pushState('', '', post.publicPath + '/edit')
      }, (err) => {
        console.error(err)
        window.notifier.error('Unable to save post', err.message)
      })
    }

    if (!selectedFile) {
      submitPost()
    } else {
      imageContainer.scrollIntoView()
      imageEditor.classList.add('uploading')
      saveImage(selectedFile, (data) => {
        console.log('Created image:', data)
        let image = data

        uploadImage(image.uid, selectedFile, (data) => {
          console.log('Uploaded image:', data)

          post.image = image
          imageEditor.classList.remove('uploading')
          imageSelector.classList.add('hidden')         
          
          submitPost()
          
        }, (err) => {
          imageEditor.classList.remove('uploading')

          console.error(err)
          window.notifier.error('Image upload failed', err.message)
        }, (loaded, total) => {
          let percent = loaded/total*100
          imageUploadProgressIndicator.style.width = `${percent}%`
          if (percent > 10) {
            imageUploadProgressIndicator.innerHTML = `${Math.round(percent)}%`
          }
        })     
      }, (err) => {
        imageEditor.classList.remove('uploading')
        console.error(err)
        window.notifier.error('Image creation failed', err.message)
      })    

    }

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
  // Add delete link
  const deleteLinks = document.querySelectorAll('.blog article.article .article-toolbar a.delete-post')
  deleteLinks.forEach((item, index) => {
    const pid = item.dataset.post
    const title = document.querySelector(`#article-${pid} .article-title a`).textContent
    item.onclick = (e) => {
      e.preventDefault()      
      if (!confirm(`Are you sure you want to delete '${title}'`)) {
        return
      }
      
      deletePost(pid, (data) => {
        console.log('Deleted post:', data)
        window.notifier.confirm('Succcessfully deleted post', data.title)
        const article = document.querySelector(`#article-${pid}`)
        article.classList.add('deleting')
        setTimeout(() => {
          article.parentNode.removeChild(article)
        }, 750)
      }, (err) => {
        console.error(err)
        window.notifier.error('Unable to delete post', err.message)
      })
      
    }
  })

  // Setup edit post
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
    // console.log(`There is no post element. Exiting.`)
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
