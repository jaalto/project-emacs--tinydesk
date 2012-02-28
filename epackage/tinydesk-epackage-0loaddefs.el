
;;;### (autoloads (tinydesk-recover-last-state tinydesk-recover-state
;;;;;;  tinydesk-save-state tinydesk-edit-state-file turn-off-tinydesk-mode
;;;;;;  tinydesk-mode tinydesk-unload) "../tinydesk" "../tinydesk.el"
;;;;;;  (20230 56634))
;;; Generated autoloads from ../tinydesk.el

(autoload 'tinydesk-unload "tinydesk" "\
Unload all files from Emacs that are in state file FILE.

If VERB is non-nil offer verbose messages [for code calls]; interactive
call always turns on verbose.

\(fn FILE &optional VERB)" t nil)

(autoload 'tinydesk-mode "tinydesk" "\
Mark and parse buffer's fist words as loada files.
If NO-FACE is non-nil, the default mouse marking isn't performed. VERB.

Comments in the right tell what is the files status:
loaded      = file inside Emacs already
invalid     = the path is invalid, no such file exists

Mode description:

\\{tinydesk-mode-map}

\(fn &optional NO-FACE VERB)" t nil)

(autoload 'turn-off-tinydesk-mode "tinydesk" "\
Turn off `tinydesk-mode'.

\(fn)" t nil)

(autoload 'tinydesk-edit-state-file "tinydesk" "\
Load state FILE into buffer for editing.
You can add comments and remove/add files. Turns on `tinydesk-mode'.

Following commands are available in `tinydesk-mode'.
\\{tinydesk-mode-map}

\(fn FILE)" t nil)

(autoload 'tinydesk-save-state "tinydesk" "\
Output all files in Emacs into FILE.
Notice, that this concerns only buffers with filenames.

Input:

  FILE          the STATE file being saved

  MODE          Control what is saved:
                 nil    only filenames
                 '(4)   \\[universal-argument], filenames and directories.
                 '(16)  \\[universal-argument] \\[universal-argument]
                        Use absolute paths to HOME.

  FILES         filenames , absolute ones. If nil then
                `tinydesk--get-save-file-function' is run to get files.
  VERB          verbose flag

\(fn FILE &optional MODE FILES VERB)" t nil)

(autoload 'tinydesk-recover-state "tinydesk" "\
Load all files listed in FILE into Emacs.
FILE can have empty lines or comments. No spaces allowed at the
beginning of filename. The state FILE itself is not left inside
Emacs if everything loads well. When all files are already
in Emacs, you may see message '0 files loaded'.

In case there were problems, the FILE will be shown and the
problematic lines are highlighted.

Prefix arg sets flag ULP, unload previous.

Input:

  FILE          state file to load

  ULP           'unload previous' if non-nil then unload previously
                loaded files according to `tinydesk--last-state-file'

  POP           if non-nil, show first buffer in saved
                state file. This flag is set to t in interactive calls.

  VERB          if non-nil, enable verbose messages. This flag is set to
                t in interactive calls.

References:

  `tinydesk--last-state-file'       Name of state file that was loaded.
  `tinydesk--recover-before-hook'   Hook to run before state file processing.
  `tinydesk--recover-after-hook'    Hook to run after state file processing.

\(fn FILE &optional ULP POP VERB)" t nil)

(autoload 'tinydesk-recover-last-state "tinydesk" "\
If Emacs was closed / crashed, recover last saved session.
References:
  `tinydesk--auto-save-interval'
  `tinydesk--auto-save-name-function'

\(fn)" nil nil)

;;;***
