; -*- Mode: Emacs-Lisp ; Coding: utf-8 -*-

;; ------------------------------------------------------------------------
;; @ load-path

;; load-pathの追加関数
(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory (expand-file-name (concat user-emacs-directory path))))
        (add-to-list 'load-path default-directory)
        (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
            (normal-top-level-add-subdirs-to-load-path))))))

;; load-pathに追加するフォルダ
;; 2つ以上フォルダを指定する場合の引数 => (add-to-load-path "elisp" "xxx" "xxx")
(add-to-load-path "elisp")


;; -----------------------------------------------------------------------
;; @ 行番号の表示

;; 行番号表示
(global-linum-mode t)
(set-face-attribute 'linum nil
                    :foreground "#800"
                    :height 0.9)

;; 行番号フォーマット
(setq linum-format "% 4d| ")


;; -----------------------------------------------------------------------
;; Scroll setting

;; 1行ずつスクロール
(setq scroll-conservatively 35
      scroll-margin 0
      scroll-step 1)
(setq comint-scroll-show-maximum-output t) 
;; shell-modeなので要注意


;; ------------------------------------------------------------------------
;; @ modeline

;; モードラインに行番号表示
(line-number-mode t)

;; モードラインに列番号表示
(column-number-mode t)

;; モードラインの割合表示を総行数表示
(defvar my-lines-page-mode t)
(defvar my-mode-line-format)

(when my-lines-page-mode
  (setq my-mode-line-format "%d")
  (if size-indication-mode
      (setq my-mode-line-format (concat my-mode-line-format " of %%I")))
  (cond ((and (eq line-number-mode t) (eq column-number-mode t))
         (setq my-mode-line-format (concat my-mode-line-format " (%%l,%%c)")))
        ((eq line-number-mode t)
         (setq my-mode-line-format (concat my-mode-line-format " L%%l")))
        ((eq column-number-mode t)
         (setq my-mode-line-format (concat my-mode-line-format " C%%c"))))

  (setq mode-line-position
        '(:eval (format my-mode-line-format
                        (count-lines (point-max) (point-min)))))) 


;; ------------------------------------------------------------------------
;; @ auto-install.el

;; パッケージのインストールを自動化
;; http://www.emacswiki.org/emacs/auto-install.el
(when (require 'auto-install nil t)
  (setq auto-install-directory "~/.emacs.d/elisp/auto-install/")
  (auto-install-update-emacswiki-package-name t)
  (auto-install-compatibility-setup))


;; ------------------------------------------------------------------------
;; @ redo+.el

;; redoできるようにする
;; http://www.emacswiki.org/emacs/redo+.el
(when (require 'redo+ nil t)
  (define-key global-map (kbd "C-?") 'redo))



;; ------------------------------------------------------------------------
;; @ flymake.el

(when (require 'flymake nil t)
  ;; 下の一行はflymakeモードでエラー行に飛べるコマンドをキーに割り当ててるコードですが、
  ;; 個人的な理由でコメントアウトしてます。必要でしたらこのコメント削除して、アンコメントしてください
  ;;define-key global-map (kbd "C-x C-e") 'flymake-display-err-menu-for-current-line)

  ;; C
  ;; http://d.hatena.ne.jp/nyaasan/20071216/p1
  (defun flymake-c-init ()
    (let* ((temp-file   (flymake-init-create-temp-buffer-copy
                         'flymake-create-temp-inplace))
           (local-file  (file-relative-name
                         temp-file
                         (file-name-directory buffer-file-name))))
      (list "gcc" (list "-Wall" "-Wextra" "-fsyntax-only" local-file))))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.\\(c\\|h\\|y\\l\\)$" flymake-c-init))
  ;; C++
  (defun flymake-cc-init ()
    (let* ((temp-file   (flymake-init-create-temp-buffer-copy
                         'flymake-create-temp-inplace))
           (local-file  (file-relative-name
                         temp-file
                         (file-name-directory buffer-file-name))))
      (list "g++" (list "-Wall" "-Wextra" "-fsyntax-only" local-file))))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.cpp$" flymake-cc-init))

  ;; Emacs Lisp
  ;; http://www.emacswiki.org/emacs/FlymakeElisp
  (defun flymake-elisp-init ()
    (unless (string-match "^ " (buffer-name))
      (let* ((temp-file   (flymake-init-create-temp-buffer-copy
                           'flymake-create-temp-inplace))
             (local-file  (file-relative-name
                           temp-file
                           (file-name-directory buffer-file-name))))
        (list
         (expand-file-name invocation-name invocation-directory)
         (list
          "-Q" "--batch" "--eval"
          (prin1-to-string
           (quote
            (dolist (file command-line-args-left)
              (with-temp-buffer
                (insert-file-contents file)
                (condition-case data
                    (scan-sexps (point-min) (point-max))
                  (scan-error
                   (goto-char(nth 2 data))
                   (princ (format "%s:%s: error: Unmatched bracket or quote\n"
                                  file (line-number-at-pos)))))))
            )
           )
          local-file)))))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.el$" flymake-elisp-init))

  (add-hook 'emacs-lisp-mode-hook
            ;; workaround for (eq buffer-file-name nil)
            (function (lambda () (if buffer-file-name (flymake-mode)))))
  (add-hook 'c-mode-common-hook
            (lambda () (flymake-mode t)))
  (add-hook 'php-mode-hook
            (lambda () (flymake-mode t)))
  ;; Haskell
  (defun flymake-haskell-init ()
    (let* ((temp-file   (flymake-init-create-temp-buffer-copy
			 'flymake-create-temp-inplace))
	   (local-dir   (file-name-directory buffer-file-name))
	   (local-file  (file-relative-name
			 temp-file
			 local-dir)))
      (list "~/local/bin/flycheck_haskell.pl" (list local-file local-dir))))
  
  (push '(".+\\hs$" flymake-haskell-init) flymake-allowed-file-name-masks)
  (push '(".+\\lhs$" flymake-haskell-init) flymake-allowed-file-name-masks)
  (push
   '("^\\(\.+\.hs\\|\.lhs\\):\\([0-9]+\\):\\([0-9]+\\):\\(.+\\)"
     1 2 3 4) flymake-err-line-patterns)
  
  (add-hook 'haskell-mode-hook
	    '(lambda ()
	       (if (not (null buffer-file-name)) (flymake-mode))
	       ))
)
