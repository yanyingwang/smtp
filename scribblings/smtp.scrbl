#lang scribble/manual
@require[@for-label[smtp
                    racket/base]
         scribble-rainbow-delimiters]

@script/rainbow-delimiters*

@title{smtp}
@author[(author+email "Yanying Wang" "yanyingwang1@gmail.com")]

@defmodule[smtp]
A practical library to send emails using SMTP protocol.
@table-of-contents[]


@section{Guide}
@subsection[#:tag "parameter-auth-example"]{Sending Emails authenticated by @secref["smtp-parameters"]:}
@racketinput[(current-smtp-host "smtp.qq.com")]
@racketinput[(current-smtp-port 587)]
@racketinput[(current-smtp-username "sender1")]
@racketinput[(current-smtp-password "password1")]
@racketinput[(current-smtp-debug-mode #t)]
@racketinput[
(define a-mail
  (make-mail "a test email"
             "this is the message body of the test mail"
             #:from "sender1@qq.com"
             #:to '("recipient1@qq.com")
             #:cc '("recipient2@qq.com")
             #:bcc '("recipient3@qq.com" "recipient4@qq.com")
             #:attached-files '("~/abc.txt")))
]
@racketinput[
(define b-mail
  (make-mail "a test1 email"
             "this is the message body of the test1 mail"
             #:from "sender1@qq.com"
             #:to '("recipient1@qq.com")))
]
@racketinput[
(define c-mail
  (make-mail "a test2 email"
             "this is the message body of the test2 mail"
             #:from "sender2@qq.com"
             #:to '("recipient1@qq.com")))
]
@racketinput[(send-smtp-mail a-mail)]
@racketinput[(send-smtp-mail b-mail)]
@racketinput[(send-smtp-mail c-mail)]


@subsection{Sending authenticated Emails by dynamically binding some parameters:}
@racketinput[
(parameterize ([current-smtp-username "sender2"]
               [current-smtp-password "password2"])
  (send-smtp-mail c-mail))
]

@subsection[#:tag "functional-auth-example"]{Sending and authenticating Emails through function arguments:}
@racketinput[
(send-smtp-mail c-mail
                #:host "smtp.qq.com"
                #:port 25
                #:username "sender2"
                #:password "password2")
]

@subsection[#:tag "html-message-example"]{Sending html message:}
@racketinput[(current-smtp-body-content-type "text/html")]
@racketinput[
(define d-mail
   (make-mail "a test of html email"
              "<html><body> <h1>a test of html email</h1> <p>hello world!</p>"
              #:body-content-type "text/html" ;; use #:body-content-type here will overwrite default value from @racket[current-smtp-body-content-type].
              #:from "sender2@qq.com"
              #:to '("recipient1@qq.com")))
]
@racketinput[
(send-smtp-mail d-mail
                #:host "smtp.qq.com"
                #:port 25
                #:username "sender2"
                #:password "password2")
]

@subsection[#:tag "html-pic-message-example"]{Sending html message with embedding pictures:}
Since most nowadays modern browsers have already supported the @hyperlink["https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs" "Data URLs"],
we can just directly embed our pictures in the html content and send it:
@racketinput[
(define f-mail
   (make-mail "a test of html email"
   "<html>
   <body>
   <div>
   <p>Taken from wikpedia</p>
   <img src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAAUA AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO 9TXL0Y4OHwAAAABJRU5ErkJggg==\"
   alt=\"Red dot\" />
   </div>
   </body>
   </html>"
              #:body-content-type "text/html"
              #:from "sender2@qq.com"
              #:to '("recipient1@qq.com")))
]
@racketinput[
(send-smtp-mail f-mail
                #:host "smtp.qq.com"
                #:port 25
                #:username "sender2"
                #:password "password2")
]


@section{API}
@subsection[#:tag "smtp-parameters"]{Parameters}
@margin-note{Check basic info at Racket @secref["parameters" #:doc '(lib "scribblings/reference/reference.scrbl")].}

@deftogether[(
@defparam[current-smtp-host v string? #:value ""]
@defparam[current-smtp-port v integer? #:value 25]
@defparam[current-smtp-username v string? #:value ""]
@defparam[current-smtp-password v string? #:value ""]
)]{
set authentication to be used for sending Emails later, check usage example at @secref["parameter-auth-example"].
}

@defparam[current-smtp-body-content-type v string? #:value "text/plain"]{
@racket[current-smtp-body-content-type] is used for set smtp mail body's content type, check usage example at @secref["html-message-example"].
}

@defparam[current-smtp-debug-mode v boolean? #:value #f]{
@racket[current-smtp-debug-mode] is used for show status of the smtp auth debug mode or set to show or not show the smtp auth log.
}


@subsection{Making and sending mails}
@defproc[(make-mail [subject string?]
                    [message-body string?]
                    [#:from from string? (current-smtp-username)]
                    [#:to to (listof string?)]
                    [#:cc cc (listof string?) '()]
                    [#:bcc bcc (listof string?) '()]
                    [#:attached-files attached-files (listof (or/c path? string?)) '()]
                    [#:body-content-type body-content-type string? (current-smtp-body-content-type)])

mail?]{
Make @racket[mail] struct instances, check usage example at @secref["parameter-auth-example"].
}

@defproc[(send-smtp-mail [email mail?]
                    [#:host host string? (current-smtp-host)]
                    [#:port port integer? (current-smtp-port)]
                    [#:tls-encode tls-encode boolean? #f]
                    [#:user username string? (current-smtp-username)]
                    [#:password password string? (current-smtp-password)])

                    void?]{
Commit the @italic{email} sending action, check usage example at @secref["functional-auth-example"].
}


@subsection{Basis Structs}
@defstruct*[mail ([sender string?]
                  [recipients list?]
                  [cc-recipients list?]
                  [bcc-recipients list?]
                  [subject string?]
                  [message-body string?]
                  [attached-files list?])]{
  Structure of smtp mails.
}

@deftogether[(
@defproc[(mail? [email mail]) boolean?]
@defproc[(mail-sender [email mail?]) string?]
@defproc[(mail-recipients [email mail?]) list?]
@defproc[(mail-cc-recipients [email mail?]) list?]
@defproc[(mail-bcc-recipients [email mail?]) list?]
@defproc[(mail-subject [email mail?]) string?]
@defproc[(mail-attached-files [email mail?]) list?]

)]{
@racket[mail?] check if @italic{email} is an instance of struct @racket[mail] or not.   @linebreak[]
@racket[mail-sender] returns struct info about who the @italic{email} was @bold{sent from}.   @linebreak[]
@racket[mail-recipients] returns struct info about who this @italic{email} was @bold{sent to}.   @linebreak[]
@racket[mail-cc-recipients] returns struct info about who this @italic{email} was @bold{copied to}.   @linebreak[]
@racket[mail-bcc-recipients] returns struct info about who this @italic{email} was @bold{carbon copied to}.    @linebreak[]
@racket[mail-attached-files] returns struct info about @bold{a list of attachment file paths} of this @italic{email}.
}

@deftogether[(
@defproc[(mail-header [email mail?]) string?]
@defproc[(mail-header/info [email mail?]) string?]
@defproc[(mail-header/body [email mail?]) string?]
@defproc[(mail-header/attachment [email mail?]) string?]
)]{
@racket[mail-header] returns @italic{email} header which is used for sending.   @linebreak[]
@racket[mail-header/info] returns sender, recipients, subject infos of the @racket[mail-header] of @italic{email}.   @linebreak[]

}

@; @(index-section)