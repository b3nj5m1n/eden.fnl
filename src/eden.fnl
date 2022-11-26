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

(def-parser :p-nil (p.p-map (fn [_] (eden.get-nil)) (p.p-str "nil")))

(def-parser :p-bool (p.p-map
                      (fn [s]
                        (if (= s "true")
                          (eden.get-bool true)
                          (eden.get-bool false)))
                      (p.p-or (p.p-str "true") (p.p-str "false"))))

; TODO make work for strings other than "test"
(def-parser :p-string (p.p-map (fn [s]
                                 (let [result (accumulate [result "" i current (ipairs (p.flatten s))] (.. result current))]
                                   (eden.get-string result)))
                               (p.p-chain
                                 [(p.p-discard (p.p-char "\""))
                                  (p.p-str "test")
                                  (p.p-discard (p.p-char "\""))])))


(def-parser :p-digit-non-zero (p.p-any ["1" "2" "3" "4" "5" "6" "7" "8" "9"]))
(def-parser :p-digit (p.p-or (p.p-char "0") eden.p-digit-non-zero))



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
