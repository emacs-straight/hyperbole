;;; hibtypes.el --- GNU Hyperbole default implicit button types
;;
;; Author: Bob Weiner
;;
;; Orig-Date: 19-Sep-91 at 20:45:31
;;
;; Copyright (C) 1991-2019  Free Software Foundation, Inc.
;; See the "HY-COPY" file for license information.
;;
;; This file is part of GNU Hyperbole.
;;; Commentary:
;;
;;   Implicit button types (ibtypes) in this file are defined in increasing
;;   order of priority within this file (last one is highest priority).
;;
;;   To return a list of the implicit button types in priority order (highest
;;   to lowest), evaluate:
;;
;;      (symset:get 'ibtypes 'symbols)
;;
;;   If you need to reset the priorities of all ibtypes, evaluate:
;;
;;      (symset:clear 'ibtypes)
;;
;;   and then reload this file.
;;
;;   To get a list of all loaded action types, evaluate:
;;
;;      (symset:get 'actypes 'symbols)

;;; Code:
;;; ************************************************************************
;;; Other required Elisp libraries
;;; ************************************************************************

(eval-when-compile (require 'hversion))
(require 'subr-x) ;; For string-trim
(require 'hactypes)

;;; ************************************************************************
;;; Public variables
;;; ************************************************************************

(defconst mail-address-tld-regexp
  (format "\\.%s\\'"
          (regexp-opt
           '("aero" "arpa" "asia" "biz" "cat" "com" "coop" "edu" "gov" "info"
             "int" "jobs" "mil" "mobi" "museum" "name" "net" "org" "pro" "tel"
             "travel" "uucp"
             "ac" "ad" "ae" "af" "ag" "ai" "al" "am" "an" "ao" "aq"
             "ar" "as" "at" "au" "aw" "ax" "az" "ba" "bb" "bd" "be" "bf" "bg" "bh"
             "bi" "bj" "bl" "bm" "bn" "bo" "br" "bs" "bt" "bv" "bw" "by" "bz" "ca"
             "cc" "cd" "cf" "cg" "ch" "ci" "ck" "cl" "cm" "cn" "co" "cr" "cu" "cv"
             "cx" "cy" "cz" "de" "dj" "dk" "dm" "do" "dz" "ec" "ee" "eg" "eh" "er"
             "es" "et" "eu" "fi" "fj" "fk" "fm" "fo" "fr" "ga" "gb" "gd" "ge" "gf"
             "gg" "gh" "gi" "gl" "gm" "gn" "gp" "gq" "gr" "gs" "gt" "gu" "gw" "gy"
             "hk" "hm" "hn" "hr" "ht" "hu" "id" "ie" "il" "im" "in" "io" "iq" "ir"
             "is" "it" "je" "jm" "jo" "jp" "ke" "kg" "kh" "ki" "km" "kn" "kp" "kr"
             "kw" "ky" "kz" "la" "lb" "lc" "li" "lk" "lr" "ls" "lt" "lu" "lv" "ly"
             "ma" "mc" "md" "me" "mf" "mg" "mh" "mk" "ml" "mm" "mn" "mo" "mp" "mq"
             "mr" "ms" "mt" "mu" "mv" "mw" "mx" "my" "mz" "na" "nc" "ne" "nf" "ng"
             "ni" "nl" "no" "np" "nr" "nu" "nz" "om" "pa" "pe" "pf" "pg" "ph" "pk"
             "pl" "pm" "pn" "pr" "ps" "pt" "pw" "py" "qa" "re" "ro" "rs" "ru" "rw"
             "sa" "sb" "sc" "sd" "se" "sg" "sh" "si" "sj" "sk" "sl" "sm" "sn" "so"
             "sr" "st" "su" "sv" "sy" "sz" "tc" "td" "tf" "tg" "th" "tj" "tk" "tl"
             "tm" "tn" "to" "tp" "tr" "tt" "tv" "tw" "tz" "ua" "ug" "uk" "um" "us"
             "uy" "uz" "va" "vc" "ve" "vg" "vi" "vn" "vu" "wf" "ws" "ye" "yt" "yu"
             "za" "zm" "zw")
           t))
  "Regular expression of most common Internet top level domain names.")

(defconst mail-address-regexp
  "\\([_a-zA-Z][-_a-zA-Z0-9.!@+%]*@[-_a-zA-Z0-9.!@+%]+\\.[a-zA-Z0-9][-_a-zA-Z0-9]+\\)\\($\\|[^a-zA-Z0-9@%]\\)"
  "Regexp with group 1 matching an Internet email address.")

;;; ************************************************************************
;;; Public implicit button types
;;; ************************************************************************

(run-hooks 'hibtypes-begin-load-hook)

;; Don't use require below here for any libraries with ibtypes in
;; them.  Use load instead to ensure are reloaded when resetting
;; ibtype priorities.

;;; ========================================================================
;;; Runs Hyperbole tests
;;; ========================================================================

(load "hypb-ert")

;;; ========================================================================
;;; Follows Org mode links and radio targets and cycles Org heading views
;;; ========================================================================

(load "hib-org")

;; If you want to to disable ALL Hyperbole support within Org major
;; and minor modes, set the custom option `inhibit-hsys-org' non-nil.

;;; ========================================================================
;;; Follows URLs by invoking a web browser.
;;; ========================================================================

(load "hsys-www")

;;; ========================================================================
;;; Follows Org links that are in non-Org mode buffers
;;; ========================================================================

(defib org-link-outside-org-mode ()
  "Follow an Org link in a non-Org mode buffer.
This should be a very low priority so other Hyperbole types
handle any links they recognize first."
  (unless inhibit-hsys-org
    (require 'hsys-org)
    (let ((start-end (hsys-org-link-at-p)))
      (when start-end
        (hsys-org-set-ibut-label start-end)
        (hact 'org-open-at-point-global)))))

;; Org links in Org mode are handled at a lower priority in "hib-org.el"

;;; ========================================================================
;;; Composes mail, in another window, to the e-mail address at point.
;;; ========================================================================

(defvar mail-address-mode-list
  '(emacs-lisp-mode lisp-interaction-mode lisp-mode scheme-mode
                    c-mode c++-mode html-mode java-mode js2-mode objc-mode
                    python-mode smalltalk-mode fundamental-mode text-mode
                    indented-text-mode web-mode)
  "List of major modes in which mail address implicit buttons are active.")

(defun mail-address-at-p ()
  "Return e-mail address, a string, that point is within or nil."
  (let ((case-fold-search t))
    (save-excursion
      (skip-chars-backward "^ \t\n\r\f\"\'(){}[];:<>|")
      (and (or (looking-at mail-address-regexp)
               (looking-at (concat "mailto:" mail-address-regexp)))
           (save-match-data
             (string-match mail-address-tld-regexp (match-string-no-properties 1)))
           (match-string-no-properties 1)))))

(defib mail-address ()
  "If on an e-mail address in a specific buffer type, compose mail to that address in another window.
Applies to any major mode in `mail-address-mode-list', the HyRolo match buffer,
any buffer attached to a file in `hyrolo-file-list', or any buffer with
\"mail\" or \"rolo\" (case-insensitive) within its name."
  (when (let ((case-fold-search t))
          (or
           (and (or (null mail-address-mode-list)
		    (memq major-mode mail-address-mode-list))
                (not (string-match "-Elements\\'" (buffer-name)))
                ;; Don't want this to trigger within an OOBR-FTR buffer.
                (not (string-match "\\`\\(OOBR.*-FTR\\|oobr.*-ftr\\)"
                                   (buffer-name)))
                (not (string-equal "*Implementors*" (buffer-name))))
           (and
            (string-match "mail\\|rolo" (buffer-name))
            ;; Don't want this to trigger in a mail/news summary buffer.
            (not (or (hmail:lister-p) (hnews:lister-p))))
           (when (boundp 'hyrolo-display-buffer)
             (equal (buffer-name) hyrolo-display-buffer))
           (and buffer-file-name
                (boundp 'hyrolo-file-list)
                (set:member (current-buffer)
                            (mapcar 'get-file-buffer hyrolo-file-list)))))
    (let ((address (mail-address-at-p)))
      (when address
        (ibut:label-set address (match-beginning 1) (match-end 1))
        (hact 'mail-other-window nil address)))))

;;; ========================================================================
;;; Displays files and directories when a valid pathname is activated.
;;; ========================================================================

(defib pathname ()
  "Make a valid pathname display the path entry.
Also works for delimited and non-delimited remote pathnames,
Texinfo @file{} entries, and hash-style link references to HTML,
XML, SGML, Markdown or Emacs outline headings, shell script
comments, and MSWindows paths (see \"${hyperb:dir}/DEMO#POSIX and
MSWindows Paths\" for details).  Emacs Lisp library
files (filenames without any directory component that end in .el,
.elc or .eln) are looked up using the `load-path' directory list.

The pathname may contain references to Emacs Lisp variables or
shell environment variables using the syntax, \"${variable-name}\".

See `hpath:at-p' function documentation for possible delimiters.
See `hpath:suffixes' variable documentation for suffixes that are
added to or removed from pathname when searching for a valid
match.  See `hpath:find' function documentation for special file
display options."
  ;;
  ;; Ignore paths in Buffer menu, dired and helm modes.
  (unless (or (derived-mode-p 'helm-major-mode)
              (delq nil (mapcar (lambda (substring)
                                  (string-match substring (format-mode-line mode-name)))
                                '("Buffer Menu" "IBuffer" "Dired"))))
    (let ((path (hpath:at-p))
          full-path)
      (if path
          (progn (when (string-match "\\`file://" path)
                   (setq path (substring path (match-end 0))))
                 (apply #'ibut:label-set path (hpath:start-end path))
                 (hact 'link-to-file path))
        ;;
        ;; Match PATH-related Environment and Lisp variable names and
	;; to Emacs Lisp and Info files without any directory component.
        (when (setq path (hpath:delimited-possible-path))
          (cond ((and (string-match hpath:path-variable-regexp path)
		      (setq path (match-string 1 path))
		      (hpath:is-path-variable-p path))
		 (setq path (if (or assist-flag (hyperb:stack-frame '(hkey-help)))
				path
			      (hpath:choose-from-path-variable path "Display")))
		 (unless (or (null path) (string-empty-p path))
		   (hact 'link-to-file path)))
		((string-match "\\`[^\\\\/~]+\\.el[cn]?\\(\\.gz\\)?\\'" path)
                 (apply #'ibut:label-set path (hpath:start-end path))
                 (if (string-match hpath:prefix-regexp path)
                     (hact 'hpath:find path)
                   (setq full-path (locate-library path t))
                   (if full-path
                       (hact 'link-to-file full-path)
                     (hact 'error "(pathname): \"%s\" not found in `load-path'"
                           path))))
                ;; Match only if "(filename)" references a valid Info file
                ;; and point is within the filename, not on any delimiters
                ;; so that delimited thing matches trigger later.
                ((and (not (looking-at "[\"()]"))
                      (string-match "\\`(\\([^ \t\n\r\f]+\\))\\'" path)
                      (save-match-data (require 'info))
                      (Info-find-file (match-string 1 path) t))
                 (apply #'ibut:label-set path (hpath:start-end path))
                 (hact 'link-to-Info-node (format "%sTop" path)))
                ((string-match hpath:info-suffix path)
                 (apply #'ibut:label-set path (hpath:start-end path))
                 (hact 'link-to-Info-node (format "(%s)Top" path)))
                ;; Otherwise, fall through and allow other implicit
                ;; button types to handle this context.
                ))))))

;;; ========================================================================
;;; Use the XEmacs func-menu library to jump to a function referred to
;;; in the same file in which it is defined.  Function references
;;; across files are handled separately by clauses within the
;;; `hkey-alist' variable.
;;; ========================================================================

(defib function-in-buffer ()
  "Display the in-buffer definition of a function name that point is within or after, else nil.
Trigger only when the \"func-menu.el\" library has been loaded and the
current major mode is one handled by func-menu."
  (when (and (boundp 'fume-function-name-regexp-alist)
             (assq major-mode fume-function-name-regexp-alist)
             (not (derived-mode-p 'dired-mode))
             ;; Not sure if this is defined in early versions of Emacs.
             (fboundp 'skip-syntax-backward)
             ;; Prevent triggering when on method, class or function definition
             ;; lines under InfoDock where outlining in programming modes is used.
             (if (and (featurep 'infodock)
                      (boundp 'id-outline-in-programming-modes)
                      id-outline-in-programming-modes
                      (boundp 'outline-regexp) (stringp outline-regexp))
                 (save-excursion (beginning-of-line)
                                 (not (looking-at outline-regexp)))
               t))
    (save-excursion
      (skip-syntax-backward "w_")
      (when (looking-at "\\(\\sw\\|\\s_\\)+")
        (let ((function-name (buffer-substring-no-properties (point) (match-end 0)))
              (start (point))
              (end (match-end 0))
              function-pos)
          (unless fume-funclist
            (fume-set-defaults)
            (let ((fume-scanning-message nil))
              (fume-rescan-buffer)))
          (setq function-pos (cdr-safe (assoc function-name fume-funclist)))
          (when function-pos
            (ibut:label-set function-name start end)
            (hact 'function-in-buffer function-name function-pos)))))))

;;; ========================================================================
;;; Handles internal references within an annotated bibliography, delimiters=[]
;;; ========================================================================

(defib annot-bib ()
  "Display annotated bibliography entries referenced internally.
References must be delimited by square brackets, must begin with a word
constituent character, not contain @ or # characters, must not be
in buffers whose names begin with a space or asterisk character, and
must have an attached file."
  (and (not (bolp))
       buffer-file-name
       (let ((chr (aref (buffer-name) 0)))
         (not (or (eq chr ?\ ) (eq chr ?*))))
       (not (or (derived-mode-p 'prog-mode)
                (apply #'derived-mode-p '(c-mode objc-mode c++-mode java-mode markdown-mode org-mode))))
       (let* ((ref-and-pos (hbut:label-p t "[" "]" t))
              (ref (car ref-and-pos)))
         (and ref (eq ?w (char-syntax (aref ref 0)))
              (not (string-match "[#@]" ref))
              (progn (ibut:label-set ref-and-pos)
                     (hact 'annot-bib ref))))))

;;; ========================================================================
;;; Handles social media hashtag and username references, e.g. twitter#myhashtag
;;; ========================================================================

(load "hib-social")

;;; ========================================================================
;;; Displays in-file Markdown link referents.
;;; ========================================================================

(defun markdown-follow-link-p ()
  "Jump between reference links and definitions; between footnote markers and footnote text.
Return t if jump and nil otherwise."
  (cond
   ;; Footnote definition
   ((markdown-footnote-text-positions)
    (markdown-footnote-return)
    t)
   ;; Footnote marker
   ((markdown-footnote-marker-positions)
    (markdown-footnote-goto-text)
    t)
   ;; Reference link
   ((thing-at-point-looking-at markdown-regex-link-reference)
    (markdown-reference-goto-definition)
    t)
   ;; Reference definition
   ((thing-at-point-looking-at markdown-regex-reference-definition)
    (markdown-reference-goto-link (match-string-no-properties 2))
    t)))

(defun markdown-follow-inline-link-p (opoint)
  "Test to see if on an inline link, jump to its referent if it is absolute (not relative within the file) and return non-nil.
Otherwise, if an internal link, move back to OPOINT and return nil."
  (let (handle-link-flag
        result)
    (skip-chars-forward "^\]\[()")
    (when (looking-at "\][\[()]")
      (if (looking-at "\(")
          (skip-chars-backward "^\]\[()")
        (skip-chars-forward "\]\[\("))
      ;; Leave point on the link even if not activated
      ;; here, so that other ibtypes activate it.  If point is after
      ;; the # character of an in-file link, then the following predicate
      ;; fails and the `pathname' ibtype will handle it.  If point is before
      ;; the # character, the link is handled here.
      (setq handle-link-flag (not (or (hpath:www-at-p) (hpath:at-p))))
      (when (setq result (and (markdown-link-p) handle-link-flag))
        ;; In-file referents are handled by the `pathname' implicit
        ;; button type, not here.
        (ibut:label-set (match-string-no-properties 0) (match-beginning 0) (match-end 0))
        (hpath:display-buffer (current-buffer))
        (hact 'markdown-follow-link-at-point)))
    (when handle-link-flag
      (goto-char opoint))
    result))

(defib markdown-internal-link ()
  "Display any in-file Markdown link referent at point.
Pathnames and urls are handled elsewhere."
  (when (and (derived-mode-p 'markdown-mode)
             (not (hpath:www-at-p)))
    (let ((opoint (point))
          npoint)
      (cond ((markdown-link-p)
             (condition-case ()
                 ;; Follows a reference link or footnote to its referent.
                 (if (markdown-follow-link-p)
                     (when (/= opoint (point))
                       (ibut:label-set (match-string-no-properties 0) (match-beginning 0) (match-end 0))
                       (setq npoint (point))
                       (goto-char opoint)
                       (hact 'link-to-file buffer-file-name npoint))
                   ;; Follows an absolute file link.
                   (markdown-follow-inline-link-p opoint))
               ;; May be on the name of an infile link, so move to the
               ;; link itself and then let the `pathname' ibtype handle it.
               (error (markdown-follow-inline-link-p opoint))))
            ((markdown-wiki-link-p)
             (ibut:label-set (match-string-no-properties 0) (match-beginning 0) (match-end 0))
             (hpath:display-buffer (current-buffer))
             (hact 'markdown-follow-wiki-link-at-point))))))

;;; ========================================================================
;;; Summarizes an Internet rfc for random access browsing by section.
;;; ========================================================================

(defib rfc-toc ()
  "Summarize the contents of an Internet rfc from anywhere within an rfc buffer.
Each line in the summary may be selected to jump to a section."
  (let ((case-fold-search t)
        (toc)
        (opoint (point)))
    (if (and (string-match "\\`rfc[-_]?[0-9]" (buffer-name))
	     (not (string-match "toc" (buffer-name)))
             (goto-char (point-min))
             (progn (setq toc (search-forward "Table of Contents" nil t))
                    (re-search-forward "^[ \t]*1.0?[ \t]+[^ \t\n\r]" nil t
                                       (and toc 2))))
        (progn (beginning-of-line)
               (ibut:label-set (buffer-name))
               (hact 'rfc-toc (buffer-name) opoint (point)))
      (goto-char opoint)
      nil)))

;;; ========================================================================
;;; Expands or collapses C call trees and jumps to code definitions.
;;; ========================================================================

(defib id-cflow ()
  "Expand or collapse C call trees and jump to code definitions.
Require cross-reference tables built by the external `cxref' program of Cflow."
  (when (and (derived-mode-p 'id-cflow-mode)
             (not (eolp)))
    (let ((pnt (point)))
      (save-excursion
        (cond
         ;; If on a repeated function mark, display its previously
         ;; expanded tree.
         ((progn (skip-chars-backward " ")
                 (looking-at id-cflow-repeated-indicator))
          (let ((end (point))
                start entry)
            (beginning-of-line)
            (skip-chars-forward "| ")
            (setq start (point)
                  entry (buffer-substring-no-properties start end))
            (ibut:label-set entry start end)
            (condition-case ()
                (hact 'link-to-regexp-match
                      (concat "^[| ]*[&%%]*" (regexp-quote entry) "$")
                      1 (current-buffer) t)
              (error
               (goto-char end)
               (error "(id-cflow): No prior expansion found")))))
         ;; If to the left of an entry, expand or contract its tree.
         ((progn (beginning-of-line)
                 (or (= pnt (point))
                     (and (looking-at "[| ]+")
                          (<= pnt (match-end 0)))))
          (hact 'id-cflow-expand-or-contract current-prefix-arg))
         ;; Within an entry's filename, display the file.
         ((search-forward "\(" pnt t)
          (let* ((start (point))
                 (end (1- (search-forward "\)" nil t)))
                 (file (buffer-substring-no-properties start end)))
            (ibut:label-set file start end)
            (hact 'link-to-file file)))
         ;; Within an entry's function name, jump to its definition.
         (t
          (hact 'smart-c)))))))

;;; ========================================================================
;;; Jumps to the source line associated with a ctags file entry.
;;; ========================================================================

(defib ctags ()
  "Jump to the source line associated with a ctags file entry in any buffer."
  (save-excursion
    (beginning-of-line)
    (cond
     ((looking-at "^\\(\\S-+\\) \\(\\S-+\\.[a-zA-Z]+\\) \\([1-9][0-9]*\\)$")
      ;;             identifier       pathname              line-number
      ;; ctags vgrind output format entry
      (let ((identifier (match-string-no-properties 1))
            (file (expand-file-name (match-string-no-properties 2)))
            (line-num (string-to-number (match-string-no-properties 3))))
        (ibut:label-set identifier (match-beginning 1) (match-end 1))
        (hact 'link-to-file-line file line-num)))
     ((looking-at "^\\(\\S-+\\) +\\([1-9][0-9]*\\) \\(\\S-+\\.[a-zA-Z]+\\) ")
      ;; ctags cxref output format entry
      ;;             identifier    line-number           pathname
      (let ((identifier (match-string-no-properties 1))
            (line-num (string-to-number (match-string-no-properties 2)))
            (file (expand-file-name (match-string-no-properties 3))))
        (ibut:label-set identifier (match-beginning 1) (match-end 1))
        (hact 'link-to-file-line file line-num))))))

;;; ========================================================================
;;; Jumps to the source line associated with an etags file entry in a TAGS buffer.
;;; ========================================================================

(defib etags ()
  "Jump to the source line associated with an etags file entry in a TAGS buffer.
If on a tag entry line, jump to the source line for the tag.  If on a
pathname line or line preceding it, jump to the associated file."
  (when (let (case-fold-search) (string-match "^TAGS" (buffer-name)))
    (save-excursion
      (beginning-of-line)
      (cond
       ((save-excursion
          (and (or (and (eq (following-char) ?\^L)
                        (zerop (forward-line 1)))
                   (and (zerop (forward-line -1))
                        (eq (following-char) ?\^L)
                        (zerop (forward-line 1))))
               (looking-at "\\([^,\n\r]+\\),[0-9]+$")))
        (let ((file (match-string-no-properties 1)))
          (ibut:label-set file (match-beginning 1) (match-end 1))
          (hact 'link-to-file file)))
       ((looking-at
         "\\([^\^?\n\r]+\\)[ ]*\^?\\([^\^A\n\r]+\^A\\)?\\([1-9][0-9]+\\),")
        (let* ((tag-grouping (if (match-beginning 2) 2 1))
               (tag (buffer-substring-no-properties (match-beginning tag-grouping)
                                                    (1- (match-end tag-grouping))))
               (line (string-to-number (match-string-no-properties 3)))
               file)
          (ibut:label-set tag (match-beginning tag-grouping)
                          (1- (match-end tag-grouping)))
          (save-excursion
            (if (re-search-backward "\^L\r?\n\\([^,\n\r]+\\),[0-9]+$" nil t)
                (setq file (expand-file-name (match-string-no-properties 1)))
              (setq file "No associated file name")))
          (hact 'link-to-file-line file line)))))))

;;; ========================================================================
;;; Jumps to C/C++ source line associated with Cscope C analyzer output line.
;;; ========================================================================

(defib cscope ()
  "Jump to C/C++ source line associated with Cscope C analyzer output line.
The cscope.el Lisp library available from the Emacs package manager
must be loaded and the open source cscope program available from
http://cscope.sf.net must be installed for this button type to do
anything."
  (and (boundp 'cscope:bname-prefix)  ;; (featurep 'cscope)
       (stringp cscope:bname-prefix)
       (string-match (regexp-quote cscope:bname-prefix)
                     (buffer-name))
       (= (match-beginning 0) 0)
       (save-excursion
         (beginning-of-line)
         (looking-at cscope-output-line-regexp))
       (let (start end)
         (skip-chars-backward "^\n\r")
         (setq start (point))
         (skip-chars-forward "^\n\r")
         (setq end (point))
         (ibut:label-set (buffer-substring start end)
                         start end)
         (hact 'cscope-interpret-output-line))))

;;; ========================================================================
;;; Makes README table of contents entries jump to associated sections.
;;; ========================================================================

(defib text-toc ()
  "Jump to the text file section referenced by a table of contents entry at point.
File name must contain DEMO, README or TUTORIAL and there must be a `Table
of Contents' or `Contents' label on a line by itself (it may begin with
an asterisk), preceding the table of contents.  Each toc entry must begin
with some whitespace followed by one or more asterisk characters.
Each section header linked to by the toc must start with one or more
asterisk characters at the very beginning of the line."
  (let (section)
    (when (and (string-match "DEMO\\|README\\|TUTORIAL" (buffer-name))
               (save-excursion
                 (beginning-of-line)
                 ;; Entry line within a TOC
                 (when (looking-at "[ \t]+\\*+[ \t]+\\(.*[^ \t]\\)[ \t]*$")
                   (setq section (match-string-no-properties 1))))
               (progn (ibut:label-set section (match-beginning 1) (match-end 1))
                      t)
               (save-excursion (re-search-backward
                                "^\\*?*[ \t]*\\(Table of \\)?Contents[ \t]*$"
                                nil t)))
      (hact 'text-toc section))))

;;; ========================================================================
;;; Makes directory summaries into file list menus.
;;; ========================================================================

(defib dir-summary ()
  "Detect filename buttons in files named \"MANIFEST\" or \"DIR\".
Display selected files.  Each file name must be at the beginning of the line
or may be preceded by some semicolons and must be followed by one or more
spaces and then another non-space, non-parenthesis, non-brace character."
  (when buffer-file-name
    (let ((file (file-name-nondirectory buffer-file-name))
          entry start end)
      (when (and (or (string-equal file "DIR")
                     (string-match "\\`MANIFEST\\(\\..+\\)?\\'" file))
		 (save-excursion
		   (beginning-of-line)
		   (when (looking-at "\\(;+[ \t]*\\)?\\([^(){}* \t\n\r]+\\)")
		     (setq entry (match-string-no-properties 2)
			   start (match-beginning 2)
			   end (match-end 2))
		     (file-exists-p entry))))
        (ibut:label-set entry start end)
        (hact 'link-to-file entry)))))

;;; ========================================================================
;;; Handles Gnu debbugs issue ids, e.g. bug#45678 or just 45678.
;;; ========================================================================

(load "hib-debbugs")

;;; ========================================================================
;;; Executes or documents command bindings of brace delimited key sequences.
;;; ========================================================================

(load "hib-kbd")

;;; ========================================================================
;;; Makes Internet RFC references retrieve the RFC.
;;; ========================================================================

(defib rfc ()
  "Retrieve and display an Internet Request for Comments (RFC) at point.
The following formats are recognized: RFC822, rfc-822, and RFC 822.  The
`hpath:rfc' variable specifies the location from which to retrieve RFCs.
Requires the Emacs builtin Tramp library for ftp file retrievals."
  (let ((case-fold-search t)
        (rfc-num nil))
    (and (not (memq major-mode '(dired-mode monkey-mode)))
         (boundp 'hpath:rfc)
         (stringp hpath:rfc)
         (or (looking-at " *\\(rfc[- ]?\\([0-9]+\\)\\)")
             (save-excursion
               (skip-chars-backward "0-9")
               (skip-chars-backward "- ")
               (skip-chars-backward "rRfFcC")
               (looking-at " *\\(rfc[- ]?\\([0-9]+\\)\\)")))
         (progn (setq rfc-num (match-string-no-properties 2))
                (ibut:label-set (match-string-no-properties 1))
                t)
         ;; Ensure remote file access is available for retrieving a remote
         ;; RFC, if need be.
         (if (string-match "^/.+:" hpath:rfc)
             ;; This is a remote path.
             (hpath:remote-available-p)
           ;; local path
           t)
         (hact 'link-to-rfc rfc-num))))

;;; ========================================================================
;;; Shows man page associated with a man apropos entry.
;;; ========================================================================

(defib man-apropos ()
  "Make man apropos entries display associated man pages when selected."
  (save-excursion
    (beginning-of-line)
    (let ((nm "[^ \t\n\r!@,:;(){}][^ \t\n\r,(){}]*[^ \t\n\r@.,:;(){}]")
          topic)
      (and (looking-at
            (concat
             "^\\(\\*[ \t]+[!@]\\)?\\(" nm "[ \t]*,[ \t]*\\)*\\(" nm "\\)[ \t]*"
             "\\(([-0-9a-zA-z]+)\\)\\(::\\)?[ \t]+-[ \t]+[^ \t\n\r]"))
           (setq topic (concat (match-string-no-properties 3)
                               (match-string-no-properties 4)))
           (ibut:label-set topic (match-beginning 3) (match-end 4))
           (hact 'man topic)))))

;;; ========================================================================
;;; Follows links to Hyperbole Koutliner cells.
;;; ========================================================================

(load "klink")

;;; ========================================================================
;;; Links to Hyperbole button types
;;; ========================================================================

(defun hlink (link-actype label-prefix start-delim end-delim)
  "Call LINK-ACTYPE as the action type and prefix button with LABEL-PREFIX if point is within an implicit button delimited by START-DELIM and END-DELIM."
  ;; Used by e/g/ilink implicit buttons."
  (let* ((label-start-end (hbut:label-p t start-delim end-delim t t))
         (label-and-file (nth 0 label-start-end))
         (start-pos (nth 1 label-start-end))
         (end-pos (nth 2 label-start-end))
         lbl but-key lbl-key key-file)
    (when label-and-file
      (setq label-and-file (parse-label-and-file label-and-file)
            partial-lbl (nth 0 label-and-file)
            but-key (hbut:label-to-key partial-lbl)
            key-file (nth 1 label-and-file)
            lbl-key (when but-key (concat label-prefix but-key)))
      (ibut:label-set (hbut:key-to-label lbl-key) start-pos end-pos)
      (hact link-actype but-key key-file))))

(defun parse-label-and-file (label-and-file)
  "Parse a colon-separated string of button label and source file path into a list of label and file."
  ;; Can't use split-string here because file path may contain colons;
  ;; we want to split only on the first colon.
  (let ((i 0)
        (len (length label-and-file))
        label
        file)
    (while (< i len)
      (when (= ?: (aref label-and-file i))
        (when (zerop i)
          (error "(parse-label-and-file): Missing label: '%s'" label-and-file))
        (setq label (hpath:trim (substring label-and-file 0 i))
              file (hpath:trim (substring label-and-file (1+ i))))
        (when (string-empty-p label) (setq label nil))
        (when (string-empty-p file) (setq file nil))
        (setq i len))
      (setq i (1+ i)))
    (unless (or label (string-empty-p label-and-file))
      (setq label label-and-file))
    (delq nil (list label file))))

(defconst elink:start "<elink:"
  "String matching the start of a link to a Hyperbole explicit button.")
(defconst elink:end   ">"
  "String matching the end of a link to a Hyperbole explicit button.")

(defib elink ()
  "At point, activate a link to an explicit button.
This executes the linked to explicit button's action in the
context of the current buffer.

Recognizes the format '<elink:' button_label [':' button_file_path] '>',
where : button_file_path is given only when the link is to another file,
e.g. <elink: project-list: ~/projs>."
  (hlink 'link-to-ebut "elink_" elink:start elink:end))

(defconst glink:start "<glink:"
  "String matching the start of a link to a Hyperbole global button.")
(defconst glink:end   ">"
  "String matching the end of a link to a Hyperbole global button.")

(defib glink ()
  "At point, activates a link to a global button.
This executes the linked to global button's action in the context
of the current buffer.

Recognizes the format '<glink:' button_label '>',
e.g. <glink: open todos>."
  (hlink 'link-to-gbut "glink_" glink:start glink:end))

(defconst ilink:start "<ilink:"
  "String matching the start of a link to a Hyperbole implicit button.")
(defconst ilink:end   ">"
  "String matching the end of a link to a Hyperbole implicit button.")

(defib ilink ()
  "At point, activate a link to a labeled implicit button.
This executes the linked to implicit button's action in the context of the
current buffer.

Recognizes the format '<ilink:' button_label [':' button_file_path] '>',
where button_file_path is given only when the link is to another file,
e.g. <ilink: my series of keys: ${hyperb:dir}/HYPB>."
  (hlink 'link-to-ibut "ilink_" ilink:start ilink:end))

;;; ========================================================================
;;; Jumps to source line associated with ipython, ripgrep, grep or
;;; compilation errors.
;;; ========================================================================

(defib ipython-stack-frame ()
  "Jump to the line associated with an ipython stack frame line numbered msg.
ipython outputs each pathname once followed by all matching lines in that pathname.
Messages are recognized in any buffer (other than a helm completion
buffer)."
  ;; Locate and parse ipython stack trace messages found in any buffer other than a
  ;; helm completion buffer.
  ;;
  ;; Sample ipython stack trace command output:
  ;;
  ;; ~/Dropbox/py/inview/inview_pr.py in ap(name_filter, value_filter, print_func)
  ;; 1389     apc(name_filter, value_filter, print_func, defined_only=True)
  ;; 1390     print('\n**** Modules/Packages ****')
  ;; -> 1391     apm(name_filter, value_filter, print_func, defined_only=True)
  ;; 1392
  ;; 1393 def apa(name_filter=None, value_filter=None, print_func=pd1, defined_only=False):
  (unless (derived-mode-p 'helm-major-mode)
    (save-excursion
      (beginning-of-line)
      (let ((line-num-regexp "\\( *\\|-+> \\)?\\([1-9][0-9]*\\) ")
            line-num
            file)
        (when (looking-at line-num-regexp)
          ;; ipython stack trace matches and context lines (-A<num> option)
          (setq line-num (match-string-no-properties 2)
                file nil)
          (while (and (= (forward-line -1) 0)
                      (looking-at line-num-regexp)))
          (unless (or (looking-at line-num-regexp)
                      (not (re-search-forward " in " nil (point-at-eol)))
                      (and (setq file (buffer-substring-no-properties (point-at-bol) (match-beginning 0)))
                           (string-empty-p (string-trim file))))
            (let* ((but-label (concat file ":" line-num))
                   (source-loc (unless (file-name-absolute-p file)
                                 (hbut:key-src t))))
              (when (stringp source-loc)
                (setq file (expand-file-name file (file-name-directory source-loc))))
              (when (file-readable-p file)
                (setq line-num (string-to-number line-num))
                (ibut:label-set but-label)
                (hact 'link-to-file-line file line-num)))))))))

(defib ripgrep-msg ()
  "Jump to the line associated with a ripgrep (rg) line numbered msg.
Ripgrep outputs each pathname once followed by all matching lines in that pathname.
Messages are recognized in any buffer (other than a helm completion
buffer)."
  ;; Locate and parse ripgrep messages found in any buffer other than a
  ;; helm completion buffer.
  ;;
  ;; Sample ripgrep command output:
  ;;
  ;; bash-3.2$ rg -nA2 hkey-throw *.el
  ;; hmouse-drv.el
  ;; 405:(defun hkey-throw (release-window)
  ;; 406-  "Throw either a displayable item at point or the current buffer to RELEASE-WINDOW.
  ;; 407-The selected window does not change."
  ;; --
  ;; 428:    (hkey-throw to-window)))
  ;; 429-
  ;; 430-(defun hmouse-click-to-drag ()
  ;;
  ;; Use `rg -n --no-heading' for pathname on each line.
  (unless (derived-mode-p 'helm-major-mode)
    (save-excursion
      (beginning-of-line)
      (when (looking-at "\\([1-9][0-9]*\\)[-:]")
        ;; Ripgrep matches and context lines (-A<num> option)
        (let ((line-num (match-string-no-properties 1))
              file)
          (while (and (= (forward-line -1) 0)
                      (looking-at "[1-9][0-9]*[-:]\\|--$")))
          (unless (or (looking-at "[1-9][0-9]*[-:]\\|--$")
                      (and (setq file (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
                           (string-empty-p (string-trim file))))
            (let* ((but-label (concat file ":" line-num))
                   (source-loc (unless (file-name-absolute-p file)
                                 (hbut:key-src t))))
              (when (stringp source-loc)
                (setq file (expand-file-name file (file-name-directory source-loc))))
              (when (file-readable-p file)
                (setq line-num (string-to-number line-num))
                (ibut:label-set but-label)
                (hact 'link-to-file-line file line-num)))))))))

(defib grep-msg ()
  "Jump to the line associated with line numbered grep or compilation error msgs.
Messages are recognized in any buffer (other than a helm completion
buffer) except for grep -A<num> context lines which are matched only
in grep and shell buffers."
  ;; Locate and parse grep messages found in any buffer other than a
  ;; helm completion buffer.
  (unless (derived-mode-p 'helm-major-mode)
    (save-excursion
      (beginning-of-line)
      (when (or
             ;; Grep matches, UNIX C compiler and Introl 68HC11 C compiler errors
             (looking-at "\\([^ \t\n\r:]+\\): ?\\([1-9][0-9]*\\)[ :]")
             ;; Grep matches, UNIX C compiler and Introl 68HC11 C
             ;; compiler errors, allowing for file names with
             ;; spaces followed by a null character rather than a :
             (looking-at "\\([^\t\n\r]+\\)  ?\\([1-9][0-9]*\\)[ :]")
             ;; HP C compiler errors
             (looking-at "[a-zA-Z0-9]+: \"\\([^\t\n\r\",]+\\)\", line \\([0-9]+\\):")
             ;; BSO/Tasking 68HC08 C compiler errors
             (looking-at
              "[a-zA-Z 0-9]+: \\([^ \t\n\r\",]+\\) line \\([0-9]+\\)[ \t]*:")
             ;; UNIX Shell errors
             (looking-at "\\([^:]+\\): line \\([0-9]+\\): ")
             ;; UNIX Lint errors
             (looking-at "[^:]+: \\([^ \t\n\r:]+\\): line \\([0-9]+\\):")
             ;; SparcWorks C compiler errors (ends with :)
             ;; IBM AIX xlc C compiler errors (ends with .)
             (looking-at "\"\\([^\"]+\\)\", line \\([0-9]+\\)[:.]")
             ;; Introl as11 assembler errors
             (looking-at " \\*+ \\([^ \t\n\r]+\\) - \\([0-9]+\\) ")
             ;; perl5: ... at file.c line 10
             (looking-at ".+ at \\([^ \t\n\r]+\\) line +\\([0-9]+\\)")
             ;; Weblint
             (looking-at "\\([^ \t\n\r:()]+\\)(\\([0-9]+\\)): ")
             ;; Microsoft JVC
             ;; file.java(6,1) : error J0020: Expected 'class' or 'interface'
             (looking-at "^\\(\\([a-zA-Z]:\\)?[^:\( \t\n\r-]+\\)[:\(][ \t]*\\([0-9]+\\),")
             ;; Grep match context lines (-A<num> option)
             (and (string-match "grep\\|shell" (buffer-name))
                  (looking-at "\\([^ \t\n\r:]+\\)-\\([1-9][0-9]*\\)-")))
        (let* ((file (match-string-no-properties 1))
               (line-num  (match-string-no-properties 2))
               (but-label (concat file ":" line-num))
               (source-loc (unless (file-name-absolute-p file)
                             (hbut:key-src t))))
          (when (stringp source-loc)
            (setq file (expand-file-name file (file-name-directory source-loc))))
          (setq line-num (string-to-number line-num))
          (ibut:label-set but-label)
          (hact 'link-to-file-line file line-num))))))

;;; ========================================================================
;;; Jumps to source line associated with debugger stack frame or breakpoint
;;; lines.  Supports gdb, dbx, and xdb.
;;; ========================================================================

(defib debugger-source ()
  "Jump to source line associated with stack frame or breakpoint lines.
This works with JavaScript and Python tracebacks, gdb, dbx, and xdb.  Such lines are recognized in any buffer."
  (save-excursion
    (beginning-of-line)
    (cond
     ;; Python pdb or traceback, pytype error
     ((or (looking-at "\\(^\\|.+ \\)File \"\\([^\"\n\r]+\\)\", line \\([0-9]+\\)")
          (looking-at ">?\\(\\s-+\\)\\([^\"()\n\r]+\\)(\\([0-9]+\\))\\S-"))
      (let* ((file (match-string-no-properties 2))
             (line-num (match-string-no-properties 3))
             (but-label (concat file ":" line-num)))
        (setq line-num (string-to-number line-num))
        (ibut:label-set but-label (match-beginning 2) (match-end 2))
        (hact 'link-to-file-line file line-num)))

     ;; JavaScript traceback
     ((or (looking-at "[a-zA-Z0-9-:.()? ]+? +at \\([^() \t]+\\) (\\([^:, \t()]+\\):\\([0-9]+\\):\\([0-9]+\\))$")
          (looking-at "[a-zA-Z0-9-:.()? ]+? +at\\( \\)\\([^:, \t()]+\\):\\([0-9]+\\):\\([0-9]+\\)$")
          (looking-at "[a-zA-Z0-9-:.()? ]+?\\( \\)\\([^:, \t()]+\\):\\([0-9]+\\)\\(\\)$"))
      (let* ((file (match-string-no-properties 2))
             (line-num (match-string-no-properties 3))
             (col-num (match-string-no-properties 4))
             but-label)

        ;; For Meteor app errors, remove the "app/" prefix which
        ;; is part of the build subdirectory and not part of the
        ;; source tree.
        (when (and (not (eq col-num "")) (string-match "^app/" file))
          (setq file (substring file (match-end 0))))

        (setq but-label (concat file ":" line-num)
              line-num (string-to-number line-num))
        (ibut:label-set but-label)
        (hact 'link-to-file-line file line-num)))

     ;; GDB or WDB
     ((looking-at
       ".+ \\(at\\|file\\) \\([^ :,]+\\)\\(:\\|, line \\)\\([0-9]+\\)\\.?$")
      (let* ((file (match-string-no-properties 2))
             (line-num (match-string-no-properties 4))
             (but-label (concat file ":" line-num))
             (gdb-last-file (or (and (boundp 'gud-last-frame)
                                     (stringp (car gud-last-frame))
                                     (car gud-last-frame))
                                (and (boundp 'gdb-last-frame)
                                     (stringp (car gdb-last-frame))
                                     (car gdb-last-frame)))))
        (setq line-num (string-to-number line-num))
        ;; The `file' typically has no directory component and so may
        ;; not be resolvable.  `gdb-last-file' is the last file
        ;; displayed by gdb.  Use its directory if available as a best
        ;; guess.
        (when gdb-last-file
          (setq file (expand-file-name file (file-name-directory gdb-last-file))))
        (ibut:label-set but-label)
        (hact 'link-to-file-line file line-num)))

     ;; XEmacs assertion failure
     ((looking-at ".+ (file=[^\"\n\r]+\"\\([^\"\n\r]+\\)\", line=\\([0-9]+\\),")
      (let* ((file (match-string-no-properties 1))
             (line-num (match-string-no-properties 2))
             (but-label (concat file ":" line-num)))
        (setq line-num (string-to-number line-num))
        (ibut:label-set but-label)
        (hact 'link-to-file-line file line-num)))

     ;; New DBX
     ((looking-at ".+ line \\([0-9]+\\) in \"\\([^\"]+\\)\"$")
      (let* ((file (match-string-no-properties 2))
             (line-num (match-string-no-properties 1))
             (but-label (concat file ":" line-num)))
        (setq line-num (string-to-number line-num))
        (ibut:label-set but-label)
        (hact 'link-to-file-line file line-num)))

     ;; Old DBX and HP-UX xdb
     ((or (looking-at ".+ \\[\"\\([^\"]+\\)\":\\([0-9]+\\),") ;; Old DBX
          (looking-at ".+ \\[\\([^: ]+\\): \\([0-9]+\\)\\]")) ;; HP-UX xdb
      (let* ((file (match-string-no-properties 1))
             (line-num (match-string-no-properties 2))
             (but-label (concat file ":" line-num)))
        (setq line-num (string-to-number line-num))
        (ibut:label-set but-label)
        (hact 'link-to-file-line file line-num)))

     ((not (boundp 'debugger-source-prior-line))
      ;; In Python tracebacks, may be on a line just below the source
      ;; reference line so if not on a Hyperbole button, move back a
      ;; line and check for a source line again.
      (let ((debugger-source-prior-line t))
	(unless (or (hbut:at-p)	(/= (forward-line -1) 0))
	  (ibtypes::debugger-source)))))))

;;; ========================================================================
;;; Displays files at specific lines and optional column number
;;; locations.
;;; ========================================================================

(defib pathname-line-and-column ()
  "Make a valid pathname:line-num[:column-num] pattern display the path at line-num and optional column-num.
Also works for remote pathnames.
May also contain hash-style link references with the following format:
\"<path>[#<link-anchor>]:<line-num>[:<column-num>]}\".

See `hpath:at-p' function documentation for possible delimiters.
See `hpath:suffixes' variable documentation for suffixes that are added to or
removed from pathname when searching for a valid match.
See `hpath:find' function documentation for special file display options."
  (let ((path-line-and-col (hpath:delimited-possible-path)))
    (when (and (stringp path-line-and-col)
               (string-match hpath:section-line-and-column-regexp path-line-and-col))
      (let ((file (save-match-data (hpath:expand (match-string-no-properties 1 path-line-and-col))))
            (line-num (string-to-number (match-string-no-properties 3 path-line-and-col)))
            (col-num (when (match-end 4)
                       (string-to-number (match-string-no-properties 5 path-line-and-col)))))
        (when (save-match-data (setq file (hpath:is-p file)))
          (ibut:label-set file (match-beginning 1) (match-end 1))
          (if col-num
              (hact 'link-to-file-line-and-column file line-num col-num)
            (hact 'link-to-file-line file line-num)))))))

;;; ========================================================================
;;; Jumps to source of Emacs Lisp byte-compiler error messages.
;;; ========================================================================

(defib elisp-compiler-msg ()
  "Jump to source code for definition associated with an Emacs Lisp byte-compiler error message.
Works when activated anywhere within an error line."
  (when (or (member (buffer-name) '("*Compile-Log-Show*" "*Compile-Log*"
                                    "*compilation*"))
            (save-excursion
              (and (re-search-backward "^[^ \t\n\r]" nil t)
                   (looking-at "While compiling"))))
    (let (src buffer-p label)
      ;; InfoDock and XEmacs
      (or (and (save-excursion
                 (re-search-backward
                  "^Compiling \\(file\\|buffer\\) \\([^ \n]+\\) at "
                  nil t))
               (setq buffer-p (equal (match-string-no-properties 1) "buffer")
                     src (match-string-no-properties 2))
               (save-excursion
                 (end-of-line)
                 (re-search-backward "^While compiling \\([^ \n]+\\)\\(:$\\| \\)"
                                     nil t))
               (progn
                 (setq label (match-string-no-properties 1))
                 (ibut:label-set label (match-beginning 1) (match-end 1))
                 ;; Remove prefix generated by actype and ibtype definitions.
                 (setq label (hypb:replace-match-string "[^:]+::" label "" t))
                 (hact 'link-to-regexp-match
                       (concat "^\(def[a-z \t]+" (regexp-quote label)
                               "[ \t\n\r\(]")
                       1 src buffer-p)))
          ;; GNU Emacs
          (and (save-excursion
                 (re-search-backward
                  "^While compiling [^\t\n]+ in \\(file\\|buffer\\) \\([^ \n]+\\):$"
                  nil t))
               (setq buffer-p (equal (match-string-no-properties 1) "buffer")
                     src (match-string-no-properties 2))
               (save-excursion
                 (end-of-line)
                 (re-search-backward "^While compiling \\([^ \n]+\\)\\(:$\\| \\)"
                                     nil t))
               (progn
                 (setq label (match-string-no-properties 1))
                 (ibut:label-set label (match-beginning 1) (match-end 1))
                 ;; Remove prefix generated by actype and ibtype definitions.
                 (setq label (hypb:replace-match-string "[^:]+::" label "" t))
                 (hact 'link-to-regexp-match
                       (concat "^\(def[a-z \t]+" (regexp-quote label)
                               "[ \t\n\r\(]")
                       1 src buffer-p)))))))

;;; ========================================================================
;;; Jumps to source associated with a line of output from `patch'.
;;; ========================================================================

(defib patch-msg ()
  "Jump to source code associated with output from the `patch' program.
Patch applies diffs to source code."
  (when (save-excursion
          (beginning-of-line)
          (looking-at "Patching \\|Hunk "))
    (let ((opoint (point))
          (file) line)
      (beginning-of-line)
      (cond ((looking-at "Hunk .+ at \\([0-9]+\\)")
             (setq line (match-string-no-properties 1))
             (ibut:label-set line (match-beginning 1) (match-end 1))
             (if (re-search-backward "^Patching file \\(\\S +\\)" nil t)
                 (setq file (match-string-no-properties 1))))
            ((looking-at "Patching file \\(\\S +\\)")
             (setq file (match-string-no-properties 1)
                   line "1")
             (ibut:label-set file (match-beginning 1) (match-end 1))))
      (goto-char opoint)
      (when file
        (setq line (string-to-number line))
        (hact 'link-to-file-line file line)))))

;;; ========================================================================
;;; Displays Texinfo or Info node associated with Texinfo @xref, @pxref or @ref at point.
;;; ========================================================================

(defib texinfo-ref ()
  "Display Texinfo, Info node or help associated with Texinfo node, menu item, @xref, @pxref, @ref, @code, @findex, @var or @vindex at point.
If point is within the braces of a cross-reference, the associated
Info node is shown.  If point is to the left of the braces but after
the @ symbol and the reference is to a node within the current
Texinfo file, then the Texinfo node is shown.

For @code, @findex, @var and @vindex references, the associated documentation string is displayed."
  (when (memq major-mode '(texinfo-mode para-mode))
    (let ((opoint (point))
          (bol (save-excursion (beginning-of-line) (point))))
      (cond ((save-excursion
               (beginning-of-line)
               ;; If a menu item, display the node for the item.
               (looking-at "*\\s-+\\([^:\t\n\r]+\\)::"))
             (hact 'link-to-texinfo-node
                   nil
                   (ibut:label-set (match-string 1) (match-beginning 1) (match-end 1))))
            ;; Show doc for any Emacs Lisp identifier references,
            ;; marked with @code{} or @var{}.
            ((save-excursion
               (and (search-backward "@" bol t)
                    (or (looking-at "@\\(code\\|var\\){\\([^\} \t\n\r]+\\)}")
                        (looking-at "@\\(findex\\|vindex\\)[ ]+\\([^\} \t\n\r]+\\)"))
                    (>= (match-end 2) opoint)))
             (let ((type-str (match-string 1))
                   (symbol (intern-soft (ibut:label-set (match-string 2) (match-beginning 2) (match-end 2)))))
               (when (and symbol (pcase type-str
                                   ((or "code" "findex") (fboundp symbol))
                                   ((or "var" "vindex") (boundp symbol))))
                 (hact 'link-to-elisp-doc symbol))))
            ;; If at an @node and point is within a node name reference
            ;; other than the current node, display it.
            ((save-excursion
               (and (save-excursion (beginning-of-line) (looking-at "@node\\s-+[^,\n\r]+,"))
                    (search-backward "," bol t)
                    (looking-at ",\\s-*\\([^,\n\r]*[^, \t\n\r]\\)[,\n\r]")))
             (hact 'link-to-texinfo-node
                   nil
                   (ibut:label-set (match-string 1) (match-beginning 1) (match-end 1))))
            ((save-excursion
               (and (search-backward "@" bol t)
                    (looking-at
                     (concat
                      "@p?x?ref\\({\\)\\s-*\\([^,}]*[^,} \t\n\r]\\)\\s-*"
                      "\\(,[^,}]*\\)?\\(,[^,}]*\\)?"
                      "\\(,\\s-*\\([^,}]*[^,} \t\n\r]\\)\\)?[^}]*}"))
                    (> (match-end 0) opoint)))
             (let* ((show-texinfo-node
                     (and
                      ;; Reference to node within this file.
                      (not (match-beginning 6))
                      ;; To the left of the reference opening brace.
                      (<= opoint (match-beginning 1))))
                    (node
                     (save-match-data
                       (if (match-beginning 6)
                           ;; Explicit filename included in reference.
                           (format "(%s)%s"
                                   (match-string-no-properties 6)
                                   (match-string-no-properties 2))
                         ;; Derive file name from the source file name.
                         (let ((nodename (match-string-no-properties 2))
                               (file (file-name-nondirectory buffer-file-name)))
                           (if show-texinfo-node
                               nodename
                             (format "(%s)%s"
                                     (if (string-match "\\.[^.]+$" file)
                                         (substring file 0
                                                    (match-beginning 0))
                                       "unspecified file")
                                     nodename)))))))
               (ibut:label-set (match-string 0) (match-beginning 0) (match-end 0))
               (if show-texinfo-node
                   (hact 'link-to-texinfo-node nil node)
                 (hact 'link-to-Info-node node))))))))

;;; ========================================================================
;;; Activate any GNUS push-button at point.
;;; ========================================================================

(defib gnus-push-button ()
  "Activate GNUS-specific article push-buttons, e.g. for hiding signatures.
GNUS is a news and mail reader."
  (and (fboundp 'get-text-property)
       (get-text-property (point) 'gnus-callback)
       (fboundp 'gnus-article-press-button)
       (hact 'gnus-article-press-button)))

;;; ========================================================================
;;; Displays Info nodes when double quoted "(file)node" button is activated.
;;; ========================================================================

(defib Info-node ()
  "Make a \"(filename)nodename\" button display the associated Info node.
Also make a \"(filename)itemname\" button display the associated Info index item.
Examples are \"(hyperbole)Implicit Buttons\" and ``(hyperbole)C-c /''.

Activates only if point is within the first line of the Info-node name."
  (let* ((node-ref-and-pos (or (hbut:label-p t "\"" "\"" t t)
			       (hbut:label-p t "\\\"" "\\\"" t t)
                               ;; Typical GNU Info references; note
                               ;; these are special quote marks, not the
                               ;; standard ASCII characters.
                               (hbut:label-p t "‘" "’" t t)
                               (hbut:label-p t "‘" "’" t t)
                               ;; Regular dual single quotes (Texinfo smart quotes)
                               (hbut:label-p t "``" "''" t t)
                               ;; Regular open and close quotes
                               (hbut:label-p t "`" "'" t t)))
         (ref (car node-ref-and-pos))
         (node-ref (and (stringp ref)
                        (string-match "\\`([^\):]+)" ref)
                        (hpath:is-p (car node-ref-and-pos) nil t))))
    (and node-ref
         (ibut:label-set node-ref-and-pos)
         (hact 'link-to-Info-node node-ref))))

;;; ========================================================================
;;; Makes Hyperbole mail addresses output Hyperbole environment info.
;;; ========================================================================

(defib hyp-address ()
  "Within a mail or Usenet news composer window, make a Hyperbole support/discussion e-mail address insert Hyperbole environment and version information.
See also the documentation for `actypes::hyp-config'.

For example, an Action Mouse Key click on <hyperbole-users@gnu.org> in
a mail composer window would activate this implicit button type."
  (when (memq major-mode (list 'mail-mode hmail:composer hnews:composer))
    (let ((addr (thing-at-point 'email)))
      (cond ((null addr) nil)
            ((member addr '("hyperbole" "hyperbole-users@gnu.org" "bug-hyperbole@gnu.org"))
             (hact 'hyp-config))
            ((string-match "\\(hyperbole\\|hyperbole-users@gnu\\.org\\|bug-hyperbole@gnu\\.org\\)\\(-\\(join\\|leave\\|owner\\)\\)" addr)
             (hact 'hyp-request))))))

;;; ========================================================================
;;; Makes source entries in Hyperbole reports selectable.
;;; ========================================================================

(defib hyp-source ()
  "Turn source location entries in Hyperbole reports into buttons that jump to the associated location.

For example, {C-h h d d C-h h e h o} summarizes the properties of
the explicit buttons in the DEMO file and each button in that
report buffer behaves the same as the corresponding button in the
original DEMO file."
  (save-excursion
    (beginning-of-line)
    (when (looking-at hbut:source-prefix)
      (let ((src (hbut:source)))
        (when src
          (unless (stringp src)
            (setq src (prin1-to-string src)))
          (ibut:label-set src (point) (progn (end-of-line) (point)))
          (hact 'hyp-source src))))))

;;; ========================================================================
;;; Executes an angle bracket delimited Hyperbole action, Elisp
;;; function call or display of an Elisp variable and its value.
;;; ========================================================================

;; Allow for parameterized action-types surrounded by angle brackets.
;; For example, <man-show "grep"> should display grep's man page
;; (since man-show is an action type).

(defconst action:start "<"
  "Regexp matching the start of a Hyperbole Emacs Lisp expression to evaluate.")

(defconst action:end ">"
  "Regexp matching the end of a Hyperbole Emacs Lisp expression to evaluate.")

(defib action ()
  "The Action Button type: At point, activate any of: an Elisp variable, a Hyperbole action-type, or an Elisp function call surrounded by <> rather than ().
If an Elisp variable, display a message showing its value.

There may not be any <> characters within the expression.  The
first identifier in the expression must be an Elisp variable,
action type or a function symbol to call, i.e. '<'actype-or-elisp-symbol
arg1 ... argN '>'.  For example, <mail nil \"user@somewhere.org\">."
  (let* ((hbut:max-len 0)
         (label-key-start-end (ibut:label-p nil action:start action:end t))
         (ibut-key (nth 0 label-key-start-end))
         (start-pos (nth 1 label-key-start-end))
         (end-pos (nth 2 label-key-start-end))
         actype actype-sym action args lbl var-flag)
    ;; Continue only if start-delim is either:
    ;;     at the beginning of the buffer
    ;;     or preceded by a space character or a grouping character
    ;;   and that character after start-delim is:
    ;;     not a whitespace character
    ;;   and end-delim is either:
    ;;     at the end of the buffer
    ;;     or is followed by a space, punctuation or grouping character.
    (when (and ibut-key (or (null (char-before start-pos))
                            (memq (char-syntax (char-before start-pos)) '(?\  ?\> ?\( ?\))))
               (not (memq (char-syntax (char-after (1+ start-pos))) '(?\  ?\>)))
               (or (null (char-after end-pos))
                   (memq (char-syntax (char-after end-pos)) '(?\  ?\> ?. ?\( ?\)))
                   ;; Some of these characters may have symbol-constituent syntax
                   ;; rather than punctuation, so check them individually.
                   (memq (char-after end-pos) '(?. ?, ?\; ?: ?! ?\' ?\"))))
      (setq lbl (ibut:key-to-label ibut-key))
      ;; Handle $ preceding var name in cases where same name is
      ;; bound as a function symbol
      (when (string-match "\\`\\$" lbl)
        (setq var-flag t
              lbl (substring lbl 1)))
      (setq actype (if (string-match-p " " lbl) (car (split-string lbl)) lbl)
            actype-sym (intern-soft (concat "actypes::" actype))
            actype (or (and (or (fboundp actype-sym) (boundp actype-sym)) actype-sym)
                       (progn (setq actype-sym (intern-soft actype))
                              (and (or (fboundp actype-sym) (boundp actype-sym)) actype-sym))))
      ;; Ignore unbound symbols
      (unless (and actype (or (fboundp actype) (boundp actype) (special-form-p actype)))
        (setq actype nil))
      (when actype
        (ibut:label-set lbl start-pos end-pos)
        (setq action (read (concat "(" lbl ")"))
              args (cdr action))
        (cond ((and (symbolp actype) (fboundp actype)
                    (string-match "-p\\'" (symbol-name actype)))
               ;; Is a function with a boolean result
               (setq action `(display-boolean ',action)
                     actype #'display-boolean))
              ((and (null args) (symbolp actype) (boundp actype)
                    (or var-flag (not (fboundp actype))))
               ;; Is a variable, display its value as the action
               (setq args `(',actype)
                     action `(display-variable ',actype)
                     actype #'display-variable)))
        ;; Necessary so can return a null value, which actype:act cannot.
        (let ((hrule:action
               (if (eq hrule:action #'actype:identity)
                   #'actype:identity
                 #'actype:eval)))
          (if (eq hrule:action #'actype:identity)
              (apply hrule:action actype args)
            (apply hrule:action actype (mapcar #'eval args))))))))

;;; ========================================================================
;;; Inserts completion into minibuffer or other window.
;;; ========================================================================

(defib completion ()
  "Insert completion at point into minibuffer or other window."
  (let ((completion (hargs:completion t)))
    (and completion
         (ibut:label-set completion)
         (hact 'completion))))


(run-hooks 'hibtypes-end-load-hook)
(provide 'hibtypes)

;;; hibtypes.el ends here
