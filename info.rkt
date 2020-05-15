#lang info
(define collection "smtp")
(define deps '("base" "gregor-lib" "at-exp-lib" "r6rs-lib" "uuid"))
;; (define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/smtp.scrbl" ())))
(define pkg-desc "send email with smtp protocol")
(define version "0.1")
(define pkg-authors '("Yanying Wang"))
