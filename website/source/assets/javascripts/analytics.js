document.addEventListener('turbolinks:load', function() {
  analytics.page()

  track('.downloads .download .details li a', function(el) {
    var version = el.dataset.version
    var os = el.dataset.os
    var arch = el.dataset.arch
    return {
      event: 'Download',
      category: 'Button',
      label: 'Vagrant | v' + version + ' | ' + os + ' | ' + arch,
      version: version,
      os: os,
      architecture: arch,
      product: 'vagrant'
    }
  })
})
