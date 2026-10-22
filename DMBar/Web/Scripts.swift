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
    /* height: a conversa também descontava os 50px da barra, o que sobrava vazio abaixo do campo de mensagem. */
    html[data-dmbar="thread"] main div:has(> div[role="navigation"]) > :not([role="navigation"]) { width: 100% !important; max-width: none !important; flex: 1 1 auto !important; height: 100% !important; }
    /* Lista, pedidos e conversa têm altura própria (100vh - 50px), não herdada: precisa do caminho exato. */
    main > section > div > div > div > div { height: 100vh !important; max-height: none !important; }
    main div[role="navigation"], main div[role="navigation"] > div { height: 100% !important; max-height: none !important; }
    /* Cabeçalho da conversa (foto, nome, ligar, vídeo, info). */
    html[data-dmbar="thread"] main div:has(> div > div > div > a[role="link"] h2) { display: none !important; }

    /* Cabeçalho da lista (nome da conta e botão de nova mensagem) e a faixa de Notas. */
    main div[role="navigation"] > div > div:has(> div[role="button"] h2) { display: none !important; }
    main div[role="navigation"] div:has(> div > div[role="presentation"]) { display: none !important; }

    /* Barra de rolagem da página ocupava 17px à direita; o scroll por trackpad continua. */
    ::-webkit-scrollbar { width: 0 !important; height: 0 !important; }

    #dmbar-back { display: none; }
    html[data-dmbar="thread"] #dmbar-back {
        /* Sem o cabeçalho da conversa, flutua sobre as mensagens: o fundo garante leitura. */
        display: block; position: fixed; top: 8px; left: 8px; z-index: 99999;
        width: 28px; height: 28px; padding: 0 0 3px; border: 0; border-radius: 14px;
        background: rgba(128,128,128,.35); color: inherit; font-size: 22px; line-height: 22px; cursor: pointer;
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
