import $ from 'jquery'

const getInfo = () => {
  $.ajax({
    dataType: 'text',
    url: `/info?${Math.random()}`
  }).done((text) => {
    $($('.process-info .content p')[0]).text(text)
    window.setTimeout(getInfo, 3000)
  })
}
export default {
  getInfo: getInfo
}
