# --- Script de Instalação-Automatização (WSL + Emacs + Java) ---
Write-Host "Iniciando Configuração Geral..." -ForegroundColor Cyan

# Detecção Automática do Usuário WSL
$wslUser = wsl whoami
if ($null -eq $wslUser) {
    Write-Host "Erro: Não foi possível detectar um usuário no WSL." -ForegroundColor Red
    exit
}
$homeDir = "/home/$wslUser"
Write-Host "Usuário detectado no WSL: $wslUser" -ForegroundColor Green

# Instalação de Dependências (Garante Emacs e Java)
Write-Host "Instalando dependências e programas (Emacs, Java, Git)..." -ForegroundColor Yellow
wsl -u $wslUser sh -c "sudo apt-get update && sudo apt-get install -y emacs-nox openjdk-17-jdk espeak-ng libespeak-ng-dev tcl-dev tclx tcl8.6-dev pulseaudio sox git locales"
wsl -u $wslUser sh -c "sudo locale-gen pt_BR.UTF-8"

# Download e Compilação do Emacspeak
Write-Host "Configurando Emacspeak em $homeDir..." -ForegroundColor Yellow
# Removemos a pasta se ela estiver incompleta e clonamos novamente
wsl -u $wslUser sh -c "cd $homeDir && rm -rf emacspeak && git clone https://github.com/tvraman/emacspeak.git"
wsl -u $wslUser sh -c "cd $homeDir/emacspeak && make"
wsl -u $wslUser sh -c "cd $homeDir/emacspeak/servers/native-espeak && make"

# Injeção do init.el
Write-Host "Configurando init.el personalizado..." -ForegroundColor Magenta
$init_el = @"
(setenv "PULSE_SERVER" "unix:/mnt/wslg/PulseServer")
(setenv "DTK_PROGRAM" "espeak")

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents (package-refresh-contents))
(unless (package-installed-p 'company) (package-install 'company))

(setq inhibit-startup-screen t)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

(defvar emacspeak-directory "$homeDir/emacspeak")
(add-to-list 'load-path (expand-file-name "lisp" emacspeak-directory))
(setq warning-minimum-level :error)
(load-file (expand-file-name "lisp/emacspeak-setup.el" emacspeak-directory))

(setq emacspeak-use-sounds nil)
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)
(load-theme 'modus-vivendi t)
(global-display-line-numbers-mode t)

(defun stark-java-run ()
  (interactive)
  (save-buffer)
  (compile (concat "javac " (buffer-file-name) " && java " (file-name-sans-extension (buffer-file-name)))))
(global-set-key (kbd "<f5>") 'stark-java-run)
"@

$init_el | wsl -u $wslUser sh -c "mkdir -p ~/.emacs.d && cat > ~/.emacs.d/init.el"

# Configuração Final do Terminal (.bashrc)
wsl -u $wslUser sh -c "sed -i '/EMACSPEAK_DIR/d; /DTK_PROGRAM/d' ~/.bashrc"
wsl -u $wslUser sh -c "echo 'export EMACSPEAK_DIR=$homeDir/emacspeak' >> ~/.bashrc && echo 'export DTK_PROGRAM=espeak' >> ~/.bashrc"

Write-Host "CONCLUÍDO! Configuração realizada com sucesso para o usuário $wslUser." -ForegroundColor Cyan