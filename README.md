# Emacspeak & GNU Emacs - Instalador Nativo para Windows

Este repositório fornece uma solução de automação para instalar e integrar o **Emacspeak** com o **GNU Emacs** de forma nativa no ambiente Windows. 

O script lida com todo o trabalho pesado: resolve dependências de sistema, compila o servidor de voz usando o .NET, gera os mapeamentos do Emacspeak em segundo plano e configura automaticamente o seu editor, tudo com um único comando.

## 🚀 O que este script faz?

1. **Instalação de Pré-requisitos:** Verifica a presença do `GNU Emacs` , `Git` e do `.NET SDK` no sistema. Caso não existam, realiza o download e a instalação silenciosa via `winget` ou via `chocolatey`.
2. **Sincronização de Código:** Clona os repositórios oficiais do [Emacspeak](https://github.com/tvraman/emacspeak) e do servidor de voz [SharpWin](https://github.com/robertmeta/sharpwin) diretamente para a sua pasta de usuário.
3. **Compilação Independente:** Utiliza o `.NET` para compilar o SharpWin em um executável autônomo (`.exe`), empacotando todas as dependências de áudio nativas do Windows.
4. **Geração de Autoloads:** Executa o binário do seu GNU Emacs em *Batch Mode* (segundo plano) para gerar o arquivo vital de mapeamento `emacspeak-loaddefs.el`.
5. **Configuração Automática:** Injeta as configurações necessárias no seu arquivo `init.el`, resolvendo problemas comuns de IPC (*Pipes*) e codificação de caracteres do Windows.

---

## 🛠️ Como Usar?

Para que a automação funcione perfeitamente e consiga instalar dependências de sistema (caso necessário), você deve executar o comando abaixo utilizando privilégios de administrador.

### Pré-requisito!
Windows 10 e 11 realizam a instalação de forma mais direta via `winget` , as versões do Windows 7 , 8 e 8.1 fazem uso do `chocolatey` para a instalação das dependências e afins. Para a instalação bem sucedida
é necessário possuir alguns dos sitemas operacionais citados acima com os respectivos gerenciadores de arquivos da versão em uso.

### Passo a Passo:
1. Pressione a tecla `Windows`, digite **PowerShell**.
2. Clique em **Executar como Administrador**.
3. Copie o comando abaixo, cole no terminal e pressione `Enter`:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iex (iwr 'https://raw.githubusercontent.com/ittallo-dev/Emacspeak-install-Windows/main/install-emacspeak.ps1' -UseBasicParsing).Content
