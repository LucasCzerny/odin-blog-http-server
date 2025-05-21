window.addEventListener('DOMContentLoaded', () => {
  if (window.self !== window.top) {
    const body = document.body;
    const paragraphs = body.querySelectorAll('p');

    if (paragraphs.length >= 2) {
      const secondP = paragraphs[1];

      let next = secondP.nextSibling;
      while (next) {
        const toRemove = next;
        next = next.nextSibling;
        body.removeChild(toRemove);
      }
    }

    sendHeight();
  }
});

window.addEventListener("resize", () => {
  if (window.self !== window.top) {
    sendHeight();
  }
});

function sendHeight() {
  console.log("sending that bish")
  
  const height = document.body.scrollHeight + 10;
  parent.postMessage({type: "setHeight", height: height}, "*")
}
