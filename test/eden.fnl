(local t (require :fspec))

(local p (require :paco))
(local e (require :eden))

(local up (require :uglyprint))

; ✌️ Types ✌️
(t.eq (e.get-nil) { :type "nil" :value nil})
(t.eq (e.get-bool true) { :type "bool" :value true})
(t.eq (e.get-bool false) { :type "bool" :value false})
(t.eq (e.get-string "test") { :type "string" :value "test"})
(t.eq (e.get-string "") { :type "string" :value ""})
(t.eq (e.get-string "🐲") { :type "string" :value "🐲"})
(t.eq (e.get-integer 5) { :type "integer" :value 5})
(t.eq (e.get-float 5.5) { :type "float" :value 5.5})
(t.eq (e.get-symbol nil nil) { :type "symbol" :prefix nil :name nil})
(t.eq (e.get-symbol nil "test") { :type "symbol" :prefix nil :name "test"})
(t.eq (e.get-symbol "test1" "test2") { :type "symbol" :prefix "test1" :name "test2"})
(t.eq (e.get-keyword nil nil) { :type "keyword" :prefix nil :name nil})
(t.eq (e.get-keyword nil "test") { :type "keyword" :prefix nil :name "test"})
(t.eq (e.get-keyword "test1" "test2") { :type "keyword" :prefix "test1" :name "test2"})
(t.eq (e.symbol-to-keyword (e.get-symbol nil nil)) (e.get-keyword nil nil))
(t.eq (e.symbol-to-keyword (e.get-symbol nil "test")) (e.get-keyword nil "test"))
(t.eq (e.symbol-to-keyword (e.get-symbol "test1" "test2")) (e.get-keyword "test1" "test2"))

; p-whitespace
(t.eq (p.parse e.p-whitespace "") (p.gen-failure "Either: Either: Either: No more input, or No more input, or No more input, or No more input" "" 0 0))
(t.eq (p.parse e.p-whitespace " ") (p.gen-success {} "" 0 1))
(t.eq (p.parse e.p-whitespace "\t") (p.gen-success {} "" 0 1))
(t.eq (p.parse e.p-whitespace "\n") (p.gen-success {} "" 1 0))
(t.eq (p.parse e.p-whitespace ",") (p.gen-success {} "" 0 1))
(t.eq (p.parse e.p-whitespace " \t\n,") (p.gen-success {} "" 1 1))
(t.eq (p.parse e.p-whitespace " abc") (p.gen-success {} "abc" 0 1))
; p-whitespace-optional
(t.eq (p.parse e.p-whitespace-optional "") (p.gen-success "" "" 0 0))
(t.eq (p.parse e.p-whitespace-optional " ,,") (p.gen-success {} "" 0 3))
(t.eq (p.parse e.p-whitespace-optional " ,,abc") (p.gen-success {} "abc" 0 3))

; p-nil
(t.eq (p.parse ( e.p-nil ) "nil") (p.gen-success (e.get-nil) "" 0 3))
(t.eq (p.parse ( e.p-nil ) "il") (p.gen-failure "Expecting 'n', got 'i'." "il" 0 0))

; p-bool
(t.eq (p.parse ( e.p-bool ) "true") (p.gen-success (e.get-bool true) "" 0 4))
(t.eq (p.parse ( e.p-bool ) "false") (p.gen-success (e.get-bool false) "" 0 5))

; p-string
(t.eq (p.parse ( e.p-string ) "\"test\"") (p.gen-success (e.get-string "test") "" 0 6))
(t.eq (p.parse ( e.p-string ) "\"test\"abc") (p.gen-success (e.get-string "test") "abc" 0 6))

