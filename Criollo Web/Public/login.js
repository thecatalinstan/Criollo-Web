import api from './api.js'

const login = {}

login.setup = (success, failure) => {
  if (!document.getElementById('login-button')) {
    return
  }

  document.getElementById('login-button').onclick = (e) => {
    api({
      url: `/api/login?${Math.random()}`,
      method: 'post',
      data: JSON.stringify({
        username: document.getElementById('username').value,
        password: document.getElementById('password').value
      })
    }, success, failure)
  }
}

login.confirm = (success, failure) => {
  api( { url: `/api/me?${Math.random()}` }, success, failure)
}

export default login
