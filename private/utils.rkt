#lang at-exp racket/base

(require rnrs/io/ports-6
         rnrs/bytevectors-6
         net/base64
         racket/format
         racket/string
         uuid
         (file "params.rkt"))
(provide (all-defined-out))


(define (b64en str)
  (bytes->string/utf-8 (base64-encode (string->bytes/utf-8 str) #"")))

(define boundary
  @~a{----=_Part_@(uuid-string)})

(define (check-rsp? port code)
  (let ([rsp (utf8->string (get-bytevector-some port))])
    (when (current-smtp-debug-mode)
      (displayln (format "==> ~a" rsp)))
    (unless (string-prefix? rsp (number->string code))
      (error  @~a{smtp server @(current-smtp-host):
                       @rsp}))))

(define (write-str port str)
  (define newstr (string-append
                  (string-replace (string-trim str) "\n" "\r\n")
                  "\r\n"))
  (fprintf port newstr)
  (flush-output port)
  (when (current-smtp-debug-mode)
    (displayln (format "==< ~a" str))))
