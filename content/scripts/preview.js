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
  }
});
