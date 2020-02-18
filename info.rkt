#lang info
(define collection "smtp-lib")
(define deps '("base" "gregor-lib" "at-exp-lib" "r6rs-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/smtp-lib.scrbl" ())))
(define pkg-desc "send email with smtp protocol in Racket")
(define version "0.1")
(define pkg-authors '("Yanying Wang"))
