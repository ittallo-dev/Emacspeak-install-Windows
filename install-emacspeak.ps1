<#
.SYNOPSIS
    Script de instalação automatizada e nativa do Emacs/Emacspeak no Windows.
.DESCRIPTION
    Suporta o Windows 7/8/8.1 (via Chocolatey) e o Windows 10/11 (via Winget).
    Verifica, instala e valida dependências necessárias (Emacs, Git & .NET SDK).
    Realiza verificações de integridade física após cada clonagem e compilação.
#>

$ErrorActionPreference = "Stop"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Iniciando a Instalação do Ambiente Emacspeak Nativo" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

$TotalSteps = 6
$CurrentStep = 0

function Show-Progress {
    param([string]$Activity, [string]$Status)
    $global:CurrentStep++
    $Percent = [math]::Round(($global:CurrentStep / $global:TotalSteps) * 100)
    Write-Progress -Activity "Instalação do Emacspeak" -CurrentOperation $Activity -Status "$Status [$Percent%]" -PercentComplete $Percent
}

# ------------------------------------------------------------
# FUNÇÃO: Atualizar Variáveis de Ambiente em Tempo de Execução
# ------------------------------------------------------------
function Update-EnvironmentVariables {
    foreach ($level in "Machine", "User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Name -eq "Path") {
                $env:Path += ";$($_.Value)"
            }
        }
    }
}

# ------------------------------------------------------------
# FUNÇÃO: Instalar e Validar Dependências (Winget / Chocolatey)
# ------------------------------------------------------------
function Install-And-Validate {
    param(
        [string]$CommandName, 
        [string]$WingetId, 
        [string]$ChocoId,
        [string]$FriendlyName,
        [string]$PackageManager
    )
    
    Write-Host "--> Verificando $FriendlyName..." -ForegroundColor DarkGray

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "    [OK] $FriendlyName já está instalado." -ForegroundColor Green
        return $false
    }

    Write-Host "    [!] $FriendlyName ausente. Iniciando instalação via $PackageManager..." -ForegroundColor Magenta
    
    if ($PackageManager -eq "winget") {
        winget install --id $WingetId -e # --silent --accept-package-agreements --accept-source-agreements | Out-Null
    } else {
        choco install $ChocoId -y | Out-Null
    }
    
    Update-EnvironmentVariables
    
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "    [✔] Sucesso: $FriendlyName foi instalado e validado no sistema!" -ForegroundColor Green
        return $true
    } else {
        Write-Error "FALHA CRÍTICA: A instalação do $FriendlyName concluiu, mas o comando '$CommandName' não foi reconhecido."
        exit
    }
}

# ---------------------------------------------------
# ETAPA 1: Verificação de SO e Gerenciador de Pacotes
# ---------------------------------------------------
Show-Progress -Activity "Pré-requisitos do sistema" -Status "Analisando versão do Windows e instalando gerenciador"
Write-Host "`n[1/6] Analisando ambiente do sistema operacional..." -ForegroundColor Yellow

$OSMajor = [Environment]::OSVersion.Version.Major
$PackageManager = ""

if ($OSMajor -ge 10) {
    Write-Host "    [OK] Windows 10/11 detectado. Utilizando Winget." -ForegroundColor Gray
    $PackageManager = "winget"
    if (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "Winget não encontrado em um sistema compatível. Atualize o App Installer via Microsoft Store!"
        exit
    }
} else {
    Write-Host "    [!] Versão anterior ao Windows 10 detectada. Utilizando Chocolatey." -ForegroundColor Gray
    $PackageManager = "choco"
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "    Instalando Chocolatey..." -ForegroundColor Magenta
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Update-EnvironmentVariables
    }
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Falha crítica ao instalar o Chocolatey. Abortando processo."
        exit
    }
}

# Instalação das dependências
$UpdatedGit = Install-And-Validate -CommandName "git" -WingetId "Git.Git" -ChocoId "git" -FriendlyName "Git" -PackageManager $PackageManager
$UpdatedDotNet = Install-And-Validate -CommandName "dotnet" -WingetId "Microsoft.DotNet.SDK.8" -ChocoId "dotnet-8.0-sdk" -FriendlyName ".NET SDK 8.0" -PackageManager $PackageManager
$UpdatedEmacs = Install-And-Validate -CommandName "Emacs" -WingetId "GNU.Emacs" -ChocoId "Emacs" -FriendlyName "GNU Emacs" -PackageManager $PackageManager

