(function () {
  var navToggle = document.querySelector("[data-nav-toggle]");
  var siteNav = document.querySelector("[data-site-nav]");
  var dropdownTriggers = document.querySelectorAll("[data-dropdown-trigger]");
  var searchOpenBtn = document.querySelector("[data-search-open]");
  var searchOverlay = document.querySelector("[data-search-overlay]");
  var searchCloseEls = document.querySelectorAll("[data-search-close]");
  var searchInput = document.querySelector("[data-search-input]");
  var yearEl = document.querySelector("[data-year]");
  var slides = document.querySelectorAll("[data-hero-slide]");
  var dotsWrap = document.querySelector("[data-hero-dots]");
  var pauseBtn = document.querySelector("[data-hero-pause]");

  if (yearEl) {
    yearEl.textContent = String(new Date().getFullYear());
  }

  /* Mobile nav */
  if (navToggle && siteNav) {
    navToggle.addEventListener("click", function () {
      var open = siteNav.classList.toggle("is-open");
      navToggle.setAttribute("aria-expanded", open ? "true" : "false");
    });

    document.addEventListener("click", function (e) {
      if (!siteNav.classList.contains("is-open")) return;
      var t = e.target;
      if (t instanceof Node && !siteNav.contains(t) && !navToggle.contains(t)) {
        siteNav.classList.remove("is-open");
        navToggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  /* Dropdowns on mobile: click to toggle */
  dropdownTriggers.forEach(function (trigger) {
    var item = trigger.closest(".has-dropdown");
    var panel = item && item.querySelector("[data-dropdown-panel]");
    if (!item || !panel) return;

    trigger.addEventListener("click", function (e) {
      if (window.matchMedia("(min-width: 841px)").matches) return;
      e.preventDefault();
      var isOpen = item.classList.toggle("is-open");
      trigger.setAttribute("aria-expanded", isOpen ? "true" : "false");
    });
  });

  /* Reset mobile mega state when viewport crosses desktop breakpoint */
  dropdownTriggers.forEach(function (trigger) {
    var item = trigger.closest(".has-dropdown");
    var panel = item && item.querySelector("[data-dropdown-panel]");
    if (!panel) return;
    function syncDesktop() {
      if (window.matchMedia("(min-width: 841px)").matches) {
        item.classList.remove("is-open");
        trigger.setAttribute("aria-expanded", "false");
      }
    }
    syncDesktop();
    window.addEventListener("resize", syncDesktop);
  });

  /* Search overlay */
  function openSearch() {
    if (!searchOverlay) return;
    searchOverlay.hidden = false;
    document.body.style.overflow = "hidden";
    if (searchInput) {
      window.requestAnimationFrame(function () {
        searchInput.focus();
      });
    }
  }

  function closeSearch() {
    if (!searchOverlay) return;
    searchOverlay.hidden = true;
    document.body.style.overflow = "";
  }

  if (searchOpenBtn) {
    searchOpenBtn.addEventListener("click", openSearch);
  }

  searchCloseEls.forEach(function (el) {
    el.addEventListener("click", closeSearch);
  });

  document.addEventListener("keydown", function (e) {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
      e.preventDefault();
      if (searchOverlay && !searchOverlay.hidden) closeSearch();
      else openSearch();
    }
    if (e.key === "Escape" && searchOverlay && !searchOverlay.hidden) {
      closeSearch();
    }
  });

  /* Hero carousel */
  var index = 0;
  var timerId = null;
  var reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function setSlide(i) {
    index = (i + slides.length) % slides.length;
    slides.forEach(function (slide, j) {
      slide.classList.toggle("is-active", j === index);
    });
    if (dotsWrap) {
      var dots = dotsWrap.querySelectorAll(".hero__dot");
      dots.forEach(function (dot, j) {
        dot.setAttribute("aria-selected", j === index ? "true" : "false");
      });
    }
  }

  function buildDots() {
    if (!dotsWrap || !slides.length) return;
    dotsWrap.innerHTML = "";
    slides.forEach(function (_, i) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "hero__dot";
      btn.setAttribute("role", "tab");
      btn.setAttribute("aria-label", "Slide " + (i + 1));
      btn.addEventListener("click", function () {
        setSlide(i);
        restartTimer();
      });
      dotsWrap.appendChild(btn);
    });
    setSlide(0);
  }

  function stopTimer() {
    if (timerId) {
      window.clearInterval(timerId);
      timerId = null;
    }
  }

  function startTimer() {
    stopTimer();
    if (reducedMotion || slides.length < 2) return;
    timerId = window.setInterval(function () {
      setSlide(index + 1);
    }, 8000);
  }

  function restartTimer() {
    if (pauseBtn && pauseBtn.getAttribute("aria-pressed") === "true") return;
    startTimer();
  }

  buildDots();
  startTimer();

  if (pauseBtn) {
    pauseBtn.addEventListener("click", function () {
      var paused = pauseBtn.getAttribute("aria-pressed") === "true";
      if (paused) {
        pauseBtn.setAttribute("aria-pressed", "false");
        pauseBtn.textContent = "Pause";
        startTimer();
      } else {
        pauseBtn.setAttribute("aria-pressed", "true");
        pauseBtn.textContent = "Play";
        stopTimer();
      }
    });
  }
})();
