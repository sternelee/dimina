// Keep focus observation in the native container: DOM focus alone does not ask ArkWeb to show the IME.
export const DMP_KEYBOARD_FOCUS_SCRIPT: string = `(() => {
  if (window.__diminaKeyboardFocus) return;
  const state = window.__diminaKeyboardFocus = { revision: 0 };
  document.addEventListener('focusin', () => {
    state.revision++;
    DiminaRenderBridge.requestKeyboard(state.revision);
  }, true);
  document.addEventListener('focusout', () => { state.revision++; }, true);
})();`;

export function keyboardFocusCheck(revision: number): string {
  return `(() => {
    const e = document.activeElement;
    if (window.__diminaKeyboardFocus?.revision !== ${revision} || !document.hasFocus()
      || !e || !e.isConnected || e.disabled || e.readOnly || e.inputMode === 'none'
      || !e.getClientRects().length) return false;
    return e.tagName === 'TEXTAREA' || (e.tagName === 'INPUT'
      && ['text', 'search', 'email', 'url', 'tel', 'password', 'number'].includes(e.type));
  })()`;
}
