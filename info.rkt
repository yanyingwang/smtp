#lang info
(define collection "smtp")
(define deps '("base" "gregor-lib" "at-exp-lib" "r6rs-lib" "uuid"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib" "scribble-rainbow-delimiters"))
(define scribblings '(("scribblings/smtp.scrbl" ())))
(define pkg-desc "a practical library to send emails using SMTP protocol")
(define version "0.1")
(define pkg-authors '("Yanying Wang"))
