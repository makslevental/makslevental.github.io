// Theme button (System -> Light -> Dark) and TOC current-section highlight.
(function () {
  var root = document.documentElement;

  //
  // Theme
  //
  var MODES = ['system', 'light', 'dark'];
  var ICONS = { system: '◐', light: '☀', dark: '☾' };
  var LABELS = { system: 'System', light: 'Light', dark: 'Dark' };

  function savedMode() {
    try {
      var t = localStorage.getItem('theme');
      return t === 'light' || t === 'dark' ? t : 'system';
    } catch (e) {
      return 'system';
    }
  }

  function applyMode(mode, button) {
    if (mode === 'system') delete root.dataset.theme;
    else root.dataset.theme = mode;

    try {
      if (mode === 'system') localStorage.removeItem('theme');
      else localStorage.setItem('theme', mode);
    } catch (e) {}

    if (button) {
      var label = 'Theme: ' + LABELS[mode];
      button.textContent = ICONS[mode];
      button.title = label;
      button.setAttribute('aria-label', label);
    }
  }

  var button = document.querySelector('.theme-toggle');
  if (button) {
    var mode = savedMode();
    applyMode(mode, button);
    button.hidden = false;
    button.addEventListener('click', function () {
      mode = MODES[(MODES.indexOf(mode) + 1) % MODES.length];
      applyMode(mode, button);
    });
  }

  //
  // TOC
  //
  var toc = document.querySelector('.toc');
  if (!toc) return;

  // Collapsed by default on narrow screens; the sidebar on wide screens ignores it.
  if (window.matchMedia('(max-width: 999px)').matches) toc.open = false;

  if (!('IntersectionObserver' in window)) return;

  var links = {};
  toc.querySelectorAll('a[href^="#"]').forEach(function (a) {
    links[decodeURIComponent(a.getAttribute('href').slice(1))] = a;
  });

  var headings = Array.prototype.filter.call(
    document.querySelectorAll('.entry h1[id], .entry h2[id]'),
    function (h) { return links[h.id]; }
  );
  if (!headings.length) return;

  var current = null;
  function setActive(id) {
    if (current === id) return;
    if (current && links[current]) links[current].classList.remove('active');
    current = id;
    links[id].classList.add('active');
  }

  // The active section is the last heading that has scrolled above 30% of the viewport.
  function update() {
    var line = window.innerHeight * 0.3;
    var active = headings[0];
    for (var i = 0; i < headings.length; i++) {
      if (headings[i].getBoundingClientRect().top <= line) active = headings[i];
      else break;
    }
    setActive(active.id);
  }

  var observer = new IntersectionObserver(update, { rootMargin: '0px 0px -70% 0px' });
  headings.forEach(function (h) { observer.observe(h); });
  update();
})();
