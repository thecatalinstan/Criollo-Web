import api from './api.js'

const login = {}

login.setup = (success, failure) => {
  const loginButton = document.getElementById('login-button')
  if (!loginButton) {
    return
  }

  const usernameField = document.getElementById('username');
  const passwordField = document.getElementById('password');

  const login = (e) => {
    api({
      url: `/api/login?${Math.random()}`,
      method: 'post',
      data: JSON.stringify({
        username: usernameField.value,
        password: passwordField.value
      })
    }, success, failure)
  }

  const enter = (callback, e) => {
    if (event.keyCode !== 13) {
      return
    }

    e.preventDefault()
    callback(e)  
  }

  loginButton.onclick = login
  usernameField.addEventListener('keyup', enter.bind(null, login))
  passwordField.addEventListener('keyup', enter.bind(null, login))
}

login.confirm = (success, failure) => {
  api( { url: `/api/me?${Math.random()}` }, success, failure)
}

export default login
