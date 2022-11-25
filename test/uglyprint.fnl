(local t (require :fspec))

(local up (require :uglyprint))

; is-array
(t.eq (up.is-array [1 2 3]) true)
(t.eq (up.is-array [1 nil 3]) true)
(t.eq (up.is-array []) false)
(t.eq (up.is-array {1 2 3 4}) false)
(t.eq (up.is-array { :test false :test2 true}) false)

; colorise-function
(t.eq (up.colorise-function (fn [] true)) "\27[38;2;245;169;127m\27[3mfunction\27[0m\27[0m")
(t.eq (up.colorise-function up.is-array) "\27[38;2;245;169;127m\27[3mfunction\27[0m\27[0m")

; colorise-string
; (t.eq (up.colorise-string :test) "\27[38;2;166;218;149mtest\27[0m")
; (t.eq (up.colorise-string "🧁") "\27[38;2;166;218;149m🧁\27[0m")

; colorise-number
(t.eq (up.colorise-number 69) "\27[38;2;145;215;227m69\27[0m")

; colorise-boolean
(t.eq (up.colorise-bool true) "\27[38;2;139;213;202m\27[1mtrue\27[0m\27[0m")
(t.eq (up.colorise-bool false) "\27[38;2;139;213;202m\27[1mfalse\27[0m\27[0m")

; colorise-nil
(t.eq (up.colorise-nil) "\27[38;2;237;135;150mnil\27[0m")

; colorise-table
(t.eq (up.colorise-table [1 2 3]) "\27[38;2;147;154;183m[\27[0m \27[38;2;145;215;227m1\27[0m\27[38;2;184;192;224m,\27[0m \27[38;2;145;215;227m2\27[0m\27[38;2;184;192;224m,\27[0m \27[38;2;145;215;227m3\27[0m \27[38;2;147;154;183m]\27[0m")

; colorise-dict
(t.eq (up.colorise-dict { :test 1}) "\27[38;2;128;135;162m{\27[0m \27[38;2;202;211;245mtest\27[0m\27[38;2;165;173;203m:\27[0m \27[38;2;145;215;227m1\27[0m \27[38;2;128;135;162m}\27[0m")


; colorise with all the above
(t.eq (up.colorise-function (fn [] true)) (up.colorise (fn [] true)))
(t.eq (up.colorise-function up.is-array) (up.colorise up.is-array))

(t.eq (up.colorise-string :test) (up.colorise :test))
(t.eq (up.colorise-string "🧁") (up.colorise "🧁"))

(t.eq (up.colorise-number 69) (up.colorise 69))

(t.eq (up.colorise-bool true) (up.colorise true))
(t.eq (up.colorise-bool false) (up.colorise false))

(t.eq (up.colorise-nil) (up.colorise nil))

(t.eq (up.colorise-table [1 2 3]) (up.colorise [1 2 3]))

(t.eq (up.colorise-dict { :test 1}) (up.colorise { :test 1}))



(t.run!)
