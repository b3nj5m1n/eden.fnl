(local t (require :fspec))

(local up (require :uglyprint))

; is-array
(t.eq true (up.is-array [1 2 3]))
(t.eq true (up.is-array [1 nil 3]))
(t.eq false (up.is-array []))
(t.eq false (up.is-array {1 2 3 4}))
(t.eq false (up.is-array { :test false :test2 true}))

; colorise-function
(t.eq "\27[38;2;245;169;127m\27[3mfunction\27[0m\27[0m" (up.colorise-function (fn [] true)))
(t.eq "\27[38;2;245;169;127m\27[3mfunction\27[0m\27[0m" (up.colorise-function up.is-array))

; colorise-string
(t.eq "\27[38;2;166;218;149mtest\27[0m" (up.colorise-string :test))
(t.eq "\27[38;2;166;218;149m🧁\27[0m" (up.colorise-string "🧁"))

; colorise-number
(t.eq "\27[38;2;145;215;227m69\27[0m" (up.colorise-number 69))

; colorise-boolean
(t.eq "\27[38;2;139;213;202m\27[1mtrue\27[0m\27[0m" (up.colorise-bool true))
(t.eq "\27[38;2;139;213;202m\27[1mfalse\27[0m\27[0m" (up.colorise-bool false))

; colorise-nil
(t.eq "\27[38;2;237;135;150mnil\27[0m" (up.colorise-nil))

; colorise-table
(t.eq "\27[38;2;147;154;183m[\27[0m \27[38;2;145;215;227m1\27[0m\27[38;2;184;192;224m,\27[0m \27[38;2;145;215;227m2\27[0m\27[38;2;184;192;224m,\27[0m \27[38;2;145;215;227m3\27[0m \27[38;2;147;154;183m]\27[0m" (up.colorise-table [1 2 3]))

; colorise-dict
(t.eq "\27[38;2;128;135;162m{\27[0m \27[38;2;202;211;245mtest\27[0m\27[38;2;165;173;203m:\27[0m \27[38;2;145;215;227m1\27[0m \27[38;2;128;135;162m}\27[0m" (up.colorise-dict { :test 1}))


; colorise with all the above
(t.eq (up.colorise (fn [] true)) (up.colorise-function (fn [] true)))
(t.eq (up.colorise up.is-array) (up.colorise-function up.is-array))

(t.eq (up.colorise :test) (up.colorise-string :test))
(t.eq (up.colorise "🧁") (up.colorise-string "🧁"))

(t.eq (up.colorise 69) (up.colorise-number 69))

(t.eq (up.colorise true) (up.colorise-bool true))
(t.eq (up.colorise false) (up.colorise-bool false))

(t.eq (up.colorise nil) (up.colorise-nil))

(t.eq (up.colorise [1 2 3]) (up.colorise-table [1 2 3]))

(t.eq (up.colorise { :test 1}) (up.colorise-dict { :test 1}))



(t.run!)