; p-digit-non-zero
(t.eq (p.parse e.p-digit-non-zero "0") (p.gen-failure "Either: Either: Either: Either: Either: Either: Either: Either: Expecting '1', got '0'., or Expecting '2', got '0'., or Expecting '3', got '0'., or Expecting '4', got '0'., or Expecting '5', got '0'., or Expecting '6', got '0'., or Expecting '7', got '0'., or Expecting '8', got '0'., or Expecting '9', got '0'." "0" 0 0))
(t.eq (p.parse e.p-digit-non-zero "1") (p.gen-success "1" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "21") (p.gen-success "2" "1" 0 1))
(t.eq (p.parse e.p-digit-non-zero "3") (p.gen-success "3" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "4") (p.gen-success "4" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "5") (p.gen-success "5" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "6") (p.gen-success "6" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "7") (p.gen-success "7" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "8") (p.gen-success "8" "" 0 1))
(t.eq (p.parse e.p-digit-non-zero "9") (p.gen-success "9" "" 0 1))
; p-digit
(t.eq (p.parse e.p-digit "0") (p.gen-success "0" "" 0 1))
; p-hex-digit
(t.eq (p.parse e.p-hex-digit "0") (p.gen-success "0" "" 0 1))
(t.eq (p.parse e.p-hex-digit "e") (p.gen-success "E" "" 0 1))
(t.eq (p.parse e.p-hex-digit "F") (p.gen-success "F" "" 0 1))
(t.eq (p.parse e.p-hex-digit "G") (p.gen-failure "Either: Either: Expecting '0', got 'G'., or Either: Either: Either: Either: Either: Either: Either: Either: Expecting '1', got 'G'., or Expecting '2', got 'G'., or Expecting '3', got 'G'., or Expecting '4', got 'G'., or Expecting '5', got 'G'., or Expecting '6', got 'G'., or Expecting '7', got 'G'., or Expecting '8', got 'G'., or Expecting '9', got 'G'., or Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Expecting 'a', got 'G'., or Expecting 'A', got 'G'., or Expecting 'b', got 'G'., or Expecting 'B', got 'G'., or Expecting 'c', got 'G'., or Expecting 'C', got 'G'., or Expecting 'd', got 'G'., or Expecting 'D', got 'G'., or Expecting 'e', got 'G'., or Expecting 'E', got 'G'., or Expecting 'f', got 'G'., or Expecting 'F', got 'G'." "G" 0 0))
; p-integer
(t.eq (p.parse ( e.p-integer ) "1") (p.gen-success (e.get-integer 1) "" 0 1))
(t.eq (p.parse ( e.p-integer ) "69") (p.gen-success (e.get-integer 69) "" 0 2))
(t.eq (p.parse ( e.p-integer ) "+69") (p.gen-success (e.get-integer 69) "" 0 3))
(t.eq (p.parse ( e.p-integer ) "-69") (p.gen-success (e.get-integer -69) "" 0 3))
(t.eq (p.parse ( e.p-integer ) "69N") (p.gen-success (e.get-integer 69) "" 0 3))
(t.eq (p.parse ( e.p-integer ) "069") (p.gen-failure "Either: Either: Either: Either: Either: Either: Either: Either: Expecting '1', got '0'., or Expecting '2', got '0'., or Expecting '3', got '0'., or Expecting '4', got '0'., or Expecting '5', got '0'., or Expecting '6', got '0'., or Expecting '7', got '0'., or Expecting '8', got '0'., or Expecting '9', got '0'." "069" 0 0))
; p-exponent
(t.eq (p.parse e.p-exponent "e50 ") (p.gen-success "e50" " " 0 3))
(t.eq (p.parse e.p-exponent "e+50 ") (p.gen-success "e+50" " " 0 4))
(t.eq (p.parse e.p-exponent "e-50 ") (p.gen-success "e-50" " " 0 4))
(t.eq (p.parse e.p-exponent "E50 ") (p.gen-success "E50" " " 0 3))
(t.eq (p.parse e.p-exponent "E+50 ") (p.gen-success "E+50" " " 0 4))
(t.eq (p.parse e.p-exponent "E-50 ") (p.gen-success "E-50" " " 0 4))
; p-float
(t.eq (p.parse ( e.p-float ) "5M") (p.gen-success (e.get-float 5.0) "" 0 2))
(t.eq (p.parse ( e.p-float ) "5.5") (p.gen-success (e.get-float 5.5) "" 0 3))
(t.eq (p.parse ( e.p-float ) "5e-3") (p.gen-success (e.get-float 0.005) "" 0 4))
(t.eq (p.parse ( e.p-float ) "5.5e-3") (p.gen-success (e.get-float 0.0055) "" 0 6))
(t.eq (p.parse ( e.p-float ) "5.5M") (p.gen-success (e.get-float 5.5) "" 0 4))
(t.eq (p.parse ( e.p-float ) "5e-3M") (p.gen-success (e.get-float 0.005) "" 0 5))
(t.eq (p.parse ( e.p-float ) "5.5e-3M") (p.gen-success (e.get-float 0.0055) "" 0 7))

