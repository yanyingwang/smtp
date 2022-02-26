1366
((3) 0 () 2 ((q lib "smtp/main.rkt") (q 2128 . 15)) () (h ! (equal) ((c def c (c (? . 0) q mail?)) c (q 2531 . 3) c (? . 1)) ((c def c (c (? . 0) q mail-header)) q (2993 . 3)) ((c def c (c (? . 0) q send-smtp-mail)) q (1548 . 13)) ((c def c (c (? . 0) q current-smtp-debug-mode)) q (569 . 5)) ((c def c (c (? . 0) q current-smtp-body-content-type)) q (430 . 5)) ((c def c (c (? . 0) q mail-header/attachment)) q (3195 . 3)) ((c def c (c (? . 0) q mail-sender)) c (q 2589 . 3) c (? . 1)) ((c def c (c (? . 0) q make-mail)) q (686 . 17)) ((c def c (c (? . 0) q mail-attached-files)) c (q 2923 . 3) c (? . 1)) ((c def c (c (? . 0) q current-smtp-username)) q (208 . 5)) ((c def c (c (? . 0) q current-smtp-host)) q (0 . 5)) ((c def c (c (? . 0) q mail-cc-recipients)) c (q 2719 . 3) c (? . 1)) ((c def c (c (? . 0) q current-smtp-password)) q (319 . 5)) ((c def c (c (? . 0) q mail-header/body)) q (3126 . 3)) ((c def c (c (? . 0) q mail)) c (? . 1)) ((c def c (c (? . 0) q current-smtp-port)) q (103 . 5)) ((c def c (c (? . 0) q struct:mail)) c (? . 1)) ((c def c (c (? . 0) q mail-recipients)) c (q 2653 . 3) c (? . 1)) ((c def c (c (? . 0) q mail-message-body)) c (? . 1)) ((c def c (c (? . 0) q mail-bcc-recipients)) c (q 2788 . 3) c (? . 1)) ((c def c (c (? . 0) q mail-header/info)) q (3057 . 3)) ((c def c (c (? . 0) q mail-subject)) c (q 2858 . 3) c (? . 1))))
parameter
(current-smtp-host) -> string?
(current-smtp-host v) -> void?
  v : string?
 = ""
parameter
(current-smtp-port) -> integer?
(current-smtp-port v) -> void?
  v : integer?
 = 25
parameter
(current-smtp-username) -> string?
(current-smtp-username v) -> void?
  v : string?
 = ""
parameter
(current-smtp-password) -> string?
(current-smtp-password v) -> void?
  v : string?
 = ""
parameter
(current-smtp-body-content-type) -> string?
(current-smtp-body-content-type v) -> void?
  v : string?
 = "text/plain"
parameter
(current-smtp-debug-mode) -> boolean?
(current-smtp-debug-mode v) -> void?
  v : boolean?
 = #f
procedure
(make-mail  subject                                     
            message-body                                
           [#:from from]                                
            #:to to                                     
           [#:cc cc                                     
            #:bcc bcc                                   
            #:attached-files attached-files             
            #:body-content-type body-content-type]) -> mail?
  subject : string?
  message-body : string?
  from : string? = (current-smtp-username)
  to : (listof string?)
  cc : (listof string?) = '()
  bcc : (listof string?) = '()
  attached-files : (listof (or/c path? string?)) = '()
  body-content-type : string? = (current-smtp-body-content-type)
procedure
(send-smtp-mail  email                       
                [#:host host                 
                 #:port port                 
                 #:tls-encode tls-encode     
                 #:user username             
                 #:password password])   -> void?
  email : mail?
  host : string? = (current-smtp-host)
  port : integer? = (current-smtp-port)
  tls-encode : boolean? = #f
  username : string? = (current-smtp-username)
  password : string? = (current-smtp-password)
struct
(struct mail (sender
              recipients
              cc-recipients
              bcc-recipients
              subject
              message-body
              attached-files))
  sender : string?
  recipients : list?
  cc-recipients : list?
  bcc-recipients : list?
  subject : string?
  message-body : string?
  attached-files : list?
procedure
(mail? email) -> boolean?
  email : mail
procedure
(mail-sender email) -> string?
  email : mail?
procedure
(mail-recipients email) -> list?
  email : mail?
procedure
(mail-cc-recipients email) -> list?
  email : mail?
procedure
(mail-bcc-recipients email) -> list?
  email : mail?
procedure
(mail-subject email) -> string?
  email : mail?
procedure
(mail-attached-files email) -> list?
  email : mail?
procedure
(mail-header email) -> string?
  email : mail?
procedure
(mail-header/info email) -> string?
  email : mail?
procedure
(mail-header/body email) -> string?
  email : mail?
procedure
(mail-header/attachment email) -> string?
  email : mail?
