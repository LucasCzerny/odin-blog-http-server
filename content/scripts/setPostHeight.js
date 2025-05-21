window.addEventListener("message", event => {
  const iframes = document.querySelectorAll("iframe")

  for (let iframe of iframes) {
    if (iframe.contentWindow != event.source) {
      iframe.style.height = event.data.height + "px";
    }
  }
});
