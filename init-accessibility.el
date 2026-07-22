;;; init-accessibility.el --- Voz, UI Limpa e Acessibilidade -*- lexical-binding: t; -*-

;; --- 1. Limpeza de Interface (Ambiente sem artefatos visuais) ---
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

;; --- 2. Configurações Básicas de Áudio e Feedback ---
(setq emacspeak-play-program nil)
(setq emacspeak-use-auditory-icons nil)
(setq emacspeak-line-echo t)
(setq echo-keystrokes 0.1)
(setq ring-bell-function #'ignore)

(defgroup my-accessibility nil
  "Configurações de acessibilidade do usuário."
  :group 'applications)

;; --- 3. Hooks de Sistema e Limpeza de Processos ---
(defun my-speak-saved ()
  "Anuncia que o arquivo foi salvo."
  (message "Arquivo salvo.")
  (when (fboundp 'emacspeak-speak-line)
    (emacspeak-speak-line)))
(add-hook 'after-save-hook #'my-speak-saved)

(defun my/emacspeak-process-p (proc)
  "Retorna t se PROC parecer ser um processo do Emacspeak."
  (let ((name (process-name proc))
        (buf  (process-buffer proc)))
    (or (eq proc (and (boundp 'dtk-speaker-process) dtk-speaker-process))
        (and name (string-match-p "speaker\\|dtk\\|tts\\|sharpwin" name))
        (and buf
             (buffer-live-p buf)
             (string-match-p "speaker\\|dtk\\|tts\\|sharpwin"
                             (buffer-name buf))))))

(defun my/emacspeak-disable-exit-query ()
  "Desativa a pergunta de saída para processos do Emacspeak."
  (dolist (proc (process-list))
    (when (and (process-live-p proc)
               (my/emacspeak-process-p proc))
      (set-process-query-on-exit-flag proc nil))))

(defun my/emacspeak-cleanup ()
  "Desativa query-on-exit e encerra processos do Emacspeak ao fechar."
  (my/emacspeak-disable-exit-query)
  (dolist (proc (process-list))
    (when (and (process-live-p proc)
               (my/emacspeak-process-p proc))
      (ignore-errors
        (delete-process proc)))))

;; --- 4. Configuração de Idioma (PT-BR) ---
(defun my/emacspeak-apply-language ()
  "Aplica português do Brasil nativamente."
  (when (fboundp 'dtk-set-language)
    (dtk-set-language "pt-br"))
  (setq dtk-speech-rate 180))

;; Inicialização de hooks temporizados para garantir carregamento seguro
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-idle-timer 1 nil #'my/emacspeak-disable-exit-query)
            (run-with-idle-timer 2 nil #'my/emacspeak-apply-language)))

(add-hook 'kill-emacs-hook #'my/emacspeak-cleanup)

;; --- 5. Alternância Dinâmica de Idiomas (Atalho) ---
(defvar my/emacspeak-current-language "pt-br"
  "Idioma atual do Emacspeak controlado pelo usuário.")

(defun my/emacspeak-toggle-language ()
  "Alterna rapidamente entre português do Brasil e inglês."
  (interactive)
  (when (fboundp 'dtk-stop)
    (dtk-stop))
  (condition-case nil
      (if (string= my/emacspeak-current-language "pt-br")
          (progn
            (dtk-set-language "en")
            (setq my/emacspeak-current-language "en")
            (run-with-timer
             0.2 nil
             (lambda ()
               (when (fboundp 'dtk-speak)
                 (dtk-speak "English mode")))))
        (dtk-set-language "pt-br")
        (setq my/emacspeak-current-language "pt-br")
        (run-with-timer
         0.2 nil
         (lambda ()
           (when (fboundp 'dtk-speak)
             (dtk-speak "Modo português")))))
    (error
     (when (fboundp 'emacspeak-emergency-tts-restart)
       (emacspeak-emergency-tts-restart)))))

(global-set-key (kbd "C-c t") #'my/emacspeak-toggle-language)

(provide 'init-accessibility)
;;; init-accessibility.el ends here