; p-letter
(t.eq (p.parse e.p-letter "a") (p.gen-success "a" "" 0 1))
(t.eq (p.parse e.p-letter "A") (p.gen-success "A" "" 0 1))
; p-alphanumeric
(t.eq (p.parse e.p-alphanumeric "a") (p.gen-success "a" "" 0 1))
(t.eq (p.parse e.p-alphanumeric "A") (p.gen-success "A" "" 0 1))
(t.eq (p.parse e.p-alphanumeric "0") (p.gen-success "0" "" 0 1))
(t.eq (p.parse e.p-alphanumeric "5") (p.gen-success "5" "" 0 1))
; p-special-symbol
(t.eq (p.parse e.p-special-symbol "<") (p.gen-success "<" "" 0 1))
; p-constituent-character
(t.eq (p.parse e.p-constituent-character ":") (p.gen-success ":" "" 0 1))
(t.eq (p.parse e.p-constituent-character "#") (p.gen-success "#" "" 0 1))
; p-valid-special-symbol-start-char
(t.eq (p.parse e.p-valid-special-symbol-start-char "-") (p.gen-success "-" "" 0 1))
(t.eq (p.parse e.p-valid-special-symbol-start-char "+") (p.gen-success "+" "" 0 1))
(t.eq (p.parse e.p-valid-special-symbol-start-char ".") (p.gen-success "." "" 0 1))
; p-valid-symbol-char
(t.eq (p.parse e.p-valid-symbol-char "a") (p.gen-success "a" "" 0 1))
(t.eq (p.parse e.p-valid-symbol-char "-") (p.gen-success "-" "" 0 1))
(t.eq (p.parse e.p-valid-symbol-char "*") (p.gen-success "*" "" 0 1))
(t.eq (p.parse e.p-valid-symbol-char "3") (p.gen-success "3" "" 0 1))

; p-escape-char
(t.eq (p.parse e.p-escape-char "\\t") (p.gen-success "\t" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\r") (p.gen-success "\r" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\n") (p.gen-success "\n" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\\\") (p.gen-success "\\" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\\"") (p.gen-success "\"" "" 0 2))
; p-redundant-char
(t.eq (p.parse e.p-redundant-char "\\c") (p.gen-success "c" "" 0 2))
(t.eq (p.parse e.p-redundant-char "\\z") (p.gen-success "z" "" 0 2))
; p-edn-char
(t.eq (p.parse e.p-edn-char "\\newline") (p.gen-success "\n" "" 0 8))
(t.eq (p.parse e.p-edn-char "\\return") (p.gen-success "\r" "" 0 7))
(t.eq (p.parse e.p-edn-char "\\space") (p.gen-success " " "" 0 6))
(t.eq (p.parse e.p-edn-char "\\tab") (p.gen-success "\t" "" 0 4))
; p-unicode-char
(t.eq (p.parse e.p-unicode-char "\\u1f49c") (p.gen-success "💜" "" 0 7))
; p-char
(t.eq (p.parse ( e.p-char ) "\\u1f49c") (p.gen-success (e.get-char "💜") "" 0 7))
; p-string
(t.eq (p.parse ( e.p-string ) "test") (p.gen-failure "Expecting '\"', got 't'." "test" 0 0))
(t.eq (p.parse ( e.p-string ) "\"test\"") (p.gen-success (e.get-string "test") "" 0 6))
(t.eq (p.parse ( e.p-string ) "\"\\\"test\\\"\"") (p.gen-success (e.get-string "\"test\"") "" 0 10))
; (t.eq (p.parse e.p-string "\"\\newline\"") (p.gen-success (e.get-string "\n") "" 0 10))
(t.eq (p.parse ( e.p-string ) "\"te\\u1f49cst\"") (p.gen-success (e.get-string "te💜st") "" 0 13))
(t.eq (p.parse ( e.p-string ) "\"te\\st\"") (p.gen-success (e.get-string "test") "" 0 7))

