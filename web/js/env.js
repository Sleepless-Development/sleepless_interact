export function isEnvBrowser() {
  if (typeof window.invokeNative === "function") return false;

  const href = String(window.location.href);
  if (href.startsWith("nui://") || href.includes("cfx-nui-")) return false;

  const protocol = window.location.protocol;
  return protocol === "http:" || protocol === "https:" || protocol === "file:";
}
