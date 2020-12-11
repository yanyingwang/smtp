#lang at-exp racket/base

(require rnrs/io/ports-6
         rnrs/bytevectors-6
         net/base64
         racket/list
         racket/format
         racket/string
         racket/port
         uuid)

(provide all-defined-out)

(define (b64en str)
  (bytes->string/utf-8 (base64-encode (string->bytes/utf-8 str))))
(define (b64en-trim str)
  (string-trim (b64en str)))

(define boundary
  @~a{__=_Part_@(uuid-string)})

(define (check-rsp? port code)
  (let ([rsp (utf8->string (get-bytevector-some port))])
    (when (current-smtp-debug-mode)
      (displayln (format "==> ~a" rsp)))
    (unless (string-prefix? rsp (number->string code))
      (error  @~a{smtp server @(current-smtp-host):
                       @rsp}))))

(define (write-str port str)
  (fprintf port (if (string-suffix? str "\r\n")
                    str
                    (string-append str "\r\n")))
  (flush-output port)
  (when (current-smtp-debug-mode)
    (displayln (format "==< ~a" str))))
