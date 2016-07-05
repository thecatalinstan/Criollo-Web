import api from './api.js'

const getStats = (container) => {
  api({ url: `/api/info?${Math.random()}` }, (data) => {
    let stats = '';
    if (data) {
      let memoryUsage = data.memoryInfo.length > 0 ? ` using ${data.memoryInfo} of memory` : ""
      stats = `${data.processName} ${data.processVersion}${memoryUsage}, running for ${data.runningTime} on ${data.unameSystemVersion}. Served ${data.requestsServed} requests.`
    }
    container.innerHTML = stats
    window.setTimeout(getStats.bind(null, container), 3000)
  }, console.error)
}

export default getStats
