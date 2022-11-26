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

; p-whitespace
(t.eq (p.parse e.p-whitespace "") (p.gen-failure "Either: Either: Either: No more input, or No more input, or No more input, or No more input" "" 0 0))
(t.eq (p.parse e.p-whitespace " ") (p.gen-success "" "" 0 1))
(t.eq (p.parse e.p-whitespace "\t") (p.gen-success "" "" 0 1))
(t.eq (p.parse e.p-whitespace "\n") (p.gen-success "" "" 1 0))
(t.eq (p.parse e.p-whitespace ",") (p.gen-success "" "" 0 1))
(t.eq (p.parse e.p-whitespace " \t\n,") (p.gen-success "" "" 1 1))
(t.eq (p.parse e.p-whitespace " abc") (p.gen-success "" "abc" 0 1))
; p-whitespace-optional
(t.eq (p.parse e.p-whitespace-optional "") (p.gen-success "" "" 0 0))
(t.eq (p.parse e.p-whitespace-optional " ,,") (p.gen-success "" "" 0 3))
(t.eq (p.parse e.p-whitespace-optional " ,,abc") (p.gen-success "" "abc" 0 3))

; p-nil
(t.eq (p.parse e.p-nil "nil") (p.gen-success (e.get-nil) "" 0 3))
(t.eq (p.parse e.p-nil "il") (p.gen-failure "Expecting 'n', got 'i'." "il" 0 0))

; p-bool
(t.eq (p.parse e.p-bool "true") (p.gen-success (e.get-bool true) "" 0 4))
(t.eq (p.parse e.p-bool "false") (p.gen-success (e.get-bool false) "" 0 5))

; p-string
(t.eq (p.parse e.p-string "\"test\"") (p.gen-success (e.get-string "test") "" 0 6))
(t.eq (p.parse e.p-string "\"test\"abc") (p.gen-success (e.get-string "test") "abc" 0 6))

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
; p-number
(t.eq (p.parse e.p-integer "69") (p.gen-success (e.get-integer 69) "" 0 2))
(t.eq (p.parse e.p-integer "+69") (p.gen-success (e.get-integer 69) "" 0 3))
(t.eq (p.parse e.p-integer "-69") (p.gen-success (e.get-integer -69) "" 0 3))
(t.eq (p.parse e.p-integer "69N") (p.gen-success (e.get-integer 69) "" 0 3))
(t.eq (p.parse e.p-integer "069") (p.gen-failure "Either: Either: Either: Either: Either: Either: Either: Either: Expecting '1', got '0'., or Expecting '2', got '0'., or Expecting '3', got '0'., or Expecting '4', got '0'., or Expecting '5', got '0'., or Expecting '6', got '0'., or Expecting '7', got '0'., or Expecting '8', got '0'., or Expecting '9', got '0'." "069" 0 0))
; p-exponent
(t.eq (p.parse e.p-exponent "e50 ") (p.gen-success "e50" " " 0 3))
(t.eq (p.parse e.p-exponent "e+50 ") (p.gen-success "e+50" " " 0 4))
(t.eq (p.parse e.p-exponent "e-50 ") (p.gen-success "e-50" " " 0 4))
(t.eq (p.parse e.p-exponent "E50 ") (p.gen-success "E50" " " 0 3))
(t.eq (p.parse e.p-exponent "E+50 ") (p.gen-success "E+50" " " 0 4))
(t.eq (p.parse e.p-exponent "E-50 ") (p.gen-success "E-50" " " 0 4))
; p-float
(t.eq (p.parse e.p-float "5M") (p.gen-success (e.get-float 5.0) "" 0 2))
(t.eq (p.parse e.p-float "5.5") (p.gen-success (e.get-float 5.5) "" 0 3))
(t.eq (p.parse e.p-float "5e-3") (p.gen-success (e.get-float 0.005) "" 0 4))
(t.eq (p.parse e.p-float "5.5e-3") (p.gen-success (e.get-float 0.0055) "" 0 6))
(t.eq (p.parse e.p-float "5.5M") (p.gen-success (e.get-float 5.5) "" 0 4))
(t.eq (p.parse e.p-float "5e-3M") (p.gen-success (e.get-float 0.005) "" 0 5))
(t.eq (p.parse e.p-float "5.5e-3M") (p.gen-success (e.get-float 0.0055) "" 0 7))

; p-escape-char
(t.eq (p.parse e.p-escape-char "\\t") (p.gen-success "\t" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\r") (p.gen-success "\r" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\n") (p.gen-success "\n" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\\\") (p.gen-success "\\" "" 0 2))
(t.eq (p.parse e.p-escape-char "\\\"") (p.gen-success "\"" "" 0 2))
; p-edn-char
(t.eq (p.parse e.p-edn-char "\\newline") (p.gen-success "\n" "" 0 8))
(t.eq (p.parse e.p-edn-char "\\return") (p.gen-success "\r" "" 0 7))
(t.eq (p.parse e.p-edn-char "\\space") (p.gen-success " " "" 0 6))
(t.eq (p.parse e.p-edn-char "\\tab") (p.gen-success "\t" "" 0 4))
; p-unicode-char
(t.eq (p.parse e.p-unicode-char "\\u1f49c") (p.gen-success "💜" "" 0 7))
; p-string
(t.eq (p.parse e.p-string "test") (p.gen-failure "Expecting '\"', got 't'." "test" 0 0))
(t.eq (p.parse e.p-string "\"test\"") (p.gen-success (e.get-string "test") "" 0 6))
(t.eq (p.parse e.p-string "\"\\\"test\\\"\"") (p.gen-success (e.get-string "\"test\"") "" 0 10))
(t.eq (p.parse e.p-string "\"\\newline\"") (p.gen-success (e.get-string "\n") "" 0 10))
(t.eq (p.parse e.p-string "\"te\\u1f49cst\"") (p.gen-success (e.get-string "te💜st") "" 0 13))

