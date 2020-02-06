#lang scribble/manual
@require[@for-label[smtp-lib
                    racket/base]]

@title{smtp-lib}
@author[(author+email "yanyingwang" "yanyingwang1@gmail.com")]


@defmodule[smtp-lib]

send emails with SMTP protocol.

@hyperlink["https://github.com/yanyingwang/smtp-lib" "source code"]

@[table-of-contents]


@section{Procedure Reference}

mail struct needs specified here.

@defproc[(mail-from [email mail?]) string?]{
returns info about who the @italic{email} was sent from.
}

@defproc[(mail-tos [email mail?]) list?]{
returns info about who this @italic{email} was sent to.
}

@defproc[(mail-subject [email mail?]) string?]{
returns the @italic{email} subject.
}

@defproc[(mail-content [email mail?]) string?]{
returns the @italic{email} content.
}

@defproc[(mail-attachment-files [email mail?]) list?]{
returns a list of the @italic{email} attachment file paths.
}

@defproc[(mail-header [email mail?]) string?]{
returns header string of the @italic{email}.
}

@defproc[(mail-header/info [email mail?]) string?]{
returns sender, recipients, subject infos of an @italic{email}'s header.
}

@defproc[(mail-header/attachment [email mail?]) string?]{
returns sender, recipients, subject infos of an @italic{email}'s header.
}

@defproc[(send-mail [email mail?]
                    [#:host host string?]
                    [#:port port integer? 25]
                    [#:user username string? (mail-from mail)]
                    [#:password password string?]) void?]{
commit the @italic{email} sending action.
}



@section{Examples:}

@codeblock[#:keep-lang-line? #f]|{
(require smtp-lib)

(define email (mail "my-email-name@qq.com" ; sender's email
                    '("user1@qq.com", "user2@qq.com") ; recipient's emails
                    "email subject"
                    "email content"
                    '("file-path1" "file-path2") ; attachment files
                ))

(send-smtp-mail email
                #:host "smtp.qq.com"
                #:auth-user "my-email-name"
                #:auth-password "the-password")
}|
