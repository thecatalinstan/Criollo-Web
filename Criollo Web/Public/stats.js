import m from 'mithril'

const getStats = (vnode) => {
  m.request({method: "GET", url: `/api/info?${Math.random()}`}).map( (response) => {
    vnode.state.response = response
    window.setTimeout(() => { getStats(vnode) }, 3000)
    m.redraw()
  })
}

export default {
  view: (vnode) => {
    let response = vnode.state.response || {}
    if ( response.data ) {
      let memoryUsage = response.data.memoryInfo > 0 ? ` using ${response.data.memoryInfo} of memory` : ""
      return m('p', `${response.data.processName} ${response.data.processVersion}${memoryUsage}, running for ${response.data.runningTime} on ${response.data.unameSystemVersion}. Served ${response.data.requestsServed} requests.`)
    } else {
      return m('p')
    }
  },
  oninit: (vnode) => {
    getStats(vnode)
  }
}
