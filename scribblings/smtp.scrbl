#lang scribble/manual
@require[@for-label[smtp
                    racket/base]]

@title{smtp}
@author[(author+email "Yanying Wang" "yanyingwang1@gmail.com")]


@defmodule[smtp]

A practical library to send emails using SMTP protocol, @hyperlink["https://github.com/yanyingwang/smtp" "Source Code"].

@[table-of-contents]




@section{Example}

@codeblock[#:keep-lang-line? #f]|{

(current-smtp-host "smtp.qq.com")
(current-smtp-port 587)
(current-smtp-username "sender1")
(current-smtp-password "password1")
(current-smtp-debug-mode #t)

(define a-mail
  (make-mail "a test email"
             "this is the message body of the test mail"
             #:from "sender1@qq.com"
             #:to '("recipient1@qq.com")
             #:cc '("recipient2@qq.com")
             #:bcc '("recipient3@qq.com" "recipient4@qq.com")
             #:attached-files '("~/abc.txt")))

(define b-mail
  (make-mail "a test1 email"
             "this is the message body of the test1 mail"
             #:from "sender1@qq.com"
             #:to '("recipient1@qq.com")))

(define c-mail
  (make-mail "a test2 email"
             "this is the message body of the test2 mail"
             #:from "sender2@qq.com"
             #:to '("recipient1@qq.com")))


(send-smtp-mail a-mail)
(send-smtp-mail b-mail)

;; below code will do the sending with a different specified auth:
(send-smtp-mail c-mail
                #:host "smtp.qq.com"
                #:port 25
                #:username "sender2"
                #:password "password2")

;; below code will do the samething as the previous code:
(parameterize ([current-smtp-username "sender2"]
               [current-smtp-password "password2"])
  (send-smtp-mail c-mail))

}|



@section{Reference}

@defparam[current-smtp-debug-mode v boolean?
          #:value #f]{
show status of the smtp auth debug mode or set to show or not show the smtp auth log.
}

@defparam[current-smtp-host v string?
          #:value ""]{
set global smtp auth host.
}

@defparam[current-smtp-port v integer?
          #:value 25]{
set global smtp auth port number.
}

@defparam[current-smtp-username v string?
          #:value ""]{
set global smtp auth username.
}

@defparam[current-smtp-password v string?
          #:value ""]{
set global smtp auth password.
}


@defproc[(make-mail [subject string?]
                    [message-body string?]
                    [#:from from string? (current-smtp-username)]
                    [#:to to (listof string?)]
                    [#:cc cc (listof string?) '()]
                    [#:bcc bcc (listof string?) '()]
                    [#:attached-files attached-files (listof (or/c path? string?)) '()])

mail?]{
make a @racket[mail] struct instance.
}


@defproc[(send-smtp-mail [email mail?]
                    [#:host host string? (current-smtp-host)]
                    [#:port port integer? (current-smtp-port)]
                    [#:user username string? (current-smtp-username)]
                    [#:password password string? (current-smtp-password)])

                    void?]{
commit the @italic{email} sending action.
}


@defstruct*[mail ([sender string?]
                  [recipients list?]
                  [cc-recipients list?]
                  [bcc-recipients list?]
                  [subject string?]
                  [message-body string?]
                  [attached-files list?])]{
  A structure type for smtp mails.
}

@defproc[(mail? [email mail]) boolean?]{
check if @italic{email} is an instance of struct @racket[mail] or not.
}

@defproc[(mail-sender [email mail?]) string?]{
returns info about who the @italic{email} was sent from.
}

@defproc[(mail-recipients [email mail?]) list?]{
returns info about who this @italic{email} was sent to.
}

@defproc[(mail-subject [email mail?]) string?]{
returns the @italic{email} subject.
}

@defproc[(mail-message-body [email mail?]) string?]{
returns the @italic{email} content.
}

@defproc[(mail-attached-files [email mail?]) list?]{
returns a list of the @italic{email} attachment file paths.
}

@defproc[(mail-header/info [email mail?]) string?]{
returns sender, recipients, subject infos of the @italic{email}.
}

@defproc[(mail-header/message-body [email mail?]) string?]{
returns message body of the @italic{email}.
}

@defproc[(mail-header/attachment [email mail?]) string?]{
returns encoded attachment content of the @italic{email}.
}

@defproc[(mail-header [email mail?]) string?]{
returns header of the @italic{email}.
}




@section{Bug Report}

Please go to @url{https://github.com/yanyingwang/smtp/issues}.


@section{TODO}

@itemlist[@item{cc bcc}
          @item{message body type: html, plain-text ...}]
