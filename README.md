# Emacspeak & GNU Emacs - Instalador Nativo para Windows

Este repositório fornece uma solução de automação robusta para instalar e integrar o **Emacspeak** com o **GNU Emacs** de forma nativa no ambiente Windows. 

O script foi projetado para ser executado em modo *zero-touch*: ele analisa o seu sistema operacional, seleciona a melhor ferramenta para gerenciar os pacotes, resolve dependências, clona repositórios e realiza validações de integridade física em tempo de execução para garantir que seu ambiente de áudio seja configurado perfeitamente.

---

## 🚀 O que este script faz? (Visão Geral do Processo)

O fluxo de execução do script divide-se em 6 etapas sequenciais e auto-validadas:

### 1. Detecção do Sistema Operacional e Instalação de Pré-requisitos
O script identifica a versão do seu Windows para definir a melhor estratégia de download:
* **Windows 10 e 11:** Utiliza o gerenciador nativo **Winget**.
* **Windows 7, 8 e 8.1:** Realiza a instalação automática e silenciosa do gerenciador **Chocolatey**.
* **Instalação e Validação de Dependências:** O script instala silenciosamente as ferramentas fundamentais: **GNU Emacs**, **Git** e **.NET SDK 8.0**. Caso a inclusão dessas ferramentas na variável de ambiente local (`PATH`) falhe, o instalador aplica um *Bypass Universal*, mapeando fisicamente os executáveis para não travar o processo.

### 2. Mapeamento Dinâmico de Diretórios
O script cria variáveis de ambiente na sessão atual e mapeia onde os arquivos de configuração serão salvos, gerando caminhos de forma dinâmica na pasta do usuário para evitar conflitos de caminhos estáticos.

### 3. Sincronização e Validação do Código-Fonte
Clona as versões mais recentes dos repositórios oficiais:
* **[Emacspeak](https://github.com/tvraman/emacspeak)** (núcleo do leitor de tela).
* **[SharpWin](https://github.com/robertmeta/sharpwin)** (servidor de áudio em C# para Windows).
* **Validação de Integridade:** Após clonar, o script checa fisicamente se os arquivos estruturais e os metadados do Git (`.git`) estão íntegros no disco.

### 4. Compilação Independente do Servidor de Voz
Invocando o compilador do `.NET SDK` recém-instalado, o instalador compila o SharpWin gerando um executável único e autônomo (`sharpwin.exe`). Ele empacota todas as dependências de áudio necessárias (`NAudio` e `System.Speech`) de forma isolada, sem poluir seu sistema global. O script valida fisicamente a existência do `.exe` gerado antes de avançar.

### 5. Geração de Autoloads (Emacs Batch Mode)
O script inicia o binário do GNU Emacs em segundo plano (*Batch Mode*) para forçar a leitura rápida do repositório de lisp do Emacspeak e compilar o arquivo de carregamento estrutural `emacspeak-loaddefs.el`. O arquivo gerado é verificado fisicamente no disco.

### 6. Configuração Inteligente do `init.el`
O instalador gera ou complementa o arquivo de inicialização do seu editor (`~/.emacs.d/init.el`) injetando a lógica necessária para o ambiente Windows, que resolve:
* O uso de **Pipes** (`process-connection-type nil`) para a troca rápida de dados entre o Emacs e o Servidor de Voz.
* Codificação compatível (`utf-8-dos`) para evitar erros de compatibilidade de caracteres no Windows.

---

## 🛠️ Como Usar?

### Requisitos de Sistema
O script possui suporte nativo para máquinas físicas e virtuais rodando:
* **Windows 10 ou 11** (com suporte e atualização ativa do *App Installer/Winget*).
* **Windows 7, 8 ou 8.1** (o script configurará o *Chocolatey* automaticamente).

### Passo a Passo:
1. Abra o menu Iniciar do Windows e digite **PowerShell**.
2. Clique com o botão direito sobre o ícone do PowerShell e escolha **Executar como Administrador** (necessário para que os gerenciadores possam registrar as novas dependências no sistema).
3. Copie o comando abaixo, cole no seu terminal e pressione `Enter`:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iex (iwr '[https://raw.githubusercontent.com/ittallo-dev/Emacspeak-install-Windows/main/install-emacspeak.ps1]' -UseBasicParsing).Content
