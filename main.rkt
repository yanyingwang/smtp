#lang at-exp racket/base

(require rnrs/io/ports-6
         rnrs/bytevectors-6
         net/base64
         racket/tcp
         racket/string
         racket/format
         racket/string
         racket/port
         racket/path
         gregor)

(provide mail
         mail-from
         mail-tos
         mail-subject
         mail-content
         mail-attachment-files
         mail-attachment-files/expanded
         mail-header
         mail-header/info
         mail-header/content
         mail-header/attachment
         mail-header/attachments
         send-smtp-mail
         set-mail-from!)


;;;;;;;;;;;; make mail
(struct mail
  ([from #:mutable] tos subject content attachment-files)
  #:guard (lambda (from tos subject content attachment-files name)
            (for-each (lambda (f) (unless (file-exists? (expand-user-path f))
                               (error @~a{file not exists @f})))
                      attachment-files)
            (values from tos subject content attachment-files)))

(define (mail-attachment-files/expanded mail)
  (map (lambda (f) (expand-user-path f))
       (mail-attachment-files mail)))

(define (mail-header/info mail)
  @~a{
      From: @(mail-from mail)
      To: @(string-join (mail-tos mail) ", ")
      Date: @(now/moment)
      Subject: @(mail-subject mail)
      MIME-Version: 1.0
      Content-type: multipart/mixed; boundary=000TheBoundary000
      })

(define (mail-header/content mail)
  @~a{
      --000TheBoundary000
      Content-Type: text/plain; charset=UTF-8; format=flowed
      Content-Disposition: inline

      @(mail-content mail)
      })

(define (mail-header/attachments mail)
  (map (lambda (f) @~a{
                  --000TheBoundary000
                  Content-Type: file --mime-type -b @(file-name-from-path f); name=@(file-name-from-path f);
                  Content-Transfer-Encoding: base64
                  Content-Disposition: attachment; filename=@(file-name-from-path f);

                  @(base64-encode (port->string (open-input-file f)))
                  })
       (mail-attachment-files/expanded mail)))

(define (mail-header/attachment mail)
  (string-join (mail-header/attachments mail) "\n"))

(define (mail-header mail)
  @~a{
      @(mail-header/info mail)

      @(mail-header/content mail)

      @(mail-header/attachment mail)
      })


;;;;;;;;;;;; send mail
(define (check-rsp? port code)
  (let ([rsp (utf8->string (get-bytevector-some port))])
    ;; (displayln (format "=== ~a" rsp)) #;debug
    (string-prefix? rsp (number->string code))))

(define (write-str port str)
  (fprintf port (if (string-suffix? str "\r\n")
                    str
                    (string-append str "\r\n")))
  (flush-output port)
  ;; (displayln (format "===> ~a" str)) #;debug
  )


(define (send-smtp-mail mail
                        #:host host
                        #:port [port 25]
                        #:auth-user [auth-user #f]
                        #:auth-passwd auth-passwd)

  (or (mail-from mail) (set-mail-from! mail auth-user))
  (define auth-user1 (if auth-user auth-user (mail-from mail)))
  (define auth-passwd1 auth-passwd)
  (define sender (mail-from mail))
  (define recipients (mail-tos mail))
  (define headers (mail-header mail))
  (define-values (r w) (tcp-connect host #;"smtp.qq.com"
                                    port #;587))

  (and (check-rsp? r 220)
       (write-str w "EHLO localhost.localdomain")
       (check-rsp? r 250)

       (write-str w "AUTH LOGIN")
       (check-rsp? r 334)
       (write-str w (bytes->string/utf-8 (base64-encode (string->bytes/utf-8  auth-user1))))
       (check-rsp? r 334)
       (write-str w (bytes->string/utf-8 (base64-encode (string->bytes/utf-8 auth-passwd1))))
       (check-rsp? r 235)

       (write-str w (format "MAIL FROM: <~a>" sender))
       (check-rsp? r 250)
       (for-each (lambda (i)
                   (and (write-str w (format "RCPT TO: <~a>" i))
                        (check-rsp? r 250)))
                 recipients)

       (write-str w "DATA")
       (check-rsp? r 354)
       (write-str w headers)

       (write-str w ".")
       (check-rsp? r 250)

       (write-str w "QUIT")
       (check-rsp? r 221)))



(module+ test
  (require rackunit))

(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.

  (check-equal? (+ 2 2) 4))
