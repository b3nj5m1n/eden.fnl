(local p (require :paco))
(local up (require :uglyprint))

(var eden {})

(fn def-type [name]
  (tset eden (.. "get-" name)
        (fn [value]
          { :type name :value value})))

(def-type :nil)
(def-type :bool)
(def-type :string)
(def-type :integer)
(def-type :float)

(fn def-parser [name parser]
  (tset eden name parser))

(def-parser :p-whitespace (p.p-discard (p.p-map (fn [s] "") (p.p-many1 (p.p-any [" " "\t" "\n" ","])))))
(def-parser :p-whitespace-optional (p.p-option eden.p-whitespace))

(def-parser :p-digit-non-zero (p.p-any ["1" "2" "3" "4" "5" "6" "7" "8" "9"]))
(def-parser :p-digit (p.p-or (p.p-char "0") eden.p-digit-non-zero))
(def-parser :p-hex-digit
  (p.p-map
    (fn [digit]
      (digit:upper))
    (p.p-or eden.p-digit (p.p-any ["a" "A" "b" "B" "c" "C" "d" "D" "e" "E" "f" "F"]))))



(def-parser :p-nil (p.p-map (fn [_] (eden.get-nil)) (p.p-str "nil")))

(def-parser :p-bool (p.p-map
                      (fn [s]
                        (if (= s "true")
                          (eden.get-bool true)
                          (eden.get-bool false)))
                      (p.p-or (p.p-str "true") (p.p-str "false"))))

(def-parser :p-escape-char
  (p.p-map (fn [s]
             (match s
               "\\t"     "\t"
               "\\r"     "\r"
               "\\n"     "\n"
               "\\\\"     "\\"
               "\\\""     "\""))
    (p.p-choose
      [(p.p-str "\\t")
       (p.p-str "\\r")
       (p.p-str "\\n")
       (p.p-str "\\\\")
       (p.p-str "\\\"")])))

; TODO using \c, \a, \z etc to get the correspondig character which seems to be in the spec
(def-parser :p-edn-char
  (p.p-map (fn [s]
             (match s
               "\\newline"     "\n"
               "\\return"     "\r"
               "\\space"     " "
               "\\tab"     "\t"))
    (p.p-choose
       [(p.p-str "\\newline")
        (p.p-str "\\return")
        (p.p-str "\\space")
        (p.p-str "\\tab")])))

; Also parses \c with more than 4 hex numbers following
; the spec is a little unclear about this but there are unicode code points
; with more than 4 numbers so doing it like this makes the most sense
(def-parser :p-unicode-char
  (p.p-map
    (fn [x]
      (let [code-point (accumulate [result "" i current (ipairs (p.flatten x))] (.. result current))]
        (utf8.char (tonumber code-point 16))))
    (p.p-and (p.p-discard (p.p-str "\\u")) (p.p-many1 eden.p-hex-digit))))

(def-parser :p-string (p.p-map (fn [s]
                                 (let [result (accumulate [result "" i current (ipairs (p.flatten s))] (.. result current))]
                                   (eden.get-string result)))
                               (p.p-chain
                                 [(p.p-discard (p.p-char "\""))
                                  (p.p-str-until (p.p-choose [eden.p-unicode-char eden.p-edn-char eden.p-escape-char (p.p-char-negative "\"")]))
                                  (p.p-discard (p.p-char "\""))])))


(def-parser :p-integer
   (p.p-map
     (fn [digits]
       (local num-as-str (accumulate [result "" i current (ipairs (p.flatten digits))] (.. result current)))
       (if (= "N" (num-as-str:sub -1))
         (eden.get-integer (tonumber (num-as-str:sub 1 (- (length num-as-str) 1))))
         (eden.get-integer (tonumber num-as-str))))
     (p.p-chain
       [(p.p-option (p.p-or (p.p-char "-") (p.p-char "+")))
        eden.p-digit-non-zero
        (p.p-many eden.p-digit)
        (p.p-option (p.p-char "N"))])))

(def-parser :p-exponent
   (p.p-map
     (fn [chars]
       (accumulate [result "" i current (ipairs (p.flatten chars))] (.. result current)))
     (p.p-chain
       [(p.p-choose
          [(p.p-str "e+")
           (p.p-str "e-")
           (p.p-char "e")
           (p.p-str "E+")
           (p.p-str "E-")
           (p.p-char "E")])
        (p.p-many eden.p-digit)])))

(def-parser :p-float
   (p.p-map
     (fn [digits]
       (local num-as-str (accumulate [result "" i current (ipairs (p.flatten digits))] (.. result current)))
       (if (= "M" (num-as-str:sub -1))
         (eden.get-float (tonumber (+ 0.0 (num-as-str:sub 1 (- (length num-as-str) 1)))))
         (eden.get-float (tonumber (+ 0.0 num-as-str)))))
     (p.p-chain
       [(p.p-option (p.p-or (p.p-char "-") (p.p-char "+")))
        (p.p-many eden.p-digit)
        (p.p-option (p.p-chain [(p.p-char ".") (p.p-many eden.p-digit) (p.p-option eden.p-exponent)]))
        (p.p-option eden.p-exponent)
        (p.p-option (p.p-char "M"))])))
           



eden
