(local t (require :fspec))

(local p (require :paco))
(local e (require :eden))

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
(local up (require :uglyprint))
(t.eq (p.parse e.p-float "5M") (p.gen-success (e.get-float 5.0) "" 0 2))
(t.eq (p.parse e.p-float "5.5") (p.gen-success (e.get-float 5.5) "" 0 3))
(t.eq (p.parse e.p-float "5e-3") (p.gen-success (e.get-float 0.005) "" 0 4))
(t.eq (p.parse e.p-float "5.5e-3") (p.gen-success (e.get-float 0.0055) "" 0 6))
(t.eq (p.parse e.p-float "5.5M") (p.gen-success (e.get-float 5.5) "" 0 4))
(t.eq (p.parse e.p-float "5e-3M") (p.gen-success (e.get-float 0.005) "" 0 5))
(t.eq (p.parse e.p-float "5.5e-3M") (p.gen-success (e.get-float 0.0055) "" 0 7))
