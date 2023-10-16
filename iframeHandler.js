console.log("Iframe script executed");
if (new URLSearchParams(window.location.search).get('iframe') === 'true') {
    document.body.setAttribute('data-iframe', 'true');
}
let iframeValue = document.body.getAttribute('data-iframe');
console.log("data-iframe attribute value:", iframeValue);
