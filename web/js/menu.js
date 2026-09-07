const container = document.getElementById("container");

let compactEnabled = true;
let idleMs = 2500;
let expanded = true;
let optionCount = 0;
let idleTimer = null;

function clearIdle() {
  clearTimeout(idleTimer);
  idleTimer = null;
}

function isHolding() {
  return document.getElementById("interact-container")?.classList.contains("is-holding");
}

export function isCompactTarget() {
  return compactEnabled && optionCount > 1;
}

export function isMenuOpen() {
  return !isCompactTarget() || expanded;
}

export function setMenuConfig(config = {}) {
  if (config.compact != null) compactEnabled = !!config.compact;
  if (config.idleMs != null) {
    const next = Number(config.idleMs);
    idleMs = Number.isFinite(next) ? Math.max(500, next) : 2500;
  }
  if (!isCompactTarget()) {
    expanded = true;
    clearIdle();
  }
  sync();
}

export function setOptionCount(count, { reset = false } = {}) {
  optionCount = count;

  if (!isCompactTarget()) {
    expanded = true;
    clearIdle();
  } else if (reset) {
    expanded = false;
    clearIdle();
    container.classList.remove("is-ready");
  }

  sync();
}

export function tryOpenMenu() {
  if (!isCompactTarget() || expanded) return false;
  expanded = true;
  sync();
  bumpIdle();
  return true;
}

export function closeMenu() {
  if (!isCompactTarget()) return false;
  expanded = false;
  clearIdle();
  sync();
  return true;
}

export function bumpIdle() {
  clearIdle();
  if (!isCompactTarget() || !expanded) return;

  idleTimer = window.setTimeout(() => {
    if (isHolding()) {
      bumpIdle();
      return;
    }
    closeMenu();
    container.dispatchEvent(new CustomEvent("menu-collapsed"));
  }, idleMs);
}

function sync() {
  const compact = isCompactTarget();
  container.classList.toggle("is-compact", compact);
  container.classList.toggle("is-open", isMenuOpen());
  requestAnimationFrame(() => {
    container.classList.add("is-ready");
  });
}
