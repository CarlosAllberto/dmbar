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
    /* Cabeçalho de Pedidos de contato (seta do Instagram e título): a seta do DMBar substitui. */
    main div[role="navigation"] > div > div:has(> div > div[role="button"]):has(> span) { display: none !important; }
    /* Faixa para a seta não cobrir o primeiro item dos Pedidos. */
    html[data-dmbar-back] main div[role="navigation"] > div { padding-top: 44px !important; box-sizing: border-box !important; }

    /* Sem fundo de hover nas conversas. Vale só para div: o ponto verde de online é span e mantém a cor. */
    main div[role="navigation"] div:hover { background-color: transparent !important; }

    /* Post ou reel aberto de uma DM: o modal limita o conteúdo a ~150px e o nome quebra letra por letra. */
    div[role="dialog"] > div > div,
    div[role="dialog"] > div > div > div,
    div[role="dialog"] article,
    div[role="dialog"] article > div { width: 100% !important; max-width: none !important; }
    /* Cabeçalho e ações na largura toda; a mídia ocupa o espaço que sobra e o vídeo mantém a proporção. */
    div[role="dialog"] article > div { display: flex !important; flex-direction: column !important; }
    div[role="dialog"] article > div > div:first-child,
    div[role="dialog"] article > div > div:last-child { width: 100% !important; height: auto !important; flex: none !important; }
    /* Só o bloco da mídia: forçar tamanho nos divs internos esticava também os controles de volume. */
    div[role="dialog"] article > div > div:nth-child(2) { width: 100% !important; max-width: none !important; }
    /* Modal colado no topo e no fim do popover, sem a faixa vazia em cima e embaixo. */
    div[role="dialog"] { height: 100vh !important; max-height: none !important; margin: 0 !important; }
    div[role="dialog"] div:has(article), div[role="dialog"] article, div[role="dialog"] article > div { height: 100% !important; max-height: none !important; }
    /* Menu "..." do post sai: o X de fechar do Instagram fica no lugar dele, no canto do cabeçalho. */
    div[role="dialog"] header + div { visibility: hidden !important; }
    /* A mídia ocupa o que sobra entre cabeçalho e ações. Antes ficava em 262px e o vídeo vazava por baixo das ações. */
    div[role="dialog"] article > div > div:nth-child(2) { flex: 1 1 0 !important; min-height: 0 !important; height: auto !important; max-height: none !important; overflow: hidden !important; }
    /* Só os divs que contêm o vídeo: o Instagram usa padding de proporção neles; os controles ficam de fora. */
    div[role="dialog"] article > div > div:nth-child(2) div:has(video) { height: 100% !important; padding: 0 !important; }
    div[role="dialog"] article > div > div:nth-child(2) video { width: 100% !important; height: 100% !important; object-fit: contain !important; }

    /* Barra de rolagem da página ocupava 17px à direita; o scroll por trackpad continua. */
    ::-webkit-scrollbar { width: 0 !important; height: 0 !important; }

    #dmbar-back { display: none; }
    html[data-dmbar-back] #dmbar-back {
        /* Sem os cabeçalhos, flutua sobre o conteúdo: o fundo garante leitura. */
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
        // Depois do login o Instagram cai no feed ("/"); o DMBar só mostra DMs.
        if (location.pathname === '/') { location.replace('/direct/inbox/'); return; }
        const mode = location.pathname.startsWith('/direct/t/') ? 'thread' : 'inbox';
        if (document.documentElement.dataset.dmbar !== mode) document.documentElement.dataset.dmbar = mode;
        // Seta de voltar em telas abaixo da inbox: conversa e Pedidos de contato.
        const sub = mode === 'thread' || location.pathname.startsWith('/direct/requests');
        document.documentElement.toggleAttribute('data-dmbar-back', sub);
        if (document.body && !document.getElementById('dmbar-back')) {
          const back = document.createElement('button');
          back.id = 'dmbar-back';
          back.textContent = '‹';
          back.setAttribute('aria-label', 'Voltar para a lista');
          // Vai sempre para a inbox: history.back() falhava depois de abrir um vídeo da conversa.
          // O link da barra escondida navega sem recarregar a página; sem ele, recarrega.
          back.onclick = () => {
            const link = document.querySelector('a[href="/direct/inbox/"]');
            link ? link.click() : location.assign('/direct/inbox/');
          };
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

    #if DEBUG
    /// Modo demo para prints do README (DMBAR_DEMO=1): troca nomes, fotos e mensagens reais por dados fictícios.
    /// O mesmo texto original vira sempre o mesmo texto falso, então o nome bate entre lista e conversa.
    static let demoJS = """
    (function () {
      const names = ['Ana Ribeiro', 'Lucas Martins', 'Bia Costa', 'Rafa Souza', 'Duda Lima', 'Pedro Alves', 'Julia Rocha', 'Caio Nunes'];
      const texts = ['Bora café amanhã?', 'Mandei o arquivo agora', 'Kkkk muito bom', 'Chego em 10 min', 'Valeu! 🙌',
        'Viu o jogo ontem?', 'Fechado, combinado', 'Me liga quando puder', 'Que foto linda!', 'Tô saindo agora'];
      const photos = \(jsonArray(DemoAvatars.dataURIs));
      // Textos da interface do Instagram que ficam como estão.
      const keep = /^(Primary|Principal|General|Geral|Pedidos|Requests?|Pesquisar|Search|Mensagem|Message|Ver perfil|View profile|Seguir|Follow|Delete all|Visto|Seen|Hoje|Today|Ontem|Yesterday|Você|You|·|\\s*)$|^(Pedidos|Requests?) \\(\\d+\\)$|^\\d+\\s*(s|min|h|d|sem|w)$|^(há|visto|seen|enviad|sent)|(\\.\\.\\.|…)$/i;
      const map = new Map();
      let n = 0, t = 0;
      const fake = (orig, isName) => {
        if (!map.has(orig)) map.set(orig, isName ? names[n++ % names.length] : texts[t++ % texts.length]);
        return map.get(orig);
      };
      // A foto segue o nome falso mais próximo (linha da lista ou conversa), para nome e rosto baterem.
      function photoFor(img, main) {
        const scope = img.closest('div[role="button"]') || main;
        const name = textNodes(scope).map(n => n.nodeValue).find(v => names.includes(v));
        return photos[(name ? names.indexOf(name) : 0) % photos.length];
      }
      function textNodes(root) {
        const out = [], walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) if (walker.currentNode.nodeValue.trim()) out.push(walker.currentNode);
        return out;
      }
      const faked = new WeakSet();
      function swap(node, isName) {
        if (faked.has(node) || keep.test(node.nodeValue.trim())) return;
        node.nodeValue = fake(node.nodeValue.trim(), isName);
        faked.add(node);
      }
      function run() {
        const main = document.querySelector('main');
        if (!main) return;
        // Na lista, o primeiro texto de cada conversa é o nome.
        main.querySelectorAll('div[role="navigation"] div[role="button"]').forEach(row => {
          textNodes(row).forEach((node, i) => swap(node, i === 0));
        });
        // Nomes (h2, links de perfil) primeiro, para baterem com a lista; o resto vira mensagem.
        main.querySelectorAll('h2, a[href^="/"] span').forEach(el => textNodes(el).forEach(node => swap(node, true)));
        textNodes(main).forEach(node => swap(node, false));
        // React volta o src real a cada render, então a troca é conferida em todo ciclo.
        main.querySelectorAll('img').forEach(img => {
          const photo = photoFor(img, main);
          if (img.src !== photo) { img.removeAttribute('srcset'); img.src = photo; }
        });
        main.querySelectorAll('video').forEach(v => v.style.visibility = 'hidden');
      }
      setInterval(run, 300);
    })();
    """
    #endif

    static var userScript: WKUserScript {
        WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private static func jsonArray(_ items: [String]) -> String {
        String(data: try! JSONSerialization.data(withJSONObject: items), encoding: .utf8)!
    }

    private static func jsonString(_ s: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [s])
        return String(data: data, encoding: .utf8)!.dropFirst().dropLast().description
    }
}
