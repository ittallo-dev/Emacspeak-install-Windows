# Emacspeak & GNU Emacs - Instalador Nativo para Windows

Este repositório fornece uma solução de automação robusta para instalar e integrar o **Emacspeak** com o **GNU Emacs** de forma nativa no ambiente Windows. 

O script foi projetado para ser executado em modo *zero-touch*: ele analisa o seu sistema operacional, seleciona a melhor ferramenta para gerenciar os pacotes, resolve dependências (incluindo o próprio editor), clona repositórios e realiza validações de integridade física em tempo de execução para garantir que seu ambiente de áudio seja configurado perfeitamente.

---

## O que este script faz? (Visão Geral)

O fluxo de execução do script divide-se em 6 etapas sequenciais e auto-validadas:

### 1. Detecção de SO e Instalação de Pré-requisitos
O script identifica a versão do seu Windows para definir a melhor estratégia de download:
* **Windows 10 e 11:** Utiliza o gerenciador nativo **Winget**.
* **Windows 7, 8 e 8.1:** Realiza a instalação automática e silenciosa do gerenciador **Chocolatey**.
* **Instalação e Validação de Dependências:** O script instala silenciosamente as ferramentas fundamentais (caso elas já não estejam presentes no sistema): **GNU Emacs**, **Git** e **.NET SDK**. Caso a inclusão dessas ferramentas na variável de ambiente local (`PATH`) falhe, o instalador aplica um *Bypass Universal*, mapeando fisicamente os executáveis para não travar o processo.

### 2. Mapeamento Dinâmico de Diretórios
O script cria variáveis de ambiente na sessão atual e mapeia onde os arquivos de configuração serão salvos, gerando caminhos de forma dinâmica na pasta do usuário (ex: `~/.emacs.d/`) para evitar conflitos de caminhos estáticos ou problemas de permissão.

### 3. Sincronização e Validação do Código-Fonte
Clona as versões mais recentes dos repositórios oficiais:
* **[Emacspeak](https://github.com/tvraman/emacspeak)** (núcleo do leitor de tela).
* **[SharpWin](https://github.com/robertmeta/sharpwin)** (servidor de áudio em C# para Windows).
* **Validação de Integridade:** Após clonar, o script checa fisicamente se os arquivos estruturais e os metadados do Git (`.git`) estão íntegros no disco.

### 4. Compilação Independente do Servidor de Voz
Invocando o compilador do `.NET SDK` recém-instalado, o instalador compila o SharpWin gerando um executável único e autônomo (`sharpwin.exe`). Ele empacota todas as dependências de áudio nativas do Windows (`System.Speech`) de forma isolada, sem poluir seu sistema global. 

### 5. Geração de Autoloads (Emacs Batch Mode)
O script inicia o binário do GNU Emacs em segundo plano (*Batch Mode*) para forçar a leitura rápida do diretório `lisp` do Emacspeak e compilar o arquivo de carregamento estrutural `emacspeak-loaddefs.el`. 

### 6. Configuração Modular Inteligente do `init.el`
O instalador gera o arquivo de inicialização do seu editor (`~/.emacs.d/init.el`) injetando a lógica necessária para o ambiente Windows, que resolve:
* O uso de **Pipes** (`process-connection-type nil`) para a troca rápida de dados entre o Emacs e o Servidor de Voz.
* Codificação compatível (`utf-8-dos`) para evitar erros de leitura de caracteres.
* **Módulo de Acessibilidade:** Baixa automaticamente deste repositório o arquivo `init-accessibility.el` e o injeta com caminhos absolutos, garantindo uma inicialização limpa e livre de avisos de segurança do Emacs.

---

## Módulo de Voz e Acessibilidade (`init-accessibility.el`)

O script baixa e configura um módulo avançado de usabilidade focado no usuário brasileiro, que inclui:
* Limpeza de processos zumbis ao fechar o editor.
* Anúncios automáticos ao salvar arquivos.
* **Alternância rápida de idiomas:** Pressione **`C-c t`** (Control+c, seguido de t) dentro do GNU Emacs para alternar instantaneamente entre a leitura em **Português do Brasil** e **Inglês**.

> **IMPORTANTE - Vozes Nativas do Windows:**
> O atalho de alternância de idioma faz chamadas diretas às vozes clássicas do Windows. Para que o atalho funcione corretamente, você **deve** ter os pacotes de voz instalados no seu sistema operacional. O script procura por:
> * `"Microsoft Maria Desktop"` (Para ler em Português).
> * `"Microsoft Zira Desktop"` (Para ler em Inglês).
> * *Nota: Caso o seu Windows utilize a voz masculina em português, você precisará editar o arquivo (C-x-C-f "init-accessibility.el") `init-accessibility.el` e alterar "Maria" para "Daniel".*

---

## Como Usar?

### Requisitos de Sistema
O script possui suporte nativo para máquinas físicas e virtuais rodando:
* **Windows 10 ou 11** (com suporte e atualização ativa do *App Installer/Winget*).
* **Windows 7, 8 ou 8.1** (o script configurará o *Chocolatey* automaticamente).

### Passo a Passo da Instalação:

**1.** Abra o menu Iniciar do Windows e digite **PowerShell**.
**2.** Clique com o botão direito sobre o ícone do PowerShell e escolha **Executar como Administrador** *(necessário para que os gerenciadores possam instalar e registrar os pacotes base no sistema)*.
**3.** Copie o comando abaixo, cole no seu terminal e pressione `Enter`:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iex (iwr '[https://raw.githubusercontent.com/ittallo-dev/Emacspeak-install-Windows/main/install-emacspeak.ps1](https://raw.githubusercontent.com/ittallo-dev/Emacspeak-install-Windows/main/install-emacspeak.ps1)' -UseBasicParsing).Content