; p-symbol-not-start
(t.eq (p.parse e.p-symbol-part "test") (p.gen-success "test" "" 0 4))
(t.eq (p.parse e.p-symbol-part "3test") (p.gen-failure "Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Either: Expecting 'a', got '3'., or Expecting 'b', got '3'., or Expecting 'c', got '3'., or Expecting 'd', got '3'., or Expecting 'e', got '3'., or Expecting 'f', got '3'., or Expecting 'g', got '3'., or Expecting 'h', got '3'., or Expecting 'i', got '3'., or Expecting 'j', got '3'., or Expecting 'k', got '3'., or Expecting 'l', got '3'., or Expecting 'm', got '3'., or Expecting 'n', got '3'., or Expecting 'o', got '3'., or Expecting 'p', got '3'., or Expecting 'q', got '3'., or Expecting 'r', got '3'., or Expecting 's', got '3'., or Expecting 't', got '3'., or Expecting 'u', got '3'., or Expecting 'v', got '3'., or Expecting 'w', got '3'., or Expecting 'x', got '3'., or Expecting 'y', got '3'., or Expecting 'z', got '3'., or Expecting 'A', got '3'., or Expecting 'B', got '3'., or Expecting 'C', got '3'., or Expecting 'D', got '3'., or Expecting 'E', got '3'., or Expecting 'F', got '3'., or Expecting 'G', got '3'., or Expecting 'H', got '3'., or Expecting 'I', got '3'., or Expecting 'J', got '3'., or Expecting 'K', got '3'., or Expecting 'L', got '3'., or Expecting 'M', got '3'., or Expecting 'N', got '3'., or Expecting 'O', got '3'., or Expecting 'P', got '3'., or Expecting 'Q', got '3'., or Expecting 'R', got '3'., or Expecting 'S', got '3'., or Expecting 'T', got '3'., or Expecting 'U', got '3'., or Expecting 'V', got '3'., or Expecting 'W', got '3'., or Expecting 'X', got '3'., or Expecting 'Y', got '3'., or Expecting 'Z', got '3'., or Either: Either: Expecting '-', got '3'., or Expecting '+', got '3'., or Expecting '.', got '3'." "3test" 0 0))
(t.eq (p.parse e.p-symbol-part "t2est") (p.gen-success "t2est" "" 0 5))
(t.eq (p.parse e.p-symbol-part "t*est") (p.gen-success "t*est" "" 0 5))
(t.eq (p.parse e.p-symbol-part "+est") (p.gen-success "+est" "" 0 4))
(t.eq (p.parse e.p-symbol-part "+e*t") (p.gen-success "+e*t" "" 0 4))
; p-symbol
(t.eq (p.parse ( e.p-symbol ) "test") (p.gen-success (e.get-symbol nil "test") "" 0 4))
(t.eq (p.parse ( e.p-symbol ) "test1/test2") (p.gen-success (e.get-symbol "test1" "test2") "" 0 11))
(t.eq (p.parse ( e.p-symbol ) "/") (p.gen-success (e.get-symbol nil nil) "" 0 1))
; p-keyword
(t.eq (p.parse ( e.p-keyword ) ":test") (p.gen-success (e.get-keyword nil "test") "" 0 5))
(t.eq (p.parse ( e.p-keyword ) "test") (p.gen-failure "Expecting ':', got 't'." "test" 0 0))
(t.eq (p.parse ( e.p-keyword ) ":test1/test2") (p.gen-success (e.get-keyword "test1" "test2") "" 0 12))

