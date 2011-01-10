;;--------------------------------------------------------------------
;; Teach emacs to syntax highlight Vagrantfile as Ruby.
;;
;; Installation: Copy the line below into your emacs configuration,
;; or drop this file anywhere in your "~/.emacs.d" directory and be
;; sure to "load" it.
;;--------------------------------------------------------------------
(add-to-list 'auto-mode-alist '("Vagrantfile$" . ruby-mode))
