import WebKit

enum Scripts {
    /// Seletores tirados do DOM real da inbox (out 2026). Instagram muda o HTML sem aviso;
    /// se a tela voltar a mostrar feed ou barra de navegação, revisar aqui primeiro.
    static let css = """
    /* Barra de ícones do Instagram (home, explorar, reels, perfil): é a irmã anterior do conteúdo principal. */
    div:has(+ div > section > main[role="main"]) { display: none !important; }

    /* Lista e conversa lado a lado não cabem em 380px: mostra uma de cada vez. */
    /* A altura original desconta os 50px da barra escondida acima. */
    main div:has(> div[role="navigation"]) { display: flex !important; height: 100vh !important; }
    html[data-dmbar="inbox"] main div:has(> div[role="navigation"]) > :not([role="navigation"]) { display: none !important; }
    html[data-dmbar="inbox"] main div[role="navigation"],
    html[data-dmbar="inbox"] main div[role="navigation"] > div {
        width: 100% !important; max-width: none !important; flex: 1 1 auto !important; border: 0 !important;
    }
    html[data-dmbar="thread"] main div:has(> div[role="navigation"]) > div[role="navigation"] { display: none !important; }
    html[data-dmbar="thread"] main div:has(> div[role="navigation"]) > :not([role="navigation"]) { width: 100% !important; max-width: none !important; flex: 1 1 auto !important; }

    /* Barra de rolagem da página ocupava 17px à direita; o scroll por trackpad continua. */
    ::-webkit-scrollbar { width: 0 !important; height: 0 !important; }

    #dmbar-back { display: none; }
    html[data-dmbar="thread"] #dmbar-back {
        /* Cabe na margem de ~20px à esquerda do avatar do cabeçalho da conversa. */
        display: block; position: fixed; top: 22px; left: 2px; z-index: 99999;
        width: 18px; height: 32px; padding: 0; border: 0;
        background: none; color: inherit; font-size: 26px; line-height: 26px; cursor: pointer;
    }
    """

    static let js = """
    (function () {
      const style = document.createElement('style');
      style.textContent = \(jsonString(css));
      document.documentElement.appendChild(style);

      // Instagram é SPA: a URL muda sem recarregar, então o modo é conferido em loop.
      function update() {
        const mode = location.pathname.startsWith('/direct/t/') ? 'thread' : 'inbox';
        if (document.documentElement.dataset.dmbar !== mode) document.documentElement.dataset.dmbar = mode;
        if (document.body && !document.getElementById('dmbar-back')) {
          const back = document.createElement('button');
          back.id = 'dmbar-back';
          back.textContent = '‹';
          back.setAttribute('aria-label', 'Voltar para a lista');
          back.onclick = () => history.length > 1 ? history.back() : location.assign('/direct/inbox/');
          document.body.appendChild(back);
        }
        // Três fontes, porque nenhuma cobre tudo: título "(3) ...", badge no ícone de DMs da barra
        // escondida (textContent ainda funciona com display:none) e abas como "Request (1)".
        const num = (text, re) => { const m = (text || '').match(re); return m ? Number(m[1]) : 0; };
        const title = num(document.title, /^\\((\\d+)\\)/);
        const nav = num(document.querySelector('a[href="/direct/inbox/"]')?.textContent, /(\\d+)/);
        const tabs = [...document.querySelectorAll('main [role="tab"]')]
          .reduce((sum, tab) => sum + num(tab.textContent, /\\((\\d+)\\)/), 0);
        // Máximo, não soma: as fontes podem contar a mesma conversa.
        const count = Math.max(title, nav, tabs);
        const sources = title + '/' + nav + '/' + tabs;
        if (sources !== lastSources) {
          lastSources = sources;
          window.webkit.messageHandlers.unread.postMessage({ count: count, title: document.title + ' t/n/a=' + sources });
        }
      }
      let lastSources = null;
      update();
      setInterval(update, 300);
    })();
    """

    static var userScript: WKUserScript {
        WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private static func jsonString(_ s: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [s])
        return String(data: data, encoding: .utf8)!.dropFirst().dropLast().description
    }
}
