(local sn (require :supernova))

; Pretty print tables
; Doesn't work for properly for nil values
(var up {})

; https://stackoverflow.com/a/66370080/11110290
(fn up.is-array [t]
  (and (> (length t) 0) (= (next t (length t)) nil)))

(set up.colors 
  {:parens-normal "#6e738d"
   :parens-curly "#8087a2"
   :parens-brackets "#939ab7"

   :comma "#b8c0e0"
   :colon "#a5adcb"

   :quotes "#b8c0e0"

   :key "#cad3f5"

   :nil "#ed8796"
   :bool "#8bd5ca"
   :number "#91d7e3"
   :string "#a6da95"
   :function "#f5a97f"})

(set up.separators
  {:parens-open-normal (sn.color "(" up.colors.parens-normal)
   :parens-close-normal (sn.color ")" up.colors.parens-normal)
   :parens-open-curly (sn.color "{" up.colors.parens-curly)
   :parens-close-curly (sn.color "}" up.colors.parens-curly)
   :parens-open-brackets (sn.color "[" up.colors.parens-brackets)
   :parens-close-brackets (sn.color "]" up.colors.parens-brackets)

   :comma (sn.color "," up.colors.comma)
   :colon (sn.color ":" up.colors.colon)

   :quotes (sn.color "\"" up.colors.quotes)})

(fn up.colorise-dict [x]
  (var result "")
  (set result (.. result up.separators.parens-open-curly " "))
  (local suffix (.. up.separators.comma " "))
  (each [key value (pairs x)]
    ; Colorise key
    (set result (.. result (sn.color key up.colors.key)))
    (set result (.. result up.separators.colon " "))
    ; Colorise value
    (set result (.. result (up.colorise value)))
    (set result (.. result suffix)))
  ; Remove trailing ", "
  (set result (result:sub 1 (- (length result) (length suffix))))
  (set result (.. result " " up.separators.parens-close-curly))
  result)

(fn up.colorise-array [x]
  (var result "")
  (set result (.. result up.separators.parens-open-brackets " "))
  (local len (length x))
  (each [index value (ipairs x)]
    (set result (.. result (up.colorise value)))
    (when (< index len)
      (set result (.. result up.separators.comma " "))))
  (set result (.. result " " up.separators.parens-close-brackets))
  result)
               
(fn up.colorise-table [x]
  (if (up.is-array x)
    (up.colorise-array x)
    (up.colorise-dict x)))

(fn up.colorise-nil [x]
  (sn.color (tostring x) up.colors.nil))
(fn up.colorise-bool [x]
  (sn.bold.color (tostring x) up.colors.bool))
(fn up.colorise-number [x]
  (sn.color (tostring x) up.colors.number))
(fn up.colorise-string [x]
  (.. up.separators.quotes (sn.color (tostring x) up.colors.string) up.separators.quotes))
(fn up.colorise-function [x]
  (sn.italic.color "function" up.colors.function))


(fn up.colorise [x]
  (match (type x)
    "table"
    (up.colorise-table x)
    "nil"
    (up.colorise-nil x)
    "boolean"
    (up.colorise-bool x)
    "number"
    (up.colorise-number x)
    "string"
    (up.colorise-string x)
    "function"
    (up.colorise-function x)))

(fn up.pp [x]
  (print (up.colorise x)))

up
