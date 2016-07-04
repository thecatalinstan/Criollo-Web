import $ from 'jquery'

const getInfo = () => {
  $.ajax({
    url: `/api/info?${Math.random()}`,
    contentType: "application/json; charset=utf-8",
    dataType: "json",
  }).done((response) => {

  	let memoryUsage = response.data.memoryInfo > 0 ? ` using ${response.data.memoryInfo} of memory` : ""
  	let processInfo = `${response.data.processName} ${response.data.processVersion}${memoryUsage}, running for ${response.data.runningTime} on ${response.data.unameSystemVersion}. Served ${response.data.requestsServed} requests.`
    $($('.process-info .content p')[0]).text(processInfo)
    window.setTimeout(getInfo, 3000)
  })
}
export default {
  getInfo: getInfo
}
