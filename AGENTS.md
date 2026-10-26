# AGENTS.md

DMBar: app de barra de menus do macOS (Swift, sem dependências) que mostra só as DMs do Instagram num `WKWebView`.

## Comandos

- Instalar ferramenta: `brew install xcodegen`
- Gerar o projeto: `xcodegen generate` (rode de novo ao criar ou remover arquivos)
- Build: `xcodebuild -project DMBar.xcodeproj -scheme DMBar -configuration Release -derivedDataPath build build`
- Rodar: abrir `build/Build/Products/Release/DMBar.app`, ou o scheme `DMBar` no Xcode
- Testes: o projeto ainda não tem alvo de testes

## Convenções

- O `DMBar.xcodeproj` é gerado a partir do `project.yml` e não vai para o git.
- Sem dependências externas: use AppKit, SwiftUI, WebKit e Carbon.
- A interface do app é em português; README em inglês com versão `README.pt-BR.md`.
- Seletores de CSS e JS do Instagram ficam em `DMBar/Web/Scripts.swift`.
- Commits no formato `tipo: descrição` em inglês (`feat`, `fix`, `docs`, `chore`, `ci`).

## Lista de tarefas

O arquivo TASKS.md na raiz tem o backlog do projeto (Agora, Próximo, Ideias, Feito) e uma seção "Em execução" para o checklist da tarefa atual.

Em tarefas com várias etapas:
- Antes de começar, liste as etapas em "Em execução".
- Marque cada item assim que terminar e acrescente o que descobrir no caminho.
- Se a conversa for resumida ou você perder o fio, leia o TASKS.md antes de continuar.
- Ao concluir, mova o item de "Agora" para "Feito" e limpe "Em execução".
- Trabalho novo fora do escopo entra em "Próximo", sem ser resolvido na hora.
- Nunca apague itens sem eu pedir.
- Antes de dizer que terminou, rode build e testes e informe o resultado.

Tarefa de um passo só não precisa de checklist.

Ao terminar cada tarefa, organize o resumo em três títulos: Travado em mim, O que mudou, O que encontrei.
