import m from 'mithril'

const getInfo = () => {
  m.request({
    url: `/api/info?${Math.random()}`,
    contentType: "application/json; charset=utf-8",
    dataType: "json",
  }).then( (response) => {
    console.log(response)
  	let memoryUsage = response.data.memoryInfo > 0 ? ` using ${response.data.memoryInfo} of memory` : ""
    let textContainer = document.querySelector('.process-info .content p')
    console.log(textContainer)
    textContainer.innerHTML = `${response.data.processName} ${response.data.processVersion}${memoryUsage}, running for ${response.data.runningTime} on ${response.data.unameSystemVersion}. Served ${response.data.requestsServed} requests.`
    window.setTimeout(getInfo, 3000)
  })
}
export default {
  getInfo: getInfo
}
