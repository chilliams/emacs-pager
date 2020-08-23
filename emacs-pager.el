;;; emacs-pager.el --- incredibly simple mode for showing data paged by emacs-pager

;; Copyright (C) 2014 Matt Briggs <http://mattbriggs.net>

;; Author: Matt Briggs
;; URL: http://github.com/mbriggs/emacs-pager
;; Version: 0.0.1
;; Keywords: pager shell

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; See <http://www.gnu.org/licenses/> for a copy of the GNU General
;; Public License.

;;; Commentary:
;; See readme (http://mattbriggs.net/emacs-pager/) for installation / usage

;;; Code:

(defvar emacs-pager-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'emacs-pager-kill-pager)
    map)
  "Keymap for emacs pager mode.")

(defun emacs-pager-kill-pager ()
  "Kill pager buffer immediately"
  (interactive)
  (delete-process (get-buffer-process (current-buffer)))
  (call-process "kill" nil nil nil "-9" (number-to-string emacs-pager-pid))
  (let ((filename emacs-pager-filename))
    (kill-buffer)
    (delete-file filename)
    (message "Deleted file %s" filename)))

;;;###autoload
(define-derived-mode emacs-pager-mode comint-mode "Pager"
  "Mode for viewing data paged by emacs-pager"
  (setq-local make-backup-files nil)
  (read-only-mode))

(defun emacs-pager-output-filter (process string)
  (comint-output-filter process string)
  (when emacs-pager-move-to-begin
    (beginning-of-buffer)
    (setq-local emacs-pager-move-to-begin nil)))

(defun emacs-pager-page (filename pid)
  (let ((buf (generate-new-buffer "*pager*")))
    (with-current-buffer buf
      (emacs-pager-mode)
      (set (make-local-variable 'emacs-pager-pid) pid)
      (set (make-local-variable 'emacs-pager-move-to-begin) t)
      (set (make-local-variable 'emacs-pager-filename) filename))
    (switch-to-buffer buf)
    (let ((proc (start-process "*pager*"
                               buf
                               "tail"
                               "-F"
                               "-n"
                               "+1"
                               filename)))
      (set-process-filter proc 'emacs-pager-output-filter))))

(provide 'emacs-pager)

;;; emacs-pager.el ends here
