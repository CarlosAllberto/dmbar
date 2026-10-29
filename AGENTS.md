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

O backlog fica no Linear: workspace "Carlos Alberto", time `CAR`, projeto `DMBar` (use `orca linear`, skill `orca-linear`). Toda issue deste repositório entra no projeto `DMBar`, nunca solta no time, para não misturar com outros projetos. Tipo pela label (`Feature`, `Improvement`, `Bug`). Estados: Backlog = ideia, Todo = próximo, In Progress = agora, Done = feito.

O checklist da tarefa atual fica na descrição da própria issue, numa seção `## Etapas` com itens `- [ ]`. Atualize a descrição com `orca linear save-issue CAR-<n> --body-file -` (a descrição é substituída inteira: leia antes com `orca linear issue CAR-<n> --full --json` e preserve o resto).

Em tarefas com várias etapas:
- Antes de começar, crie ou ache a issue, escreva as etapas em `## Etapas` e passe a issue para In Progress.
- Marque cada item assim que terminar e acrescente o que descobrir no caminho.
- Se a conversa for resumida ou você perder o fio, releia a issue In Progress antes de continuar.
- Ao concluir, passe a issue para Done.
- Trabalho novo fora do escopo vira issue nova em Todo no projeto `DMBar`, sem ser resolvido na hora.
- Nunca apague nem cancele issues sem eu pedir.
- Antes de dizer que terminou, rode build e testes e informe o resultado.

Tarefa de um passo só não precisa de checklist.

Ao terminar cada tarefa, organize o resumo em três títulos: Travado em mim, O que mudou, O que encontrei.
