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
         gregor
         uuid)

(provide mail
         mail-sender
         mail-recipients
         mail-cc-recipients
         mail-bcc-recipients
         mail-subject
         mail-content
         mail-attachment-files

         mail-header/info
         mail-header/content
         mail-header/attachment
         mail-header

         send-smtp-mail
         set-mail-sender!
         current-smtp-host
         current-smtp-port
         current-smtp-username
         current-smtp-password
         current-smtp-boundary)


(define current-smtp-host (make-parameter #f))
(define current-smtp-port (make-parameter 25))
(define current-smtp-username (make-parameter #f))
(define current-smtp-password (make-parameter #f))
(define current-smtp-boundary (make-parameter @~a{----=_Part_@(uuid-string)}))

(define (b64en str)
  (bytes->string/utf-8 (base64-encode (string->bytes/utf-8 str))))
(define (b64en-trim str)
  (string-trim (b64en str)))


;;;;;;;;;;;; make mail
(struct mail
  ([sender #:mutable]
   recipients cc-recipients bcc-recipients
   subject content attachment-files)
  #:guard
  (lambda (sender
      recipients cc-recipients bcc-recipients
      subject content attachment-files name)
    (and attachment-files
         (for-each (lambda (f) (unless (file-exists? (expand-user-path f))
                            (error @~a{file not exists @f})))
                   attachment-files))
    (values sender
            recipients cc-recipients bcc-recipients
            subject content attachment-files)))

(define (mail-header/info mail)
  @~a{
      From: @(mail-sender mail)
      To: @(string-join (mail-recipients mail) ", ")
      Subject: =?UTF-8?B?@(b64en-trim (mail-subject mail))?=
      MIME-Version: 1.0
      Content-type: multipart/alternative; boundary=@(current-smtp-boundary)
      Date: @(~t (now/moment) "E, d MMM yyyy HH:mm:ss Z")
      })

(define (mail-header/content mail)
  @~a{
      --@(current-smtp-boundary)
      Content-Type: text/plain; charset=UTF-8; format=flowed
      Content-Disposition: inline

      @(mail-content mail)
      })

(define (mail-header/attachment mail)
  (define files (mail-attachment-files mail))
  (if (and (list? files) (not (empty? files)))
      (string-join (map (lambda (f)
                          @~a{
                              --@(current-smtp-boundary)
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

      @(mail-header/content mail)

      @(mail-header/attachment mail)

      --@(current-smtp-boundary)--
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
                        #:host [host (current-smtp-host)]
                        #:port [port (current-smtp-port)]
                        #:username [username (current-smtp-username)]
                        #:password [password (current-smtp-password)])

  (unless (mail-sender mail) (set-mail-sender! mail username))
  (unless username (set! username (mail-sender mail)))
  (define sender (mail-sender mail))
  (define recipients (mail-recipients mail))
  (define cc-recipients (mail-cc-recipients mail))
  (define bcc-recipients (mail-bcc-recipients mail))
  (define headers (mail-header mail))
  (define-values (r w) (tcp-connect host
                                    port))

  (and (check-rsp? r 220)
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

  (current-smtp-host "smtp.qq.com")
  (current-smtp-port 587)
  (current-smtp-username "")
  (current-smtp-password "")
  (current-smtp-boundary "----=Part_abc_abc")

  (define mail-a
    (mail #f
          '("recipient1@qq.com" "recipient2@qq.com") #f #f
          "subject" "content" #f))
  (define mail-b
    (mail "sender1@qq.com"
          '("recipient1@qq.com" "recipient2@qq.com") '("recipient3@qq.com" "recipient4@qq.com") '("recipient5@qq.com" "recipient6@qq.com")
          "subject" "content" #f))

  #;(check-regexp-match
     @~a{
         From:
         To:
         Subject: =\?UTF-8\?B\?c3ViamVjdA==\?=
         MIME-Version: 1.0
         Content-type: multipart/alternative; boundary=.*
         Date: .*
         .*}
     (mail-header mail-b))

  #;(send-smtp-mail mail-c)

  )
