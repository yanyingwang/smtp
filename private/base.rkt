#lang racket/base

(provide all-defined-out)



(define current-smtp-debug-mode (make-parameter #f))
(define current-smtp-host (make-parameter ""))
(define current-smtp-port (make-parameter 25))
(define current-smtp-username (make-parameter ""))
(define current-smtp-password (make-parameter ""))
(define current-smtp-body-content-type (make-parameter "text/plain"))


(struct mail
  ([sender #:mutable]
   recipients cc-recipients bcc-recipients
   subject body body-content-type attached-files)
  #:guard
  (lambda (sender
           recipients cc-recipients bcc-recipients
           subject body attached-files name)
    (and attached-files
         (for-each (lambda (f)
                     (unless (file-exists? (expand-user-path f)) (error @~a{struct:mail: file not exists, @f})))
                   attached-files))
    (values sender
            recipients cc-recipients bcc-recipients
            subject body attached-files))
  #:methods gen:custom-write
  [(define (write-proc mail port mode)
     (display @~a{#<mail to:@(~a (string-join (mail-recipients mail) ", ") #:max-width 16 #:limit-marker "...") subject:@(~a (mail-subject mail) #:max-width 16 #:limit-marker "...") body:@(~a (mail-body mail) #:max-width 16 #:limit-marker "...")>} port))]
  )

(define (mail-header mail)
  @~a{
      @(mail-header/info mail)

      @(mail-header/body mail)

      @(mail-header/attachment mail)

      --@|boundary|--
      })

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

(define (mail-header/body mail)
  @~a{
      --@boundary
      Content-Type: @(mail-body-content-type mail); charset=UTF-8; format=flowed
      Content-Disposition: inline

      @(mail-body mail)
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