# ---------------------------------------------------------
# ETAPA 2: Definição de Variáveis e Busca Dinâmica do Emacs
# ---------------------------------------------------------
Show-Progress -Activity "Mapeamento de Diretórios" -Status "Configurando caminhos de usuário e sistema"
Write-Host "`n[2/6] Mapeando diretórios de ambiente..." -ForegroundColor Yellow

$UserHome = [System.Environment]::GetFolderPath("UserProfile")
$EmacspeakDir = Join-Path $UserHome "emacspeak"
$SharpWinDir = Join-Path $EmacspeakDir "servers\sharpwin"
$EmacsDotDir = Join-Path $UserHome ".emacs.d"
$InitElPath = Join-Path $EmacsDotDir "init.el"

$EmacsExe = (Get-Command emacs -ErrorAction SilentlyContinue).Source
if (-Not $EmacsExe -or -Not (Test-Path $EmacsExe)) {
    Write-Host "    Buscando binário do Emacs em C:\Program Files e C:\tools..." -ForegroundColor DarkGray
    $EmacsExe = (Get-ChildItem -Path @("C:\Program Files\Emacs", "C:\tools\emacs") -Filter "emacs.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
}

if (-Not $EmacsExe -or -Not (Test-Path $EmacsExe)) {
    Write-Error "Não foi possível localizar fisicamente o emacs.exe. Abortando processo."
    exit
}
Write-Host "    [OK] Emacs validado fisicamente em: $EmacsExe" -ForegroundColor Green

# ---------------------------------
# ETAPA 3: Obtenção do Código-Fonte
# ---------------------------------
Show-Progress -Activity "Download de Repositórios" -Status "Clonando Emacspeak e SharpWin"
Write-Host "`n[3/6] Sincronizando repositórios do GitHub..." -ForegroundColor Yellow

try {
    if (-Not (Test-Path $EmacspeakDir)) {
        Write-Host "    Clonando repositório principal do Emacspeak..." -ForegroundColor DarkGray
        git clone https://github.com/tvraman/emacspeak.git $EmacspeakDir | Out-Null
        
        # Validação física da clonagem
        if (-Not (Test-Path (Join-Path $EmacspeakDir "lisp"))) {
            Write-Error "Falha: O repositório Emacspeak não foi clonado corretamente na máquina."
            exit
        }
        Write-Host "    [✔] Emacspeak clonado e validado." -ForegroundColor Green
    } else {
        Write-Host "    [OK] Repositório Emacspeak já está presente." -ForegroundColor Gray
    }

    if (-Not (Test-Path $SharpWinDir)) {
        Write-Host "    Clonando repositório do servidor SharpWin..." -ForegroundColor DarkGray
        Set-Location (Join-Path $EmacspeakDir "servers")
        git clone https://github.com/robertmeta/sharpwin.git | Out-Null
        
        # Validação física da clonagem
        if (-Not (Test-Path (Join-Path $SharpWinDir "sharpwin.csproj"))) {
            Write-Error "Falha: O repositório SharpWin não foi clonado corretamente na máquina."
            exit
        }
        Write-Host "    [✔] SharpWin clonado e validado." -ForegroundColor Green
    } else {
        Write-Host "    [OK] Repositório SharpWin já está presente." -ForegroundColor Gray
    }
} catch {
    Write-Error "FALHA CRÍTICA durante o uso do Git."
    exit
}

# --------------------------------------
# ETAPA 4: Compilação do Servidor de Voz
# --------------------------------------
Show-Progress -Activity "Compilação de arquivos" -Status "Gerando binário autônomo do SharpWin"
Write-Host "`n[4/6] Compilando o servidor de voz nativo (SharpWin)..." -ForegroundColor Yellow

try {
    Set-Location $SharpWinDir
    Write-Host "    Executando 'dotnet publish'..." -ForegroundColor DarkGray
    dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o (Join-Path $EmacspeakDir "servers") | Out-Null
    
    # Validação física da compilação
    $CompiledExe = Join-Path $EmacspeakDir "servers\sharpwin.exe"
    if (-Not (Test-Path $CompiledExe)) {
        Write-Error "Falha: O compilador .NET terminou, mas o arquivo sharpwin.exe não foi encontrado."
        exit
    }
    Write-Host "    [✔] Servidor compilado, empacotado e validado fisicamente!" -ForegroundColor Green
} catch {
    Write-Error "FALHA CRÍTICA na compilação do .NET."
    exit
}

# ------------------------------------------------
# ETAPA 5: Geração de Autoloads (Emacs Batch Mode)
# ------------------------------------------------
Show-Progress -Activity "Geração de Mapeamentos" -Status "Executando Emacs em Batch Mode"
Write-Host "`n[5/6] Gerando mapeamentos estruturais do Emacspeak..." -ForegroundColor Yellow

try {
    Set-Location (Join-Path $EmacspeakDir "lisp")
    Write-Host "    Invocando o Emacs em background..." -ForegroundColor DarkGray
    & $EmacsExe --batch --eval "(require 'loaddefs-gen)" --eval "(loaddefs-generate `".`" `"emacspeak-loaddefs.el`")" 2>&1 | Out-Null
    
    # Validação física da geração
    if (-Not (Test-Path "emacspeak-loaddefs.el")) {
        Write-Error "Falha: O arquivo emacspeak-loaddefs.el não foi gerado no disco."
        exit
    }
    Write-Host "    [✔] Arquivo emacspeak-loaddefs.el gerado e validado." -ForegroundColor Green
} catch {
    Write-Error "FALHA CRÍTICA ao interagir com o binário do Emacs."
    exit
}

