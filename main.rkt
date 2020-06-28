#lang at-exp racket/base

(require rnrs/io/ports-6
         rnrs/bytevectors-6
         net/base64
         racket/tcp
         racket/list
         racket/format
         racket/string
         racket/port
         racket/path
         racket/contract
         gregor
         uuid)

(provide mail
         mail?
         mail-sender
         mail-recipients
         mail-cc-recipients
         mail-bcc-recipients
         mail-subject
         mail-message-body
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
         mail-header/message-body
         mail-header/attachment
         mail-header

         send-smtp-mail
         set-mail-sender!
         current-smtp-debug-mode
         current-smtp-host
         current-smtp-port
         current-smtp-username
         current-smtp-password)


(define current-smtp-debug-mode (make-parameter #f))
(define current-smtp-host (make-parameter ""))
(define current-smtp-port (make-parameter 25))
(define current-smtp-username (make-parameter ""))
(define current-smtp-password (make-parameter ""))
(define current-smtp-body-content-type (make-parameter "text/plain"))


(define (b64en str)
  (bytes->string/utf-8 (base64-encode (string->bytes/utf-8 str))))
(define (b64en-trim str)
  (string-trim (b64en str)))

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
  (fprintf port (if (string-suffix? str "\r\n")
                    str
                    (string-append str "\r\n")))
  (flush-output port)
  (when (current-smtp-debug-mode)
    (displayln (format "==< ~a" str))))




;;;;;;;;;;;; mail
(define (make-mail subject message-body
                   #:from [sender (current-smtp-username)]
                   #:to [recipients '()]
                   #:cc [cc-recipients '()]
                   #:bcc [bcc-recipients '()]
                   #:attached-files [attached-files '()])
  ;; todo: if recipients = string, then convert it ot list, same do the cc bcc.
  (mail sender
        recipients cc-recipients bcc-recipients
        subject message-body attached-files))

(struct mail
  ([sender #:mutable]
   recipients cc-recipients bcc-recipients
   subject message-body attached-files)
  #:guard
  (lambda (sender
           recipients cc-recipients bcc-recipients
           subject message-body attached-files name)
    (and attached-files
         (for-each (lambda (f)
                     (unless (file-exists? (expand-user-path f)) (error @~a{struct:mail: file not exists, @f})))
                   attached-files))
    (values sender
            recipients cc-recipients bcc-recipients
            subject message-body attached-files))
  #:methods gen:custom-write
  [(define (write-proc mail port mode)
     (display @~a{#<mail to:@(~a (string-join (mail-recipients mail) ", ") #:max-width 16 #:limit-marker "...") subject:@(~a (mail-subject mail) #:max-width 16 #:limit-marker "...") message-body:@(~a (mail-message-body mail) #:max-width 16 #:limit-marker "...")>} port))]
  )

(define (mail-header/info mail)
  @~a{
      From: @(mail-sender mail)
      To: @(string-join (mail-recipients mail) ", ")
      @~a{Cc: @(string-join (mail-cc-recipients mail) ", ")}
      Subject: =?UTF-8?B?@(b64en-trim (mail-subject mail))?=
      MIME-Version: 1.0
      Content-type: multipart/alternative; boundary="@boundary"
      Date: @(~t (now/moment) "E, d MMM yyyy HH:mm:ss Z")
      })

(define (mail-header/message-body mail)
  @~a{
      --@boundary
      Content-Type: @(current-smtp-body-content-type); charset=UTF-8; format=flowed
      Content-Disposition: inline

      @(mail-message-body mail)
      })

(define (mail-header/attachment mail)
  (define files (mail-attached-files mail))
  (if (and (list? files) (not (empty? files)))
      (string-join (map (lambda (f)
                          @~a{
                              --@boundary
                              Content-Type: file --mime-type -b @(file-name-from-path f); name=@(file-name-from-path f);
                              Content-Transfer-Encoding: base64
                              Content-Disposition: attachment; filename=@(file-name-from-path f);

                              @(base64-encode (port->string (open-input-file f)))
                              })
                         (map (lambda (f) (expand-user-path f)) files))
                   "\n")
      ""))

(define (mail-header mail)
  @~a{
      @(mail-header/info mail)

      @(mail-header/message-body mail)

      @(mail-header/attachment mail)

      --@|boundary|--
      })


;;;;;;;;;;;; smtp
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
  (define headers (mail-header mail))

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
                   message-body-line1
                   message-body-line2
                   message-body-line3
                   message-body-line4
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
