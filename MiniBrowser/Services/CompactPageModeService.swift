import WebKit

enum CompactPageModeService {
    static let scriptSource = #"""
    (() => {
      "use strict";

      if (location.hostname !== "img.2chan.net" ||
          !/^\/[^/]+\/res\/\d+\.htm$/.test(location.pathname)) {
        return;
      }

      const doc = document;
      const thread = doc.querySelector("div.thre");
      const form = Array.from(doc.forms).find(candidate =>
        candidate.querySelector('textarea[name="com"]')
      );
      if (!thread || !form) return;

      let viewport = doc.querySelector('meta[name="viewport"]');
      if (!viewport) {
        viewport = doc.createElement("meta");
        viewport.name = "viewport";
        doc.head.appendChild(viewport);
      }
      viewport.content = "width=device-width, initial-scale=1";

      if (!doc.getElementById("minibrowser-targetpage-style")) {
        const style = doc.createElement("style");
        style.id = "minibrowser-targetpage-style";
        style.textContent = `
          html, body {
            width: 100% !important;
            min-width: 0 !important;
            max-width: 100% !important;
            overflow-x: hidden !important;
            box-sizing: border-box !important;
          }
          body {
            margin: 0 !important;
            padding: 0 4px !important;
          }
          #minibrowser-targetpage-compose {
            display: grid !important;
            grid-template-columns: minmax(88px, 30vw) minmax(0, 1fr) !important;
            gap: 8px !important;
            align-items: start !important;
            width: 100% !important;
            box-sizing: border-box !important;
            margin: 4px 0 8px !important;
          }
          #minibrowser-targetpage-compose.minibrowser-no-context {
            grid-template-columns: minmax(0, 1fr) !important;
          }
          #minibrowser-targetpage-context {
            display: flex !important;
            flex-direction: column !important;
            gap: 6px !important;
            width: 100% !important;
            min-width: 0 !important;
            box-sizing: border-box !important;
          }
          #minibrowser-targetpage-starter {
            display: block !important;
            width: 100% !important;
            margin: 0 !important;
          }
          #minibrowser-targetpage-starter img {
            display: block !important;
            width: 100% !important;
            max-width: 100% !important;
            height: auto !important;
            max-height: 180px !important;
            margin: 0 !important;
            object-fit: contain !important;
          }
          #minibrowser-targetpage-opener {
            display: -webkit-box !important;
            width: 100% !important;
            max-width: 100% !important;
            margin: 0 !important;
            padding: 6px !important;
            border: 1px solid rgba(128, 64, 48, 0.35) !important;
            background: rgba(255, 255, 255, 0.45) !important;
            color: inherit !important;
            box-sizing: border-box !important;
            font-size: 14px !important;
            line-height: 1.35 !important;
            overflow: hidden !important;
            overflow-wrap: anywhere !important;
            -webkit-box-orient: vertical !important;
            -webkit-line-clamp: 4 !important;
          }
          .minibrowser-targetpage-form {
            position: static !important;
            display: block !important;
            visibility: visible !important;
            width: 100% !important;
            min-width: 0 !important;
            margin: 0 !important;
            box-sizing: border-box !important;
          }
          .minibrowser-targetpage-form .ftbl,
          .minibrowser-targetpage-form table.ftbl {
            position: static !important;
            width: 100% !important;
            min-width: 0 !important;
            margin: 0 !important;
            box-sizing: border-box !important;
          }
          .minibrowser-targetpage-form .ftdc {
            width: 4.5em !important;
            white-space: normal !important;
          }
          .minibrowser-targetpage-form textarea,
          .minibrowser-targetpage-form input[type="text"],
          .minibrowser-targetpage-form input[type="password"],
          .minibrowser-targetpage-form input[type="file"],
          .minibrowser-targetpage-form select {
            max-width: 100% !important;
            box-sizing: border-box !important;
            font-size: 16px !important;
          }
          .minibrowser-targetpage-form textarea,
          .minibrowser-targetpage-form input[type="text"] {
            width: 100% !important;
          }
          .minibrowser-targetpage-form .ftb2 {
            display: none !important;
          }
          .minibrowser-targetpage-thread-extra {
            display: none !important;
          }
          .minibrowser-targetpage-page-extra,
          #hdp,
          #contres,
          #ufm {
            display: none !important;
          }
          div.thre {
            width: 100% !important;
            min-width: 0 !important;
            margin: 0 !important;
            font-size: 0 !important;
            line-height: 0 !important;
          }
          div.thre > table {
            display: none !important;
          }
          div.thre > table.minibrowser-own-response {
            display: table !important;
            width: 100% !important;
            max-width: 100% !important;
            margin: 4px 0 !important;
            font-size: 14px !important;
            line-height: normal !important;
            table-layout: fixed !important;
          }
          div.thre > table.minibrowser-own-response .rtd,
          div.thre > table.minibrowser-own-response blockquote {
            max-width: 100% !important;
            overflow-wrap: anywhere !important;
            box-sizing: border-box !important;
          }
          div.thre > table.minibrowser-own-response img {
            max-width: 100% !important;
            height: auto !important;
          }
        `;
        doc.head.appendChild(style);
      }

      form.classList.add("minibrowser-targetpage-form");
      const infoTable = form.querySelector(".ftb2");
      if (infoTable) infoTable.setAttribute("aria-hidden", "true");

      function previousModeHeader(element) {
        let candidate = element.previousElementSibling;
        while (candidate) {
          if (candidate.tagName === "TABLE" &&
              /レス送信モード/.test(candidate.textContent || "")) {
            return candidate;
          }
          candidate = candidate.previousElementSibling;
        }
        return null;
      }

      function hideRange(first, stopExclusive = null) {
        let element = first;
        while (element && element !== stopExclusive) {
          const next = element.nextElementSibling;
          element.classList.add("minibrowser-targetpage-page-extra");
          element = next;
        }
      }

      const modeHeader = previousModeHeader(form);

      let compose = doc.getElementById("minibrowser-targetpage-compose");
      if (!compose) {
        compose = doc.createElement("div");
        compose.id = "minibrowser-targetpage-compose";
        form.parentNode.insertBefore(compose, form);

        const starterLink = Array.from(thread.children).find(element =>
          element.tagName === "A" && element.querySelector("img")
        );
        const opener = Array.from(thread.children).find(element =>
          element.tagName === "BLOCKQUOTE"
        );

        if (starterLink || opener) {
          const context = doc.createElement("div");
          context.id = "minibrowser-targetpage-context";
          compose.appendChild(context);

          if (starterLink) {
            starterLink.id = "minibrowser-targetpage-starter";
            context.appendChild(starterLink);
          }

          if (opener) {
            opener.id = "minibrowser-targetpage-opener";
            context.appendChild(opener);
          } else {
            const placeholder = doc.createElement("div");
            placeholder.id = "minibrowser-targetpage-opener";
            placeholder.textContent = "本文なし";
            context.appendChild(placeholder);
          }
        } else {
          compose.classList.add("minibrowser-no-context");
        }

        compose.appendChild(form);
      }

      if (modeHeader && modeHeader.parentElement === doc.body) {
        hideRange(doc.body.firstElementChild, modeHeader);
      }
      if (compose.parentElement === doc.body && thread.parentElement === doc.body) {
        hideRange(compose.nextElementSibling, thread);
        hideRange(thread.nextElementSibling);
      }

      Array.from(thread.children).forEach(element => {
        if (element.tagName !== "TABLE") {
          element.classList.add("minibrowser-targetpage-thread-extra");
        }
      });

      const storageKey = "MiniBrowser.TargetPageOwnPosts:" + location.pathname;
      const pendingStorageKey = "MiniBrowser.TargetPagePendingPost:" + location.pathname;
      const defaultImageComments = new Set([
        "ｷﾀ━━━(ﾟ∀ﾟ)━━━!!",
        "ｷﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!!",
        "本文無し"
      ]);

      function normalizedText(value) {
        return String(value || "")
          .replace(/\r\n?/g, "\n")
          .replace(/[ \t]+$/gm, "")
          .trim();
      }

      function loadState() {
        try {
          const parsed = JSON.parse(localStorage.getItem(storageKey) || "{}");
          const pending = JSON.parse(sessionStorage.getItem(pendingStorageKey) || "[]");
          return {
            ownNumbers: Array.isArray(parsed.ownNumbers) ? parsed.ownNumbers.map(String) : [],
            pending: Array.isArray(pending) ? pending : []
          };
        } catch (_) {
          return { ownNumbers: [], pending: [] };
        }
      }

      function saveState(state) {
        try {
          localStorage.setItem(storageKey, JSON.stringify({ ownNumbers: state.ownNumbers }));
          if (state.pending.length) {
            sessionStorage.setItem(pendingStorageKey, JSON.stringify(state.pending));
          } else {
            sessionStorage.removeItem(pendingStorageKey);
          }
        } catch (_) {}
      }

      function responseInfo(table) {
        const deletionMarker = table.querySelector('[id^="delcheck"]');
        const numberFromID = deletionMarker && deletionMarker.id.match(/^delcheck(\d+)$/);
        const textMarker = table.querySelector(".cno, .no_quote");
        const numberFromText = textMarker && textMarker.textContent.match(/(\d+)$/);
        const match = numberFromID || numberFromText;
        const blockquote = table.querySelector(".rtd blockquote, blockquote");
        if (!match || !blockquote) return null;
        return {
          table,
          number: match[1],
          numericNumber: Number(match[1]),
          body: normalizedText(blockquote.innerText || blockquote.textContent)
        };
      }

      function responseInfos() {
        return Array.from(thread.children)
          .filter(element => element.tagName === "TABLE")
          .map(responseInfo)
          .filter(Boolean);
      }

      let state = loadState();

      function reconcileAndRender() {
        const infos = responseInfos();
        const own = new Set(state.ownNumbers.map(String));
        const now = Date.now();
        const remaining = [];

        state.pending.forEach(pending => {
          if (!pending || now - Number(pending.createdAt || 0) > 10 * 60 * 1000) return;
          const body = normalizedText(pending.body);
          const candidates = infos.filter(info => {
            if (own.has(info.number) || info.numericNumber <= Number(pending.afterNumber || 0)) {
              return false;
            }
            return body ? info.body === body : defaultImageComments.has(info.body);
          });
          const match = candidates.sort((a, b) => a.numericNumber - b.numericNumber).pop();
          if (match) {
            own.add(match.number);
          } else {
            remaining.push(pending);
          }
        });

        state.ownNumbers = Array.from(own);
        state.pending = remaining;
        saveState(state);

        infos.forEach(info => {
          info.table.classList.toggle("minibrowser-own-response", own.has(info.number));
        });
      }

      if (!form.dataset.minibrowserOwnPostTracking) {
        form.dataset.minibrowserOwnPostTracking = "true";
        let lastRecordedAt = 0;
        const recordPendingPost = () => {
          const now = Date.now();
          if (now - lastRecordedAt < 1000) return;
          lastRecordedAt = now;
          const infos = responseInfos();
          const afterNumber = infos.reduce((maximum, info) =>
            Math.max(maximum, info.numericNumber), 0
          );
          const textarea = form.querySelector('textarea[name="com"]');
          state.pending.push({
            body: normalizedText(textarea && textarea.value),
            afterNumber,
            createdAt: now
          });
          state.pending = state.pending.slice(-10);
          saveState(state);
        };
        form.addEventListener("submit", recordPendingPost, true);
        const submitButton = Array.from(form.querySelectorAll(
          'input[type="submit"], button[type="submit"]'
        )).find(button => /返信|送信/.test(button.value || button.textContent || ""));
        if (submitButton) {
          submitButton.addEventListener("click", recordPendingPost, true);
        }
      }

      reconcileAndRender();
      const observer = new MutationObserver(() => reconcileAndRender());
      observer.observe(thread, { childList: true, subtree: true });
    })();
    """#

    static func install(on controller: WKUserContentController) {
        controller.addUserScript(WKUserScript(source: scriptSource,
                                              injectionTime: .atDocumentEnd,
                                              forMainFrameOnly: true))
    }
}
