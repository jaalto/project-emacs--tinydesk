;;; epackage.el --- Emacs Lisp package manager (download, build, install)

;; This file is not part of Emacs

;; Copyright (C)    2009-2011 Jari Aalto
;; Keywords:        tools
;; Author:          Jari Aalto
;; Maintainer:      Jari Aalto

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.
;;
;; Visit <http://www.gnu.org/copyleft/gpl.html> for more information

;;; Install:

;;  Put this file on your Emacs-Lisp `load-path', add following into your
;;  ~/.emacs startup file.
;;
;;      (require 'tinyepkg)		; Requires Emacs 22+
;;
;;  You can also use the preferred way: autoload
;;
;;       (autoload 'epackage "tinyepkg" "" t)
;;       (global-set-key "\C-cP" 'epackage)

;;; Commentary:

;;  Preface 2009
;;
;;      Emacs has been around for decades now. Many new version have
;;      come and gone (18.59 ... 23.x), There are many packages (*.el)
;;      that enhance and add new feature e.g. for new programming
;;      langauges. The typical procedure to add new feature to Emacs
;;      is:
;;
;;      o   Find a package at places like
;;          http://dir.gmane.org/gmane.emacs.sources or
;;          http://www.emacswiki.org
;;      o   Download and save the package along `load-path'
;;      o   Read the installation information. Usually embedded in comments
;;          inside a file.
;;      o   Add Emacs Lisp code to the startup file ~/.emacs
;;          to arrange loading the package with personal customizations.
;;
;;      That's quite a bit of work for each package; reaching
;;      thousands out there. Many Linux distributions offer package
;;      managers to download and install programs. Debian has
;;      *apt-get*, Redhat uses *rpm*, Suse uses *yum* etc. So why not
;;      make one for Emacs as well.
;;
;;  Epackage - the DVCS packaging system
;;
;;      This packaging system is called epackage, short name for
;;      "Emacs Lisp packages".
;;
;;      In this system uses the packages are available in a form of
;;      distributed[1] git[2] version control repositories. The
;;      traditional packaging methods (like ELPA[2]) have relied on
;;      archives like *.tar.gz to hold all the code. In contrast the
;;      DVCS offers important features over *.tag.gz approach:
;;
;;	o   Efficient downloads; fast, only deltas are transferred
;;	o Local modifications; users can creaet their own customizations
;;	    easily
;;	o   Helping package authors made easy; have you fixed an
;;	    error? Generate diff straight from the repository
;;	o   Select any version; pick latest or
;;	    downgrade to a older version with ease.
;;
;;      To use a package in this system, it must be first converted
;;      into a Git repository and made available online. This job can
;;      be made by anyone who sets up the reposository. It doesn't
;;      need to be done by the original developer who may not be
;;      familiar with the git(1) program. For more inforamtion about
;;      the packaging see "Epackage specification" below.
;;
;;      [1] DVCS = Distributed Version Control System
;;          http://en.wikipedia.org/wiki/Distributed_revision_control
;;
;;      [2] http://git-scm.org
;;
;;	[3] http://www.emacswiki.org/emacs/ELPA
;;
;;  User commands
;;
;;      Command `M-x' `epackage' is alias for function
;;      `epackage-manager'. It builds outline based buffer where
;;      packages can be browsed, built and installed. Standard outline
;;      type of keys can be used to navigate in the buffer. The
;;      *Local* is "yes" when package has been downloaded to local
;;      disk. The *Status* indicates if the package activation code is
;;      found from `ROOT/install' directory (see below). User's
;;      standard Emacs startup files, like ~/.emacs are never
;;      modified.
;;
;;          * Section: tools
;;          ** Package: one; Local: no; Status: not-installed; Ver: 1.5 -!-
;;          <content of the 'info' file>
;;          * Section: tools
;;          ** Package: two; Local: yes; Status: installed; Ver: 1.0
;;          <content of the 'info' file>
;;          ...
;;
;;      In this view, supposing the cursor is at [-!-] or inside the
;;      package description, the commands are:
;;
;;      o   d, run `dired' on package installation directory.
;;      o   e, edit package "info".
;;      o   g, get. Update package list. What new is available
;;      o   i, install package.
;;      o   l, list only installed packages.
;;      o   m, mark package (for command install or remove).
;;      o   n, list only new packages (not-installed).
;;      p   p, purge package; delete package physically from local disk.
;;      o   r, remove package. Synonym for uninstall action.
;;	o   u, unmark (install, purge, remove)
;;	o   U, upgrade package to newer version
;;      o   q, quit. Run `bury-buffer'.
;;	o   x, execute (install, purge, remove).
;;
;;      Building the initial list of available packages take some time
;;      and this is done via open internet connection. Install command
;;      also requires an open internet connection.
;;
;;  Epackage system layout
;;
;;      The packages are installed under root `epackage--root-directory',
;;      which defaults to ~/.emacs.d or ~/elisp respectively. The
;;      root directory is organized as follows:
;;
;;          epackage
;;	    | epackage.lst		The yellow pages to available packages
;;          | epackage-loader.el	activated + installed as one big file
;;          |
;;          +--install/
;;          |  <package>-activate.el files
;;          |  <package>-install.el files
;;          |
;;          +--vc/     Packages. The Version control repositories.
;;             |
;;             +--<package name>/
;;             +--<package name2>/
;;             +-- ...
;;
;;  Epackage specification
;;
;;      The Git repository branches used are:
;;
;;      o   `master', required. Branched off from `upstream'. Adds directory
;;	    `epackage/'. This contains verything to use the package.
;;      o   `patches', optional. Patches to `upstream' code.
;;      o   `upstream', required. The original unmodified upstream code.
;;	    Releases are tagged with label
;;	    "upstream/YYYY-MM-DD[--VERSION]". The YYYY-MM-DD is the
;;	    date of upstream release or best guess and it is
;;	    accompanied with optional "--VERSION" of the package. Not
;;	    all packages include version information. The ISO 8601
;;	    date is needed so that the 1) release date is immediately
;;	    available e.g. for post processing and 2) the tags sort
;;	    nicely by date. An example: "upstream/2009-12-31--0.3"
;;
;;      The epackage method borrows concepts from the Debian package
;;      build system where a separate control directory contains
;;      the needed information. The directory name *epackage* is not
;;      configurable. Files in pacakge/ directory include:
;;
;;          <package name>
;;          |
;;          +- .git/			Version control branches (see above)
;;          |
;;          +-- epackage/
;;		info			required: The package control file
;;		PACKAGE-autoloads.el	optional: all autoload statements (raw)
;;		PACKAGE-install.el	required: Code to make package available
;;		PACKAGE-loaddefs.el	required: ###autoload statements
;;		PACKAGE-uninstall.el	optional: to remove package
;;		PACKAGE-xactivate.el	optional: Code to activate package
;;
;;	The nanes of the files have been chosen to sort
;;	alphabetically. From Emacs point of view, loading individual
;;	files is slower than loading a gigantic setup. It would be
;;	possible (due to sort order) to safely collect all together
;;	with:
;;
;;		cat PACKAGE-* | grep -v uninstall > PACKAGE-all-in-one-loader.el
;;
;;     The *-install.el
;;
;;	This file does not modify user's environment. It publishes
;;	user variables and interactive `M-x' functions in autoload
;;	state for the package. This file is usually necessary only if
;;	PACKAGE does not contain proper ###autoload statements. See
;;	*-loaddefs alternative in that case.
;;
;;     The *-loaddefs.el
;;
;;	This file does not modify user's environment. It is
;;	automatically generated from the PACKAGE by collecting all
;;	###autoload definitions. If PACKAGE does not contains any
;;	###autoload definitions, then manually crafter *-install.el
;;	file works as a substitute for file.
;;
;;     The *-uninstall.el
;;
;;	This file does the opposite of *-install.el and *-activate.el
;;	Runs commands to remove the package as if it has never been
;;	loaded. Due to the nature of Emacs, it may not be possible to
;;	completely uninstall the package. The uninstallation usually
;;	covers undoing the changes to variables like *-hook,
;;	*-functions and `auto-mode-alist'. The actual symbols (defined
;;	functions and variables) are not removed. Usually it is more
;;	practical to just restart Emacs than completely trying undo
;;	all the effects of a package.
;;
;;     The *-xactivate.el
;;
;;	This file makes the PACKAGE immediately active in user's
;;	environment. It modifies current environment by adding
;;	functions to hooks, adding minor or major modes or arranging
;;	keybindings so that when pressed, the feature is loaded. It is
;;	adviseable that any custom settings, like variables and prefix
;;	keys, are defined *before* this file is loaded.
;;
;;  The info file
;;
;;      A RFC 2822 formatted file (email), which contains information
;;      about the package. The minumum required fields are presented
;;      below. The header field names are case insensitive. Continued
;;      lines must be intended; suggested indentation is one space.
;;      Required fields aer marked with "*" character.
;;
;;	    *Package:
;;          *Section: <data | extensions | files | languages | mail | tools | M-x finder-list-keywords>
;;          License: <GPL-[23]+ | BSD | Apache-2.0>
;;          *Depends: emacs (>= 20)
;;          Status: [ core-emacs | unmaintained | broken |
;;            note YYYY-MM-DD the code hasn't been touched since 2006 ; ]
;;          *Email:
;;          Bugs:
;;          Vcs-Type:
;;          Vcs-Url:
;;          Vcs-Browser:
;;          Homepage:
;;          Wiki: http://www.emacswiki.org/emacs/
;;          *Description: <short one line>
;;           [<Longer description>]
;;	     .
;;           [<Longer description, next paragraph>]
;;	     .
;;           [<Longer description, next paragraph>]
;;
;;  Details of the info file fields in alphabetical order
;;
;;     Conflicts
;;
;;	This field lists packages that must be removed before install
;;	should be done. This field follow guidelines of
;;	<http://www.debian.org/doc/debian-policy/ch-relationships.html>.
;;
;;     Depends (required)
;;
;;	List of dependencies: Emacs flavor and packages required. The
;;	version information is enclosed in parentheses with comparison
;;	operators ">=" and "<=". A between range is not defined. This
;;	field follow guidelines of
;;	<http://www.debian.org/doc/debian-policy/ch-relationships.html>.
;;
;;	In case program works inly in certain Emacs versions, this
;;	information should be announces in field "Status::note" (which
;;	see). Packages that are not updated to work for latest Emacs
;;	versions are candidate for removal from package archive
;;	anyway. An example:
;;
;;		Depends: emacs (>= 22.2.2) | xemacs (>= 20)
;;
;;     Description (required)
;;
;;	The first line of this field is a consise description that fits on
;;      maximum line length of 80 characters in order to display in
;;      combined format "PACKAGE -- SHORT DESCRIPTION". The longer
;;	description is explained in paragraphs that are separated from
;;	each orher with a single (.) at its own line. The paragraphs
;;	are recommended to be intended by one space.
;;
;;     Email
;;
;;	Upstream developers email address(es). Multiple developers
;;	are listed like in email: separated by commas. Teh role can
;;	be expressed in parenthesis. An example:
;;
;;		Email: John doe (Author) <jdoe@example.com>,
;;		 Joe Average (Co-developer) <jave@example.com>
;;
;;     Homepage
;;
;;      URL to the project homepage. For this field it is adviseable
;;      to use project addresses that don't move; those of
;;      Freshmeat.net, Sourceforge, Launchpad, Github etc. The
;;      Freshmeat is especially good because is provides an easy
;;      on-to-tover-all hub to all other Open Source projects. Through
;;      Freshmeat users can quickly browse related software and
;;      subscribe to project announcements. Freshmeat is also easy for
;;      the upstream developer to set up because it requires no heavy
;;      project management (it's kind of "yellow pages"). In any case,
;;      the Homepage link should not directly point to a volatile
;;      personal homepage if an alternative exists.
;;
;;     License
;;
;;      If misssing, the value is automatically assumed "GPL-2+". The
;;      valid License abbreviations should follow list defined at
;;      <http://wiki.debian.org/CopyrightFormat>.
;;
;;     Package (required)
;;
;;	This field is the PACKAGE part from file name package.el or the
;;      canonical known name in case of bigger packages like "gnus".
;;      An example "html-helper-mode.el" => package name is
;;      "html-helper-mode". It is adviseable to always add *-mode even
;;	if file does not explicitly say so. An example "python.el" =>
;;	package name is "python-mode". Duplicate similar names cannot
;;      exists. Please contact package author in case of name clashes.
;;
;;     Recommends
;;
;;	This field lists additional packages that the current package
;;	can utilize. E.g a package A, can take advantage of package B,
;;	if it is aailable, but it is not a requirement to install B
;;	for package A to work. This field is *not* used to annouce
;;	related packages. That information can be mentioned in
;;	the end of "Description" in paragraph "SEE ALSO".
;;
;;     Section (required)
;;
;;	This field contains category for package. The valid keywords are
;;      those listed in `M-x' `finder-list-keywords'.
;;
;;     Status
;;
;;	This field lists information about the package. Each keyword
;;	has a unique mening. the allowed list:
;;
;;	    keyword := 'core-emacs'
;;		       | 'core-xemacs'
;;		       | 'unmaintained'
;;		       | 'broken'
;;		       | 'note' YYYY-MM-DD [COMMENT] ';'
;;
;;	And example:
;;
;;	    Status: unmaintained
;;		broken
;;		note YYYY-MM-DD Doesn't work in Emacs 23.
;;		See thread http://example.com ;
;;
;;	The `core-*' values mark the package being included (or will
;;	be) in the latest [X]Emacs. Value `unmaintained' means that
;;	the original developer has vanished or abandoned the project
;;	and is no longer available for developing the package. Value
;;	`broken' means that package is broken and does not work in
;;	some Emacs version (usually latest). The `note' keyword can be
;;	used for any kind of information. It is adviced that notes are
;;	time stamped using ISO 8601 YYYY-MM-DD format. A note ends in
;;	character `;' and can be of any length.
;;
;;     Vcs-Browser
;;
;;	The URL address to the version control browser of the repository.
;;
;;     Vcs-Type
;;
;;      Version Constrol System information. The value is the
;;      lowercase name of the version control program. A special value
;;      "http" can be used to signify direct HTTP download. An example
;;      of an Emacs package hosted directly at a web page:
;;
;;	    Vcs-Type: http
;;          Vcs-Url: http://www.emacswiki.org/emacs/download/vline.el
;;
;;     Vcs-Url
;;
;;	The technical repository URL. For CVS, this is the value of
;;	CVSROOT which includes also the protocol name:
;;
;;	    Vcs-Url: :pserver:anonymous@example.com/reository/foo
;;
;;     Vcs-User
;;
;;	The login name. In case the repository cannot be accessed
;;	simply by visiting the `Vcs-Url' (or in the case of CVS:
;;	pressing RETURN at login prompt), this is the login name.
;;
;;     Wiki
;;
;;	This field points to package at <http://www.emacswiki.org>. If
;;	it does not exists, consider creating one for the PACKAGE.
;;
;;     X-*
;;
;;      Any other custom fields can be inserted using `X-*' field
;;      notation:
;;
;;          X-Comment: <comment here>
;;          X-Maintainer-Homepage: <URL>
;;
;; TODO
;:
;;	- Git tags, where is this information kept?
;;	- How to update package, or all packages?
;;	  => Running git preocess? When update is avilable how to flag this?
;;	  => What about conflits?
;;	- What about 'local', manual branch and updates?
;;	- Retrieve new yellow pages (available packages)
;;	- Rescan current information? (what is installed, what is not)
;;        => Keep cache? Or regenerate, or scan at startup every time?
;;	- What if user manually deletes directories? Refresh?
;;	- Package health check, Lint?
;;	- Edit yellow pages catalog?
;;	  => Submit/update yellow pages catalog changes?
;;	  => version controlled, patches? Interface to automatic email?
;;	- Yellow pages URL health check? What to do with broken links?

;;; Change Log:

;;; Code:

(defconst epackage-version-time "2010.1129.1643"
  "*Version of last edit.")

(defcustom epackage--load-hook nil
  "*Hook run when file has been loaded."
  :type  'hook
  :group 'Epackage)

(defcustom epackage--sources-url
  "http://cante.net/~jaalto/epackage.lst"
  "URL to the location of available package list. The yellow pages.
This is a text file that contains information about package names
and their DVCS URLs. Empty lines and comment on their own lines
started with character '#' are ignored:

  # Comment
  PACKAGE-NAME REPOSITORY-URL DESCRIPTION
  PACKAGE-NAME REPOSITORY-URL DESCRIPTION
  ...

An example:

  foo git://example.com/repository/foo.git")

(defcustom epackage--root-directory
  (let (ret)
    (dolist (elt (list
		  (if (featurep 'xemacs)
		      "~/.xemacs.d"
		    "~/.emacs.d")
		  "~/elisp"))
      (if (and elt
	       (null ret)
	       (file-directory-p elt))
	  (setq ret elt)))
    (cond
     (ret
      ret)
     (t
      ;; No known package installation root directory
      (message
       (concat "Epackage: [ERROR] Can't determine location of lisp packages."
	       "Please define `epackage--root-directory'.")))))
  "*Location of lisp files. Typically ~/.emacs.d or ~/elisp.
