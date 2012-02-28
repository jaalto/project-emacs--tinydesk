;; Prevent loading this file. Study the examples.
(error "tinydesk-epkg-examples.el is not a configuration file.")

;; To key bindings suggested in original package
(define-key ctl-x-4-map "S" 'tinydesk-save-state)
(define-key ctl-x-4-map "R" 'tinydesk-recover-state)
(define-key ctl-x-4-map "E" 'tinydesk-edit-state-file)
(define-key ctl-x-4-map "U" 'tinydesk-unload)

;; To restore session at Emacs startup
(add-hook 'tinydesk--load-hook 'tinydesk-recover-last-state)

;; End of file
