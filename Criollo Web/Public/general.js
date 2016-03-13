var mailchimp = function() {
  return {
    subscribe: function(path, token, listId) {
      console.log(arguments)
      return false
    }
  }
}

document.onload = function() {
  mailchimp().subscribe()
}

