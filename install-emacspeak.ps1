<#
.SYNOPSIS
    Script de instalação automatizada e nativa do Emacspeak no Windows.
.DESCRIPTION
    Verifica e instala dependências (Git & .NET SDK) via Winget, clona repositórios,
    compila o servidor SharpWin e configura o init.el base do GNU Emacs.
#>

$ErrorActionPreference = "Stop"

Write-Host "Iniciando a automação do ambiente Emacspeak..." -ForegroundColor Cyan

# ---------------------------------------------------------
# FUNÇÃO: Atualizar Variáveis de Ambiente em Tempo de Execução
# ---------------------------------------------------------
function Update-EnvironmentVariables {
    Write-Host "Atualizando variáveis de ambiente (PATH)..." -ForegroundColor DarkGray
    foreach ($level in "Machine", "User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Name -eq "Path") {
                $env:Path += ";$($_.Value)"
            }
        }
    }
}

# ---------------------------------------------------------
# ETAPA 1: Verificação e Instalação de Pré-requisitos
# ---------------------------------------------------------
Write-Host "`n[1/5] Verificando pré-requisitos do sistema..." -ForegroundColor Yellow

# Verificar Winget (necessário para baixar o resto)
if (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "O Gerenciador de Pacotes do Windows (winget) não foi encontrado. Atualize seu Windows."
    exit
}

$RequiresUpdate = $false

# Verificar/Instalar Git
if (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git não encontrado. Instalando dependência via Winget..." -ForegroundColor Magenta
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    $RequiresUpdate = $true
} else {
    Write-Host "Git já está instalado." -ForegroundColor Gray
}

# Verificar/Instalar .NET SDK (necessário para o dotnet publish)
if (-Not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host ".NET SDK não encontrado. Instalando dependência via Winget..." -ForegroundColor Magenta
    # Instala o SDK 8.0 (LTS mais recente). Pode ser ajustado conforme a exigência do SharpWin.
    winget install Microsoft.DotNet.SDK.8 -e --silent --accept-package-agreements --accept-source-agreements
    $RequiresUpdate = $true
} else {
    Write-Host ".NET SDK já está instalado." -ForegroundColor Gray
}

# Atualiza o PATH se algo foi instalado, para que o script possa usar "git" e "dotnet" logo em seguida
if ($RequiresUpdate) {
    Update-EnvironmentVariables
}

# ---------------------------------------------------------
# ETAPA 2: Definição de Variáveis e Caminhos
# ---------------------------------------------------------
$UserHome = [System.Environment]::GetFolderPath("UserProfile")
$EmacspeakDir = Join-Path $UserHome "emacspeak"
$SharpWinDir = Join-Path $EmacspeakDir "servers\sharpwin"
$EmacsDotDir = Join-Path $UserHome ".emacs.d"
$InitElPath = Join-Path $EmacsDotDir "init.el"

# Caminho do Emacs ( Nota: no futuro seria interessante instalar via Winget também: winget install GNU.Emacs)
$EmacsExe = "C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"

# ---------------------------------------------------------
# ETAPA 3: Obtenção do Código-Fonte
# ---------------------------------------------------------
try {
    Write-Host "`n[2/5] Clonando repositórios do GitHub..." -ForegroundColor Yellow
    if (-Not (Test-Path $EmacspeakDir)) {
        git clone https://github.com/tvraman/emacspeak.git $EmacspeakDir
    } else {
        Write-Host "Repositório Emacspeak já clonado." -ForegroundColor Gray
    }

    if (-Not (Test-Path $SharpWinDir)) {
        Set-Location (Join-Path $EmacspeakDir "servers")
        git clone https://github.com/robertmeta/sharpwin.git
    } else {
        Write-Host "Repositório SharpWin já clonado." -ForegroundColor Gray
    }
} catch {
    Write-Error "Falha na etapa do Git. Abortando."
    exit
}

# ---------------------------------------------------------
# ETAPA 4: Compilação do Servidor de Voz
# ---------------------------------------------------------
try {
    Write-Host "`n[3/5] Compilando o servidor SharpWin..." -ForegroundColor Yellow
    Set-Location $SharpWinDir
    dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o (Join-Path $EmacspeakDir "servers")
} catch {
    Write-Error "Falha na compilação do .NET. Abortando."
    exit
}

# ---------------------------------------------------------
# ETAPA 5: Geração de Autoloads
# ---------------------------------------------------------
try {
    Write-Host "`n[4/5] Gerando mapeamento do Emacspeak..." -ForegroundColor Yellow
    if (-Not (Test-Path $EmacsExe)) {
        Write-Warning "Emacs não encontrado no caminho padrão ($EmacsExe)."
        $EmacsExe = Read-Host "Insira o caminho completo para o emacs.exe"
    }
    
    Set-Location (Join-Path $EmacspeakDir "lisp")
    & $EmacsExe --batch --eval "(require 'loaddefs-gen)" --eval "(loaddefs-generate `".`" `"emacspeak-loaddefs.el`")"
} catch {
    Write-Error "Falha ao interagir com o binário do Emacs."
    exit
}

# ---------------------------------------------------------
# ETAPA 6: Injeção no init.el
# ---------------------------------------------------------
Write-Host "`n[5/5] Injetando configurações no init.el..." -ForegroundColor Yellow

$EmacspeakDirUnix = $EmacspeakDir -replace "\\", "/"
if (-Not $EmacspeakDirUnix.EndsWith("/")) { $EmacspeakDirUnix += "/" }

if (-Not (Test-Path $EmacsDotDir)) {
    New-Item -ItemType Directory -Force -Path $EmacsDotDir | Out-Null
}

$ElispConfig = @"

;; --- Configuração Auto-Gerada: Emacspeak Nativamente no Windows ---

;; 1. Define o diretório base do Emacspeak
(defvar emacspeak-dir "$EmacspeakDirUnix")

;; 2. Força a comunicação via Pipes
(setq process-connection-type nil)

;; 3. Força a codificação de texto compatível para evitar o erros de compatibilidade
(add-to-list 'process-coding-system-alist '(".*" . (utf-8-dos . utf-8-dos)))

;; 4. Aponta as variáveis de servidor para o executável gerado pelo .NET
(setq dtk-program (concat emacspeak-dir "servers/sharpwin.exe"))
(setenv "DTK_PROGRAM" (concat emacspeak-dir "servers/sharpwin.exe"))

;; 5. Adiciona diretórios ao caminho de execução do Emacs
(add-to-list 'load-path (concat emacspeak-dir "lisp"))
(add-to-list 'exec-path (concat emacspeak-dir "servers"))

;; 6. Inicialização do sistema
(load-file (concat emacspeak-dir "lisp/emacspeak-setup.el"))
;; ------------------------------------------------------------------
"@

Add-Content -Path $InitElPath -Value $ElispConfig -Encoding UTF8

Write-Host "`n✔ Instalação finalizada de ponta a ponta! Inicie seu Emacs." -ForegroundColor Green