# ---------------------------
# ETAPA 6: Injeção no init.el
# ---------------------------
Show-Progress -Activity "Configuração Final" -Status "Gravando configurações no init.el"
Write-Host "`n[6/6] Injetando configurações no init.el..." -ForegroundColor Yellow

$EmacspeakDirUnix = $EmacspeakDir -replace "\\", "/"
if (-Not $EmacspeakDirUnix.EndsWith("/")) { $EmacspeakDirUnix += "/" }

if (-Not (Test-Path $EmacsDotDir)) {
    Write-Host "    Criando diretório .emacs.d..." -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $EmacsDotDir | Out-Null
}

$ElispConfig = @"

;; - Inicio da Configuração Base: Emacs/Emacspeak Nativos no Windows -

;; 1. Define o diretório base do Emacspeak
(defvar emacspeak-dir "$EmacspeakDirUnix")

;; 2. Força a comunicação via Pipes
(setq process-connection-type nil)

;; 3. Força a codificação de texto compatível para evitar erros de compatibilidade
(add-to-list 'process-coding-system-alist '(".*" . (utf-8-dos . utf-8-dos)))

;; 4. Aponta as variáveis de servidor para o executável gerado pelo .NET
(setq dtk-program (concat emacspeak-dir "servers/sharpwin.exe"))
(setenv "DTK_PROGRAM" (concat emacspeak-dir "servers/sharpwin.exe"))

;; 5. Adiciona diretórios ao caminho de execução do Emacs
(add-to-list 'load-path (concat emacspeak-dir "lisp"))
(add-to-list 'exec-path (concat emacspeak-dir "servers"))

;; 6. Inicialização do sistema
(load-file (concat emacspeak-dir "lisp/emacspeak-setup.el"))

;; - Fim da Configuração Base -
"@

Add-Content -Path $InitElPath -Value $ElispConfig -Encoding UTF8

# Validação física final
if (-Not (Test-Path $InitElPath)) {
    Write-Error "Falha: O arquivo init.el não pôde ser gravado."
    exit
}
Write-Host "    [✔] Arquivo init.el configurado e verificado no disco." -ForegroundColor Green

# -------------------------------
# FINALIZAÇÃO DA INSTALAÇÃO GERAL
# -------------------------------
Write-Progress -Activity "Instalação Completa" -Completed
Write-Host "`n======================================================" -ForegroundColor Green
Write-Host " ✔ INSTALAÇÃO FINALIZADA COM SUCESSO!" -ForegroundColor Green
Write-Host " Todas as dependências e arquivos foram validados fisicamente." -ForegroundColor Green
Write-Host " Inicie o seu Emacs para começar o uso do ambiente audível." -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
