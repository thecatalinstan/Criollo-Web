import $ from 'jquery'
import hljs from 'highlight.js'

hljs.initHighlightingOnLoad()

const getInfo = _ => {
  $.ajax({
    dataType: 'text',
    url: '/info'
  }).done((text) => {
    $($('.process-info .content p')[0]).text(text)
    setTimeout(getInfo, 3000)
  })
}

$(document).ready(_ => {
  getInfo()
})