; p-edn-type
(t.eq (p.parse ( e.p-edn-type ) "nil") (p.gen-success (e.get-nil) "" 0 3))
(t.eq (p.parse ( e.p-edn-type ) "true") (p.gen-success (e.get-bool true) "" 0 4))
(t.eq (p.parse ( e.p-edn-type ) "\"test\"") (p.gen-success (e.get-string "test") "" 0 6))
; (t.eq (p.parse e.p-edn-type "69N") (p.gen-success (e.get-integer 69) "" 0 3))
(t.eq (p.parse ( e.p-edn-type ) "5.5e-3M") (p.gen-success (e.get-float 0.0055) "" 0 7))
(t.eq (p.parse ( e.p-edn-type ) "\\u1f49c") (p.gen-success (e.get-char "💜") "" 0 7))
(t.eq (p.parse ( e.p-edn-type ) "test") (p.gen-success (e.get-symbol nil "test") "" 0 4))
(t.eq (p.parse ( e.p-edn-type ) "test1/test2") (p.gen-success (e.get-symbol "test1" "test2") "" 0 11))
(t.eq (p.parse ( e.p-edn-type ) ":test") (p.gen-success (e.get-keyword nil "test") "" 0 5))
(t.eq (p.parse ( e.p-edn-type ) ":test1/test2") (p.gen-success (e.get-keyword "test1" "test2") "" 0 12))

; p-list
(t.eq (p.parse ( e.p-list ) "(nil nil nil)") (p.gen-success (e.get-list [(e.get-nil) (e.get-nil) (e.get-nil)]) "" 0 13))
(t.eq (p.parse ( e.p-list ) "(\"test\" 5.1 3 nil)") (p.gen-success (e.get-list [(e.get-string "test") (e.get-float 5.1) (e.get-integer 3) (e.get-nil)]) "" 0 18))
(t.eq (p.parse ( e.p-list ) "(1 (2 (3 4) 5) 6)")
      (p.gen-success (e.get-list [(e.get-integer 1)
                                  (e.get-list [(e.get-integer 2)
                                               (e.get-list [(e.get-integer 3) (e.get-integer 4)])
                                               (e.get-integer 5)])
                                  (e.get-integer 6)])
                    "" 0 17))

; p-vector
(t.eq (p.parse ( e.p-vector ) "[ nil nil nil ]") (p.gen-success (e.get-vector [(e.get-nil) (e.get-nil) (e.get-nil)]) "" 0 15))


; (up.pp (p.parse e.p-list "(nil nil nil)"))
; (print "\n")
; (up.pp (p.parse e.p-list "(\"moin\" 1 5.7)"))
; (print "\n")
; (up.pp (p.parse e.p-list "(nil (nil))"))
; (local t1 (p.parse e.p-char "\\a"))
; (local t2 (p.parse e.p-char "\\b"))
; (local t3 (p.combine-results t1 t2))
; (local t4 (p.parse e.p-char "\\c"))
; (print "\n\n--\n\n")
; (up.pp (p.table-prepend [t1 t2] t4))
; (up.pp (p.table-prepend [1 2] 3))
; (up.pp t1)
; (up.pp t3)
; (print "\n\n\n\n\n")
; (up.pp t3)
; (print "\n")
; (up.pp t4)
; (print "\n\n")
; (local t5 (p.combine-results t3 t4))
; (up.pp t5)
; (up.pp (p.parse e.p-list "(nil nil nil nil)"))
; (local test (p.shallow-flatten [[[(e.get-integer 1) (e.get-integer 2)] (e.get-integer 3)] (e.get-integer 4)]))
; (up.pp test)
; (up.pp (. test 1))
