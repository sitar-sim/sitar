/* sitar_download.js
 *
 * For each <div class="sitar-download-marker"> injected by the hook:
 *   1. Find the immediately following .highlight div (the rendered code block).
 *   2. Create a styled <a download> anchor.
 *   3. Append the anchor inside .highlight so it sits next to Material's copy button.
 *   4. Remove the now-empty marker div.
 */

function installDownloadButtons() {
  document.querySelectorAll("div.sitar-download-marker").forEach(function (marker) {
    var src   = marker.getAttribute("data-sitar-src");
    var fname = marker.getAttribute("data-fname");

    // Walk forward through siblings to find the next .highlight block.
    var el = marker.nextElementSibling;
    while (el && !el.classList.contains("highlight")) {
      el = el.nextElementSibling;
    }

    // Remove the marker regardless of whether we found a highlight block.
    marker.parentNode.removeChild(marker);

    if (!el) return;

    // Build the download anchor to match Material's copy-button style.
    var a = document.createElement("a");
    a.className = "sitar-download-btn md-icon";
    a.href      = src;
    a.setAttribute("download", fname);
    a.title     = "Download " + fname;
    el.appendChild(a);
  });
}

// Material re-renders content on SPA navigation via document$.
// Fall back to DOMContentLoaded for first load / non-Material builds.
if (typeof document$ !== "undefined") {
  document$.subscribe(installDownloadButtons);
} else {
  document.addEventListener("DOMContentLoaded", installDownloadButtons);
}
