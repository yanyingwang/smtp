#lang racket/base

(provide (all-defined-out))


(define current-smtp-debug-mode (make-parameter #f))

(define current-smtp-host (make-parameter ""))
(define current-smtp-port (make-parameter 25))
(define current-smtp-username (make-parameter ""))
(define current-smtp-password (make-parameter ""))
(define current-smtp-body-content-type (make-parameter "text/plain"))
