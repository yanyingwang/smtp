#lang at-exp racket/base

(require racket/tcp
         racket/format
         racket/string
         racket/contract
         (file "private/params.rkt")
         (file "private/utils.rkt")
         (file "private/core.rkt"))


(provide mail
         mail?
         mail-sender
         mail-recipients
         mail-cc-recipients
         mail-bcc-recipients
         mail-subject
         mail-body
         mail-attached-files
         (contract-out
          [make-mail (->* (string?
                           string?
                           #:to (listof string?))
                          (#:from string?
                           #:cc (listof string?)
                           #:bcc (listof string?)
                           #:attached-files (listof (or/c path? string?)))
                          any)])
         mail-header/info
         mail-header/body
         mail-header/attachment
         mail-header
         send-smtp-mail
         set-mail-sender!
         current-smtp-debug-mode
         current-smtp-host
         current-smtp-port
         current-smtp-username
         current-smtp-password
         current-smtp-body-content-type)



(define (make-mail subject body
                   #:from [sender (current-smtp-username)]
                   #:to [recipients '()]
                   #:cc [cc-recipients '()]
                   #:bcc [bcc-recipients '()]
                   #:attached-files [attached-files '()]
                   #:body-content-type [body-content-type (current-smtp-body-content-type)])
  ;; todo: if recipients = string, then convert it to list, same do the cc bcc.
  (mail sender
        recipients cc-recipients bcc-recipients
        subject body body-content-type attached-files))

(define (send-smtp-mail mail
                        #:host [host (current-smtp-host)]
                        #:port [port (current-smtp-port)]
                        #:username [username (current-smtp-username)]
                        #:password [password (current-smtp-password)])

  (unless (mail-sender mail) (set-mail-sender! mail username))
  (unless username (set! username (mail-sender mail)))
  (unless (non-empty-string? username) (set! username (mail-sender mail)))
  (define sender (mail-sender mail))
  (define recipients (mail-recipients mail))
  (define cc-recipients (mail-cc-recipients mail))
  (define bcc-recipients (mail-bcc-recipients mail))
  (define headers (formated-mail-header mail))

  (when (current-smtp-debug-mode)
    (displayln @~a{starting to connect @|host|:@|port|......}))
  (define-values (r w) (tcp-connect host port))

  (check-rsp? r 220)
  (write-str w "EHLO localhost.localdomain")
  (check-rsp? r 250)

  (write-str w "AUTH LOGIN")
  (check-rsp? r 334)
  (write-str w (b64en username))
  (check-rsp? r 334)
  (write-str w (b64en password))
  (check-rsp? r 235)

  (write-str w (format "MAIL FROM: <~a>" sender))
  (check-rsp? r 250)
  (for-each (lambda (i)
              (and (write-str w (format "RCPT TO: <~a>" i))
                   (check-rsp? r 250)))
            recipients)
  (for-each (lambda (i)
              (and (write-str w (format "RCPT TO: <~a>" i))
                   (check-rsp? r 250)))
            cc-recipients)
  (for-each (lambda (i)
              (and (write-str w (format "RCPT TO: <~a>" i))
                   (check-rsp? r 250)))
            bcc-recipients)

  (write-str w "DATA")
  (check-rsp? r 354)
  (write-str w headers)

  (write-str w ".")
  (check-rsp? r 250)

  (write-str w "QUIT")
  (check-rsp? r 221))




(module+ test
  (require rackunit))

(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.

  (check-false (current-smtp-debug-mode))
  ;; (current-smtp-debug-mode #t)
  ;; (check-true (current-smtp-debug-mode))

  (check-equal? (current-smtp-host) "")
  (check-equal? (current-smtp-port) 25)
  (check-equal? (current-smtp-username) "")
  (check-equal? (current-smtp-password) "")

  (current-smtp-host "smtp.qq.com")
  (current-smtp-port 587)
  (current-smtp-username "test1")
  (current-smtp-password "test1password")

  (check-equal? (current-smtp-host) "smtp.qq.com")
  (check-equal? (current-smtp-port) 587)
  (check-equal? (current-smtp-username) "test1")
  (check-equal? (current-smtp-password) "test1password")

  (define a-mail
    (make-mail "rackunit test email"
               @~a{
                   body-line1
                   body-line2
                   body-line3
                   body-line4
                   }
               #:from "sender1@qq.com"
               #:to '("recipient1@qq.com" "recipient2@qq.com")
               #:cc '("recipient3@qq.com" "recipient4@qq.com")
               #:bcc '("recipient5@qq.com")))


  (check-regexp-match @~a|{
                           From: sender1@qq.com
                           To: recipient1@qq.com, recipient2@qq.com
                           Cc: recipient3@qq.com, recipient4@qq.com
                           Subject: =\?UTF-8\?B\?cmFja3VuaXQgdGVzdCBlbWFpbA==\?=
                           MIME-Version: 1.0
                           Content-type: multipart/alternative; boundary=".*"
                           Date: .*
                           .*
                           }|
                      (mail-header a-mail))


  (check-exn exn:fail?
             (lambda ()
               (send-smtp-mail a-mail)))


  )
