export default (config, success, failure) => {

    const url = config.url
    if (!url) {
      failure(new Error('No URL specified'))
      return;
    }

    const method = config.method || 'GET'
    const data = config.data || null

    let request = null
    if (window.XMLHttpRequest) {
      request = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
      try {
        request = new ActiveXObject('Msxml2.XMLHTTP');
      } catch (e) {
        try {
          request = new ActiveXObject('Microsoft.XMLHTTP');
        } catch (e) {}
      }
    }

    if (!request) {
      failure('Ajax not supported.')
      return
    }

    request.open(method, url)
    if ( method != 'GET' ) {
      request.setRequestHeader('Content-Type', 'application/json;charset=utf-8');
    }

    request.addEventListener('load', () => {
      if (request.status === 200) {

        let response = JSON.parse(request.responseText)
        if ( response.success ) {
          success(response.data)
        } else {
          failure(response.error)
        }
      } else {
        failure(request.statusText);
      }
    }, false)
    request.addEventListener('error', failure, false)
    request.send(data)
}
