import $ from 'jquery'

const login = {}

login.setup = (success, failure) => {
  if (!$('#login-button')) {
    return
  }
  $('#login-button').on('click', (e) => {
    $.ajax({
        url: `/authenticate?${Math.random()}`,
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        method: 'post',
        data: JSON.stringify({
          username: $('#username').val(),
          password: $('#password').val()
        })
      })
      .done(success)
      .fail(failure)
  })
}

export default login
