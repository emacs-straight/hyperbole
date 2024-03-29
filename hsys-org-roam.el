;;; hsys-org.el --- GNU Hyperbole support functions for Org Roam  -*- lexical-binding: t; -*-
;;
;; Author:       Bob Weiner
;;
;; Orig-Date:    26-Feb-23 at 11:20:15 by Bob Weiner
;; Last-Mod:     20-Jan-24 at 15:39:49 by Mats Lidell
;;
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; Copyright (C) 2023-2024  Free Software Foundation, Inc.
;; See the "HY-COPY" file for license information.
;;
;; This file is part of GNU Hyperbole.

;;; Commentary:
;;
;;   The autoloaded function, `hsys-org-roam-consult-grep', uses
;;   consult-grep to do a full-text search over notes included
;;   into the user's Org Roam database.
;;
;;   Use `org-roam-migrate-wizard' to import any Org note files and
;;   assign them UUIDs required for indexing by Org Roam.

;;; Code:
;;; ************************************************************************
;;; Other required Elisp libraries
;;; ************************************************************************

(require 'package)

;;; ************************************************************************
;;; Public declarations
;;; ************************************************************************

(defvar consult-org-roam-grep-func)
(defvar org-roam-directory)
(declare-function org-roam-db-autosync-mode "ext:org-roam")

;;; ************************************************************************
;;; Public functions
;;; ************************************************************************

;;;###autoload
(defun hsys-org-roam-consult-grep ()
  "Prompt for search terms and run consult grep over `org-roam-directory'.
Actual grep function used is given by the variable,
`consult-org-roam-grep-func'."
  (interactive)
  (unless (package-installed-p 'consult-org-roam)
    (package-install 'consult-org-roam))
  (require 'consult-org-roam)
  (let ((grep-func (when (and (boundp 'consult-org-roam-grep-func)
			      (fboundp consult-org-roam-grep-func))
		     consult-org-roam-grep-func)))
    (if grep-func
	(funcall grep-func org-roam-directory)
      (error "(hsys-org-roam-consult-grep): `%s' is an invalid function"
	     consult-org-roam-grep-func))))

(provide 'hsys-org-roam)

;;; hsys-org-roam.el ends here