Directory should not contain a trailing slash."
  :type  'directory
  :group 'Epackage)

(defvar epackage--directory-name "epackage"
  "Name of package directory under `epackage--root-directory'.
Use function `epackage-directory' for full path name.")

(defvar epackage--directory-name-vcs "vc"
  "VCS directory under `epackage--root-directory'.
Use function `epackage-file-name-vcs-compose' for full path name.")

(defvar epackage--directory-name-install "install"
  "Install directory under `epackage--root-directory'.")

(defconst epackage--directory-exclude-regexp
  (concat
   "/\\.\\.?$"
   "\\|/RCS$"
   "\\|/rcs$"
   "\\|/CVS$"
   "\\|/cvs$"
   "\\|/\\.\\(svn\\|git\\|bzr\\|hg\\|mtn\\|darcs\\)$"
   "\\|/"
   epackage--directory-name
   "$")
  "Regexp to exclude dirctory names.")

(defconst epackage--layout-mapping
  '((activate . "xactivate")
    (autoload . "autoloads")
    (enable . "install")
    (info . "info")
    (loaddefs . "loaddefs")
    (uninstall . "uninstall"))
  "File name mappings under epackage/ directory.
Format is:
  '((TYPE . FILENAME) ...)

Used in `epackage-file-name-vcs-directory-control-file'.")

(defvar epackage--initialize-flag nil
  "Set to t, when epackage has been started. do not touch.")

(defvar epackage--program-git nil
  "Location of program git(1).")

(defvar epackage--sources-file-name "epackage.lst"
  "Name of yellow pages file that lists available packages.
See variable `epackage--sources-url'.")

(defvar epackage--loader-file "epackage-loader.el"
  "file that contains all package enable and activate code.
See `epackage-loader-file-generate'.")

(defvar epackage--package-control-directory "epackage"
  "Name of directory inside VCS controlled package.")

(defvar epackage--process-output "*Epackage process*"
  "Output of `epackage--program-git'.")

(defsubst epackage-file-name-compose (name)
  "Return path to NAME in epackage directory."
  (format "%s/%s"
	  (epackage-directory)
	  name))

(defsubst epackage-file-name-loader-file (package)
  (format "%s/%s%s"
	  (epackage-directory)
	  epackage--loader-file))

(defsubst epackage-file-name-vcs-compose (package)
  (format "%s/%s%s"
	  (epackage-directory)
	  epackage--directory-name-vcs
	  (if (string= "" package)
	      ""
	    (concat "/" package))))

(defsubst epackage-file-name-vcs-directory ()
  "Return VCS directory"
  (epackage-file-name-vcs-compose ""))

(defsubst epackage-file-name-install-directory ()
  "Return VCS directory"
  (format "%s/%s"
	  (epackage-directory)
	  epackage--directory-name-install))

(defsubst epackage-file-name-vcs-package-control-directory (package)
  "Return control directory of PACKAGE"
  (let ((root (epackage-file-name-vcs-compose package)))
    (format "%s/%s" root epackage--package-control-directory)))

(defun epackage-file-name-vcs-directory-control-file (package type)
  "Return PACKAGE's control file of TYPE.

TYPE can be on of the following:

  'activate
  'autoload
  'enable
  'info
  'loaddefs
  'uninstall

Refer top Epackage specification for more information in
documentation of tinyepkg.el."
  (let ((dir (epackage-file-name-vcs-package-control-directory package))
	(file (cdr-safe (assq type epackage--layout-mapping))))
    (if (not file)
	(error "Epackage: Unknown TYPE argument '%s'" type)
      (cond
       ((eq type 'info)
	 (format "%s/%s" dir file))
       (t
	(format "%s/%s-%s.el" dir package file))))))

(defsubst epackage-file-name-activated-compose (package)
  "Return path to PACKAGE under activated directory."
  (format "%s/%s%s"
	  (epackage-directory)
	  epackage--directory-name-install
	  (if (string= "" package)
	      ""
	    (format "/%s-xactivate.el" package))))

(defsubst epackage-file-name-enabled-compose (package)
  "Return path to PACKAGE under install directory."
  (format "%s/%s%s"
	  (epackage-directory)
	  epackage--directory-name-install
	  (if (string= "" package)
	      ""
	    (format "/%s-install.el" package))))

(defun epackage-package-enabled-p (package)
  "Return file if PACKAGE is enabled."
  (let ((file (epackage-file-name-enabled-compose package)))
    (if (file-exists-p file)
	file)))

(defun epackage-package-activated-p (package)
  "Return file if PACKAGE is activated."
  (let ((file (epackage-file-name-activated-compose package)))
    (if (file-exists-p file)
	file)))

(defun epackage-package-downloaded-p (package)
  "Check if package has been downloaded."
  (unless (stringp package)
    (error "Epackage: PACKAGE arg is not a string."))
  (let ((dir (epackage-file-name-vcs-compose package)))
    (file-directory-p dir)))

(defun epackage-package-activated-p (package)
  "Check if package has been activated, return activate file."
  (unless (stringp package)
    (error "Epackage: PACKAGE arg is not a string."))
  (let ((file (epackage-file-name-activated-compose package)))
    (if (file-exists-p file)
	file)))

(defun epackage-package-enabled-p (package)
  "Check if package has been enabled, return enabled file."
  (unless (stringp package)
    (error "Epackage: PACKAGE arg is not a string."))
  (let ((file (epackage-file-name-install-compose package)))
    (if (file-exists-p file)
	file)))

(defsubst epackage-file-name-sources-list ()
  "Return path to `epackage--sources-file-name'."
  (epackage-file-name-compose epackage--sources-file-name))

(defsubst epackage-sources-list-p ()
  "Check existence of `epackage--sources-file-name'."
  (file-exists-p (epackage-file-name-sources-list)))

(defsubst epackage-sources-list-verify ()
  "Signal error if `epackage--sources-file-name' does not exist."
  (unless (epackage-sources-list-p)
    (error "Epackage: Missing file %s. Run epackage-initialize"
	   (epackage-file-name-sources-list))))

(defun epackage-program-git-verify ()
  "Verify variable `epackage--program-git'."
  (when (or (not (stringp epackage--program-git))
	    (not (file-exists-p epackage--program-git)))
    (error
     (substitute-command-keys
      (format "Epackage: Invalied variable `epackage--program-git' (%s) "
	      epackage--program-git
	      "Run \\[epackage-initialize]")))))

(defun epackage-directory ()
  "Return root directory."
  (format "%s%s"
	  (expand-file-name
	   (file-name-as-directory epackage--root-directory))
	  (if (stringp epackage--directory-name)
	      epackage--directory-name
	    (error "Epackage: epackage--directory-name is not a string"))))

(put  'epackage-with-binary 'lisp-indent-function 0)
(put  'epackage-with-binary 'edebug-form-spec '(body))
(defmacro epackage-with-binary (&rest body)
  "Disable all interfering `write-file' effects and run BODY."
  `(let ((version-control 'never)
	 (backup-inhibited t)
	 (buffer-file-coding-system 'no-conversion)
	 write-file-functions
	 after-save-hook)
     ,@body))

(put  'epackage-with-sources-list 'lisp-indent-function 0)
(put  'epackage-with-sources-list 'edebug-form-spec '(body))
(defmacro epackage-with-sources-list (&rest body)
  "Run BODY in package list buffer."
  `(progn
     (epackage-sources-list-verify)
     (with-current-buffer
	 (find-file-noselect (epackage-file-name-sources-list))
       ,@body)))

(defun epackage-git-command-process (&rest args)
  "Run git COMMAND with output to `epackage--process-output'."
  (epackage-program-git-verify)
  (with-current-buffer (get-buffer-create epackage--process-output)
    (goto-char (point-max))
    (apply 'call-process
	   epackage--program-git
	   (not 'infile)
	   (current-buffer)
	   (not 'display)
	   args)))

(defsubst epackage-git-command-ok-p (status)
  "Return non-nil if command STATUS was ok."
  (zerop status))

(defun epackage-git-command-clone (url dir &optional verbose)
  "Clone git PACKAGE under `epackage--directory-name'.
If VERBOSE is non-nil, display progress message."
  (let ((default-directory (epackage-file-name-vcs-directory)))
    (if verbose
	(message "Epackage: Running git clone %s %s ..." url git))
    (prog1
	(epackage-git-command-ok-p
	 (epackage-git-command-process
	  "clone"
	  url
	  dir))
    (if verbose
	(message "Epackage: Running git clone %s %s ...done" url git)))))

(defun epackage-download-package (package &optional verbose)
  "Download PACKAGE to VCS directory."
  (let ((url (epackage-sources-list-info-url package)))
    (unless url
      (error "Epackage: No Git URL for package '%s'" package))
    (let ((dir (epackage-file-name-vcs-compose package)))
      (epackage-git-command-clone url dir))))

(defun epackage-enable-package (package)
  "Enable PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
	       package 'enable))
	(to (epackage-file-name-install-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: file does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-activate-package (package)
  "Activate PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
	       package 'activate))
	(to (epackage-file-name-activated-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: file does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-enable-package (package)
  "Activate PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
	       package 'enable))
	(to (epackage-file-name-enabled-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: file does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-disable-package (package)
  "Disable PACKAGE."
  (dolist (file (directory-files
		 (epackage-file-name-install-directory)
		 'full-path
		 (format "^%s-.*\\.el" package)
		 t))
    (if (file-exists-p file)
	(delete-file file))))

(defun epackage-action-package (package action)
  "Perform ACTION on PACKAGE.
ACTION can be:

  'enable
  'disable
  'activate
  'uninstall"
  ;; FIXME: Not implemented
  )

(defun epackage-directory-list (dir)
  "Return all directories under DIR."
  (let (list)
    (dolist (elt (directory-files dir 'full))
      (when (and (file-directory-p elt)
                 (not (string-match
		       epackage--directory-exclude-regexp
		       elt)))
        (setq list (cons elt list))))
    list))

(defun epackage-directory-recursive-list (dir list)
  "Return all directories under DIR recursively to LIST.
Exclude directories than contain file .nosearch
or whose name match `epackage--directory-name'."
  (let ((dirs (epackage-directory-list dir)))
    (dolist (elt dirs)
      (cond
       ((file-exists-p (concat elt "/.nosearch")))
       (t
	(setq list (cons elt list))
	(epackage-directory-recursive-list elt list))))
    list))

(defun epackage-loader-file-insert-header ()
  "Empty `current-buffer' and write comments."
  (insert
   (format
    "\
;; Empackge boot file -- automatically generated
;; Add following to your ~/.emacs to use this file:
;;   (load-file \"%s\")\n")
   (epackage-file-name-loader-file)))

(defun epackage-loader-insert-file-path-list-by-path (path)
  "Insert `load-path' definitions to `current-buffer' from PATH."
  (let (list)
    (dolist (dir (epackage-directory-recursive-list path list))
      (insert (format
	       "(add-to-list 'load-path \"%s\")\n"
	       dir)))))

(defun epackage-loader-file-insert-path-list ()
  "Insert `load-path' commands to `current-buffer'."
  (let (name
	package
	list)
    (dolist (file (directory-files
		   (epackage-file-name-install-directory)
		   'full-path
		   (format "^\\.el" package)
		   t))
      (setq name
	    (file-name-sans-extension
	     (file-name-nondirectory file)))
      ;; package-name-autoloads => package-name
      (setq package (replace-regexp-in-string  "-[^-]+$" "" name))
      (unless (member package list)
	(add-to-list 'list package)
	(epackage-loader-insert-file-path-list-by-path
	  (epackage-directory-recursive-list package))))))

(defun epackage-loader-file-collect ()
  "Collect loader code into `current-buffer'."
  ;; FIXME: Use only activate, not enable if both exists
  (dolist (file (directory-files
		 (epackage-file-name-install-directory)
		 'full-path
		 (format "^\\.el" package)
		 t))
    (goto-char (point-max))
    (insert-file-contents-literally file)))

(defsubst epackage-loader-file-insert-main ()
  "Inser loaded Emacs Lisp command to current point."
  (epackage-loader-file-insert-header)
  (epackage-loader-file-insert-path-list)
  (epackage-loader-file-insert-install-code))

(defun epackage-loader-file-generate ()
  "Generate main loader for all installed or activated packages."
  (let ((file (epackage-file-name-loader-file)))
    (with-current-buffer (find-file-noselect file)
      (delete-region (point-min) (point-max))
      (epackage-loader-file-insert-main))))

(defun epackage-sources-list-info-main (package)
  "Return '(pkg url description) for PACKAGE.
Format is described in variable `epackage--sources-url'."
  (epackage-with-sources-list
   (goto-char (point-min))
   (let ((re
	  (format
	   `,(concat "^\\(%s\\)\\>"
		     "[ \t]+\\([^ \t\r\n]+\\)"
		     "[ \t]*\\([^ \t\r\n]*\\)")
	   (regexp-quote package))))
     (when (re-search-forward re nil t)
       (list
	(match-string-no-properties 1)
	(match-string-no-properties 2)
	(match-string-no-properties 3))))))

(defun epackage-sources-list-info-url (package)
  "Return URL for PACKAGE."
  (let ((info (epackage-sources-list-info-main package)))
    (when info
      (nth 1 info))))

(defun epackage-require-emacs ()
  "Require Emacs features."
  (unless (fboundp 'url-retrieve-synchronously)
    (error (concat
	    "Epackage: this Emacs does not define "
	    "`url-retrieve-synchronously' which is included in url.el"))))

(defun epackage-require-git ()
  "Require Git program."
  (cond
   ((null epackage--program-git)
    (let ((bin (executable-find "git")))
      (unless bin
	(error "Epackage: program 'git' not found in PATH"))
      (setq epackage--program-git bin)))
   ((and (stringp epackage--program-git)
	 (not (file-exists-p epackage--program-git)))
    (error "Epackage: [ERROR] Invalid `epackage--program-git' (%s)"
	   epackage--program-git))
   ((file-executable-p epackage--program-git)) ;All ok
   (t
    (error "Epackage: [ERROR] Unknown value in `epackage--program-git' (%s)"
	   epackage--program-git))))

(defun epackage-require-directories ()
  "Buid directory structure."
  (dolist (dir (list
		(epackage-directory)
		(epackage-file-name-vcs-directory)
		(epackage-file-name-install-directory)))
    (unless (file-directory-p dir)
      (message "Epackage: Making directory %s ..." dir)
      (make-directory dir))))

(defun epackage-require-main ()
  "Check requirements to run Epackage."
  (epackage-require-emacs)
  (epackage-require-git)
  (epackage-require-directories))

(defun epackage-url-http-parse-respons-error (&optional url)
  "On HTTP GET error, show reponse and signal error for optional URL."
  (let ((status (url-http-parse-response)))
    (when (or (< status 200)
	      (>= status 300))
      (display-buffer (current-buffer))
      (error "HTTP access error %d%s"
	     status
	     (if url
		 (concat " " url)
	       "")))))

(defun epackage-url-retrieve-main (url file)
  "Download URL and save to a FILE."
  (let ((buffer (url-retrieve-synchronously url)))
    (unless buffer
      (error "Epackage: can't access %s" url))
    (with-current-buffer buffer
      (epackage-url-http-parse-respons-error url)
      (re-search-forward "^$" nil 'move)
      (forward-char)
      (epackage-with-binary
	(write-region (point) (point-max) file)
	(kill-buffer (current-buffer))))))

(defun epackage-url-retrieve-sources-list (&optional message)
  "Download package list file, the yellow pages."
  (if message
      (message message))
  (epackage-url-retrieve-main
   epackage--sources-url
   (epackage-file-name-sources-list)))

(defun epackage-cmd-download-sources-list ()
  "Download package list; the yellow pages of packages."
  (interactive)
  (epackage-url-retrieve-sources-list "Downloading package sources list"))

(defun epackage-initialize ()
  "Inialize package."
  (unless epackage--initialize-flag
    (epackage-require-main))
  (unless (epackage-sources-list-p)
    (epackage-cmd-download-sources-list))
  (setq epackage--initialize-flag t))

;;;###autoload (autoload 'epackage-mode          "epackage" "" t)
;;;###autoload (autoload 'turn-on-epackage-mode  "epackage" "" t)
;;;###autoload (autoload 'tun-off-epackage-mode  "epackage" "" t)
;;;###autoload (autoload 'epackage-commentary    "epackage" "" t)

;; FIXME: Unfinished, this is at a sketch / planning phase.

(eval-and-compile
  (ti::macrof-minor-mode-wizard
   "epackage-" " Epkg" "z" "Epkg" 'Epackage "epackage--"
   "Emacs package manager

Mode description:

\\{epackage--mode-prefix-map}"

   "Epackage"
   nil
   "Number conversion mode"
   (list                                ;arg 10
    epackage--mode-easymenu-name
    "----"
    ["Package version"    epackage-version        t]
    ["Package commentary" epackage-commentary     t]
    ["Mode help"   epackage-mode-help   t]
    ["Mode off"    epackage-mode        t])
   (progn
     (define-key map "v"  'epackage-version)
     (define-key map "?"  'epackage-mode-help)
     (define-key map "Hm" 'epackage-mode-help)
     (define-key map "Hc" 'epackage-commentary)
     (define-key map "Hv" 'epackage-version))))

(defsubst epackage-directory-name ()
  "Return package directory.
Refences:
  `epackage--package-root-directory'
  `epackage--directory-name'."
  (if (and (stringp epackage--root-directory)
	   (stringp epackage--directory-name))
      (format "%s/%s"
	      epackage--root-directory
	      epackage--directory-name)
    (error (concat "Epackge: [FATAL] Invalid epackage--root-directory"
		    " or epackage--directory-name"))))

(add-hook  'epackage--mode-hook 'epackage-mode-define-keys)
(provide   'epackage)
(run-hooks 'epackage--load-hook)

;;; epackage.el ends here
