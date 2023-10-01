;;; git-cliff.el --- Generate and update changelog using git-cliff -*- lexical-binding: t -*-

;; Copyright (C) 2023 liuyinz

;; Author: liuyinz <liuyinz95@gmail.com>
;; Maintainer: liuyinz <liuyinz95@gmail.com>
;; Version: 0.3.1
;; Package-Requires: ((emacs "26.3") (transient "0.4.3"))
;; Keywords: tools
;; Homepage: https://github.com/liuyinz/git-cliff

;; This file is not a part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This file is not a part of GNU Emacs.

;;; Commentary:

;; This package provides the interface of `git-cliff`, built in transient, to
;; generate and update changelog for project.  Call `git-cliff-menu` to start.

;; configurations spec SEE https://git-cliff.org/docs/configuration/

;;; Code:

(require 'cl-lib)
(require 'transient)
(require 'lisp-mnt)
(require 'crm)
(require 'vc-git)

(declare-function 'markdown-view-mode "markdown-mode")

(defgroup git-cliff nil
  "Generate changelog based on git-cliff."
  :prefix "git-cliff-"
  :group 'git-cliff
  :link '(url-link :tag "GitHub" "https://github.com/liuyinz/git-cliff"))

(defconst git-cliff-version
  (lm-version (or load-file-name buffer-file-name))
  "The current version of `git-cliff.el'.")

(defcustom git-cliff-enable-examples t
  "If non-nil, configs in examples directory are included as presets."
  :package-version '(git-cliff . "0.1.0")
  :type 'boolean
  :group 'git-cliff)

(defcustom git-cliff-extra-dir nil
  "Directory storing user defined config presets and body templates."
  :package-version '(git-cliff . "0.1.0")
  :type 'string
  :group 'git-cliff)

(defcustom git-cliff-cache-file
  (locate-user-emacs-file "git-cliff-cache.el")
  "File used to save cached values of git-cliff."
  :package-version '(transient . "0.3.0")
  :type 'file
  :group 'git-cliff)

(defcustom git-cliff-release-message "chore(version): release %s"
  "Commit message when release new version."
  :package-version '(git-cliff . "0.3.0")
  :type 'string
  :group 'git-cliff)

(defface git-cliff-example
  '((t (:inherit font-lock-function-name-face)))
  "Face for git-cliff examples files set by default.")

(defface git-cliff-extra
  '((t (:inherit font-lock-constant-face)))
  "Face for git-cliff extra files defined by user.")

;; variables
(defconst git-cliff-config-regexp "\\`cliff\\.\\(to\\|ya\\)ml\\'"
  "Regexp for matching git-cliff config file.")

(defconst git-cliff-example-dir
  (expand-file-name "examples" (file-name-directory load-file-name))
  "Directory for storing default presets and templates.")

;; ISSUE https://github.com/magit/transient/issues/189
;; transient-values per project is under discussion
(defvar git-cliff-cache
  (transient--read-file-contents git-cliff-cache-file)
  "Cached values of `git-cliff-menu'.
The value of this variable persists between Emacs sessions and you usually
should not change it manually.")

(defvar git-cliff-presets nil
  "Presets available for git-cliff.")

(defvar git-cliff-templates nil
  "Templates available for git-cliff.")

;; functions
(defun git-cliff--get-repository ()
  "Return git project path if exists."
  (ignore-errors (locate-dominating-file (buffer-file-name) ".git")))

(defun git-cliff--get-infix (infix)
  "Return the value of INFIX in current active `git-cliff-menu'."
  (transient-arg-value infix (transient-args transient-current-command)))

;; (defun git-cliff--relative-path (filename dir)
;;   "Convert FILENAME to relative path if it's inside in DIR, otherwise return."
;;   (let* ((filename (expand-file-name filename))
;;          (dir (expand-file-name dir)))
;;     (if (string-prefix-p dir filename)
;;         (file-relative-name filename dir)
;;       (abbreviate-file-name filename))))

(defun git-cliff--get-changelog ()
  "Return changelog file name in repository."
  (or (and (null (git-cliff--get-infix "--context"))
           (or (git-cliff--get-infix "--output=")
               (git-cliff--get-infix "--prepend=")))
      "CHANGELOG.md"))

(defun git-cliff--default-directory (&optional default)
  "Return repository path as default directory.
If optional DEFAULT is non-nil, use `default-directory' as fallback."
  (or (git-cliff--get-infix "--repository=")
      (git-cliff--get-repository)
      (and default default-directory)))

(defmacro git-cliff-with-repo (&rest body)
  "Evaluate BODY if repository exists."
  `(if-let ((default-directory (git-cliff--default-directory)))
       (progn ,@body)
     (prog1 nil
       (message "git-cliff: couldn't find git repository."))))

(defun git-cliff--locate (dir &optional full regexp)
  "Return a list of git cliff config or templates in DIR.
If FULL is non-nil, return absolute path, otherwise relative path according to
DIR.  If REGEXP is non-nil, match configurations by REGEXP instead of
`git-cliff-config-regexp'."
  (ignore-errors
    (mapcar #'abbreviate-file-name
            (delq nil (directory-files
                       dir full (or regexp git-cliff-config-regexp))))))

(defun git-cliff--propertize (dir regexp face)
  "Return a list of file paths match REGEXP in DIR propertized in FACE."
  (mapcar (lambda (x)
            (concat (propertize (file-name-directory x)
                                'face 'font-lock-comment-face)
                    (propertize (file-name-nondirectory x) 'face face)))
          (git-cliff--locate dir t regexp)))

(defun git-cliff--extract (regexp)
  "Return a list of file paths match REGEXP."
  (nconc (git-cliff--propertize git-cliff-extra-dir regexp 'git-cliff-extra)
         (git-cliff--propertize git-cliff-example-dir regexp 'git-cliff-example)))

(defun git-cliff--presets ()
  "Return a list of git-cliff config presets."
  (or git-cliff-presets
      (setq git-cliff-presets (git-cliff--extract "\\.\\(to\\|ya\\)ml\\'"))))

(defun git-cliff--templates ()
  "Return a list of git-cliff body templates."
  (or git-cliff-templates
      (setq git-cliff-templates (git-cliff--extract "\\.tera\\'"))))

;; SEE https://emacs.stackexchange.com/a/8177/35676
(defun git-cliff--completion-table (type)
  "Return completion table for TYPE."
  (lambda (string pred action)
    (if (eq action 'metadata)
        `(metadata (display-sort-function . ,#'identity))
      (complete-with-action
       action
       (seq-filter (lambda (x)
                     (or git-cliff-enable-examples
                         (face-equal (get-text-property (- (length x) 1) 'face x)
                                     'git-cliff-extra)))
                   (if (eq type 'preset)
                       (git-cliff--presets)
                     (git-cliff--templates)))
       string pred))))

;; repository
(defun git-cliff--set-repository (prompt &rest _)
  "Read and set repository paths of git-cliff with PROMPT."
  (when-let ((dir (read-directory-name prompt (git-cliff--default-directory t) nil t)))
    (if (git-cliff--locate dir t "\\.git")
        dir
      (prog1 nil (message "Not git repo")))))

(transient-define-argument git-cliff--arg-repository ()
  :argument "--repository="
  :class 'transient-option
  :prompt "Set repository : "
  :reader #'git-cliff--set-repository)

;; config
(defun git-cliff--configs ()
  "Return a list of git-cliff configs available for current working directory."
  (nconc (git-cliff--locate (git-cliff--get-repository))
         (git-cliff--locate
          (convert-standard-filename
           (concat (getenv "HOME")
                   (cl-case system-type
                     (darwin "/Library/Application Support/git-cliff/")
                     ((cygwin windows-nt ms-dos) "/AppData/Roaming/git-cliff/")
                     (_ "/.config/git-cliff/"))))
          t git-cliff-config-regexp)))

(defun git-cliff--set-config (prompt &rest _)
  "Read and set config file for current working directory with PROMPT."
  (completing-read prompt (git-cliff--configs)))

(transient-define-argument git-cliff--arg-config ()
  :argument "--config="
  :class 'transient-option
  :prompt "Set config: "
  :reader #'git-cliff--set-config)

;; tag
(defun git-cliff--tag-latest ()
  "Return name of latest tag info in local repository if exists."
  (if-let ((default-directory (git-cliff--default-directory))
           (rev (shell-command-to-string "git rev-list --tags --max-count=1")))
      (if (string-empty-p rev)
          "No tag"
        (unless (string-prefix-p "fatal: not a git repository" rev)
          (string-trim (shell-command-to-string
                        (format "git describe --tags %s" rev)))))
    "Not git repo"))

(defun git-cliff--tag-bump ()
  "Return a list of bumped tags if latest tag match major.minor.patch style."
  (let ((latest (git-cliff--tag-latest))
        (regexp "^\\([[:alpha:]]+\\)?\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)"))
    (save-match-data
      (when (string-match regexp latest)
        (let ((prefix (match-string 1 latest))
              (base (cl-loop for i from 2 to 4
                             collect (string-to-number (match-string i latest)))))
          (mapcar (lambda (x)
                    (concat prefix (string-join (mapcar #'number-to-string x) ".")))
                  (list (list (nth 0 base)(nth 1 base) (1+ (nth 2 base)))
                        (list (nth 0 base) (1+ (nth 1 base)) 0)
                        (list (1+ (nth 0 base)) 0 0))))))))

(defun git-cliff--set-tag (prompt &rest _)
  "Read and set unreleased tag with PROMPT."
  (completing-read prompt (git-cliff--tag-bump)))

(transient-define-argument git-cliff--arg-tag ()
  :argument "--tag="
  :class 'transient-option
  :always-read nil
  :allow-empty t
  :prompt "Set tag: "
  :reader #'git-cliff--set-tag)

;; body
(defun git-cliff--set-body (prompt &rest _)
  "Read and set body template with PROMPT."
  (completing-read prompt (git-cliff--completion-table 'template) nil t))

(transient-define-argument git-cliff--arg-body ()
  :argument "--body="
  :class 'transient-option
  :prompt "Set body: "
  :reader #'git-cliff--set-body)

;; range
(transient-define-argument git-cliff--arg-tag-switch ()
  :class 'transient-switches
  :argument-format "--%s"
  :argument-regexp "\\(--\\(latest\\|current\\|unreleased\\)\\)"
  :choices '("latest" "current" "unreleased"))

(defun git-cliff--set-range (prompt &rest _)
  "Read and set commits range for git-cliff with PROMPT."
  (git-cliff-with-repo
   (let* ((crm-separator "\\.\\.")
          (rev (completing-read-multiple
                prompt
                (nconc (split-string
                        (shell-command-to-string
                         "git for-each-ref --format=\"%(refname:short)\"")
                        "\n" t)
                       (seq-filter (lambda (name)
                                     (file-exists-p
                                      (expand-file-name (concat ".git/" name))))
                                   '("HEAD" "ORIG_HEAD" "FETCH_HEAD"
                                     "MERGE_HEAD" "CHERRY_PICK_HEAD"))))))
     (and rev (concat (car rev) ".." (cadr rev))))))

(transient-define-argument git-cliff--arg-range ()
  :argument "--="
  :prompt "Limit to commits: "
  :class 'transient-option
  :always-read nil
  :reader #'git-cliff--set-range)

;; changelog
(defun git-cliff--set-changelog (prompt &rest _)
  "Read and set changelog file for current working directory with PROMPT."
  (completing-read prompt '("CHANGELOG.md" "CHANGELOG.json")))

(transient-define-suffix git-cliff--run (args)
  (interactive (list (transient-args 'git-cliff-menu)))
  (git-cliff-with-repo
   (let* ((cmd (executable-find "git-cliff"))
          (is-init (git-cliff--get-infix "--init"))
          (is-json (git-cliff--get-infix "--context"))
          (shell-command-dont-erase-buffer 'erase)
          (shell-command-buffer-name (concat "*git-cliff-preview."
                                             (if is-json "json" "md"))))
     (unless cmd (user-error "Cannot find git-cliff in PATH"))
     (when-let* ((template (git-cliff--get-infix "--body=")))
       (cl-nsubstitute
        (concat "--body="
                (shell-quote-argument
                 ;; NOTE replace new line
                 (replace-regexp-in-string
                  "\\\\n" "\n"
                  ;; NOTE replace line continuation
                  (replace-regexp-in-string
                   "\\\\\n\s*" ""
                   (with-temp-buffer
                     (insert-file-contents-literally template)
                     (buffer-string))
                   nil t)
                  nil t)))
        (concat "--body=" template) args :test #'string-equal))
     ;; ISSUE https://github.com/orhun/git-cliff/issues/266
     ;; install newer version than v.1.3.0 or build from source
     (setq args (replace-regexp-in-string "--[[:alnum:]-]*\\(=\\).+?"
                                          " " (string-join args " ")
                                          nil nil 1))
     (when (zerop (shell-command (format "%s %s" cmd args)))
       (if-let ((file (or (and is-init "cliff.toml")
                          (or (git-cliff--get-infix "--output=")
                              (git-cliff--get-infix "--prepend=")))))
           (find-file-other-window file)
         (switch-to-buffer-other-window shell-command-buffer-name))
       (and (not is-json) (not is-init)
            (fboundp 'markdown-view-mode)
            (markdown-view-mode))))))

(transient-define-suffix git-cliff--release ()
  (interactive)
  (git-cliff-with-repo
   (if-let* ((file (git-cliff--get-changelog))
             ((file-exists-p file))
             ((member (vc-git-state file) '(edited unregistered))))
       (when-let ((tag (or (git-cliff--get-infix "--tag=")
                           (git-cliff--set-tag "tag to release: "))))
         (when (zerop (shell-command
                       (format "git add %s;git commit -m \"%s\";git tag %s"
                               file
                               (read-from-minibuffer
                                "commit message: "
                                (format (or git-cliff-release-message "Release: %s")
                                        tag))
                               tag)))
           (find-file-other-window file)
           (and (fboundp 'markdown-view-mode) (markdown-view-mode))))
     (message "%s not prepared yet." file))))

(transient-define-suffix git-cliff--choose-preset ()
  (interactive)
  (git-cliff-with-repo
   (let* ((local-config (car (git-cliff--locate default-directory)))
          backup)
     (when (or (not local-config)
               (setq backup (yes-or-no-p "File exist, continue?")))
       (when-let* ((preset
                    (completing-read
                     "Select a preset: "
                     (git-cliff--completion-table 'preset)
                     nil t))
                   (newname (concat "cliff." (file-name-extension preset))))
         ;; kill buffer and rename file
         (when backup
           (when-let ((buf (get-file-buffer local-config)))
             (with-current-buffer buf
               (let ((kill-buffer-query-functions nil))
                 (save-buffer)
                 (kill-buffer))))
           (rename-file local-config
                        (concat local-config (format-time-string
                                              "-%Y%m%d%H%M%S"))))
         (copy-file preset newname)
         (find-file newname))))))

(transient-define-suffix git-cliff--edit-config ()
  (interactive)
  (git-cliff-with-repo
   (if-let* ((path (git-cliff--get-infix "--config="))
             ((file-exists-p path)))
       (find-file path)
     (message "git-cliff: %s not exist!" path))))

(transient-define-suffix git-cliff--open-changelog ()
  (interactive)
  (git-cliff-with-repo
   (if-let* ((name (git-cliff--get-changelog))
             ((file-exists-p name)))
       (find-file-read-only name)
     (message "git-cliff: %s not exist!" name))))

(transient-define-suffix git-cliff--set (&optional unset)
  "Set the value of `git-cliff-run' in current repository during session."
  (interactive)
  (when-let ((obj (or transient--prefix transient-current-prefix))
             (repo (git-cliff--get-repository)))
    (setf (alist-get (oref obj command)
                     (alist-get repo git-cliff-cache nil nil #'string-equal) nil unset)
          (unless unset (transient-get-value)))))

(transient-define-suffix git-cliff--save ()
  "Save the value of `git-cliff-menu' in current repository across Emacs Session."
  (interactive)
  (git-cliff--set)
  (transient--pp-to-file git-cliff-cache git-cliff-cache-file))

(transient-define-suffix git-cliff--reset ()
  "Reset the value of `git-cliff-menu' in current repository across Emacs Session."
  (interactive)
  (git-cliff--set 'unset)
  (transient-setup 'git-cliff-menu)
  (transient--pp-to-file git-cliff-cache git-cliff-cache-file))

;; HACK use advice to bind values from cache
(defun git-cliff--preload (fn)
  "Load saved value before call FN."
  (let ((transient-values
         (cdr (assoc (git-cliff--get-repository) git-cliff-cache))))
    (funcall fn)))
(advice-add 'git-cliff-menu :around #'git-cliff--preload)

(dolist (cmd '("run" "release" "choose-preset" "edit-config"
               "open-changelog" "set" "save" "reset"))
  (put (intern (concat "git-cliff--" cmd)) 'completion-predicate #'ignore))

(defun git-cliff-menu--header ()
  "Return a string to list dir and tag info as header."
  (let ((dir (ignore-errors (abbreviate-file-name
                             (file-name-directory (buffer-file-name)))))
        (tag (git-cliff--tag-latest)))
    (format "%s\n %s %s\n %s %s\n"
            (propertize "Status" 'face 'transient-heading)
            (propertize "current dir :" 'face 'font-lock-variable-name-face)
            (propertize (or dir "No dir") 'face 'transient-pink)
            (propertize "latest  tag :" 'face 'font-lock-variable-name-face)
            (propertize tag 'face 'transient-pink))))

;;;###autoload
(transient-define-prefix git-cliff-menu ()
  "Invoke command for `git-cliff'."
  :incompatible '(("--output=" "--prepend="))
  [:description git-cliff-menu--header
   :class transient-subgroups
   ["Flags"
    :pad-keys t
    ("-i" "Init default config" ("-i" "--init"))
    ("-T" "Sort the tags topologically" "--topo-order")
    ("-j" "Print changelog context as JSON" "--context")
    ("-l" "Processes commits from tag" git-cliff--arg-tag-switch)]
   ["Options"
    :pad-keys t
    ("-r" "Set git repository" git-cliff--arg-repository)
    ("-c" "Set config file" git-cliff--arg-config)
    ("-t" "Set tag of unreleased version" git-cliff--arg-tag)
    ("-o" "Generate new changelog" "--output="
     :prompt "Set output file: "
     :reader git-cliff--set-changelog)
    ("-p" "Prepend existing changelog" "--prepend="
     :prompt "Set prepend file: "
     :reader git-cliff--set-changelog)
    ("-S" "Set commits order inside sections" "--sort="
     :always-read t
     :choices ("oldest" "newest"))
    ("-b" "Set template for changelog body" git-cliff--arg-body)
    ("-m" "Set custom commit messages to include in changelog" "--with-commit=")
    ("-I" "Set path to include related commits" "--include-path=")
    ("-E" "Set path to exclude related commits" "--exclude-path=")
    ("-s" "Strip the given parts from changelog" "--strip="
     :choices ("header" "footer" "all"))]
   ["Range"
    ("--" "Limit to commits" git-cliff--arg-range)]
   [["Command"
     ("r" "Run command" git-cliff--run)
     ("R" "Release version" git-cliff--release)]
    ["Other"
     ("s" "Set values"     git-cliff--set :transient t)
     ("S" "Save values"    git-cliff--save :transient t)
     ("x" "Reset values"   git-cliff--reset :transient t)
     ("c" "Choose preset"  git-cliff--choose-preset :transient t)
     ("o" "Open changelog" git-cliff--open-changelog)
     ("e" "Edit config"    git-cliff--edit-config)]]])

(provide 'git-cliff)
;;; git-cliff.el ends here
