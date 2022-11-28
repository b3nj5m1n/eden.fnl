(local p (require :paco))
(local up (require :uglyprint))

(var eden {})

(fn def-type [name]
  (tset eden (.. "get-" name)
        (fn [value]
          {:type name :value value})))

(def-type :nil)
(def-type :bool)
(def-type :string)
(def-type :char)
(def-type :integer)
(def-type :float)
(def-type :list)
(def-type :vector)
(def-type :map)
(def-type :set)

(fn eden.result-to-lua [x]
  (let [t (if (not= nil (. x :result)) (. x :result) x)]
    ; (up.pp t)
    (match (. t :type)
      :nil nil
      :bool (. t :value)
      :string (. t :value)
      :char (. t :value)
      :integer (. t :value)
      :float (. t :value)
      :symbol (.. (if (= nil (. t :prefix)) "" (. t :prefix) ) (if (= nil (. t :prefix)) "" "/") (if (= nil (. t :name)) "" (. t :name)))
      :keyword (.. ":" (if (= nil (. t :prefix)) "" (. t :prefix) ) (if (= nil (. t :prefix)) "" "/") (if (= nil (. t :name)) "" (. t :name)))
      :list
      (do
        (icollect [_ v (ipairs (. t :value))]
          (eden.result-to-lua v)))
      :vector
      (do
        (icollect [_ v (ipairs (. t :value))]
          (eden.result-to-lua v)))
      :set
      (do
        (icollect [_ v (ipairs (. t :value))]
          (eden.result-to-lua v)))
      :map
      (do
        (collect [k v (pairs (. t :value))]
          (values (eden.result-to-lua k) (eden.result-to-lua v)))))))

(fn eden.get-symbol [prefix name]
  {:type "symbol" :prefix prefix :name name})
(fn eden.get-keyword [prefix name]
  {:type "keyword" :prefix prefix :name name})
(fn eden.symbol-to-keyword [symbol]
  (tset symbol :type "keyword")
  symbol)

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

(def-parser :p-letter
  (p.p-any
    ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"
     "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]))

(def-parser :p-alphanumeric
  (p.p-or eden.p-letter eden.p-digit))

(def-parser :p-special-symbol
  (p.p-any
    ["." "*" "+" "!" "-" "_" "?" "$" "%" "&" "=" "<" ">"]))

; From the spec:
; Additionally, : # are allowed as constituent characters in symbols other than as the first character.
(def-parser :p-constituent-character
  (p.p-any
    [":" "#"]))

; Relevant because, from the spec:
; If -, + or . are the first character, the second character (if any) must be non-numeric.
(def-parser :p-valid-special-symbol-start-char
  (p.p-any
    ["-" "+" "."]))

; Valid characters in a symbol/keyword, excluding the first character
(def-parser :p-valid-symbol-char
  (p.p-choose [eden.p-alphanumeric eden.p-special-symbol eden.p-constituent-character]))



(fn eden.p-nil []
  (p.p-map (fn [_] (eden.get-nil)) (p.p-str "nil")))

(fn eden.p-bool []
  (p.p-map
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

; Tbh I'm not sure if I understand the spec correctly here:
; Characters are preceded by a backslash: \c, ...
(def-parser :p-redundant-char
  (p.p-chain
     [(p.p-discard (p.p-char "\\"))
      (p.p-char-negative "\\")]))

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

(def-parser :p-char-all
  (p.p-choose [eden.p-unicode-char eden.p-edn-char eden.p-escape-char eden.p-redundant-char]))

(fn eden.p-char []
  (p.p-map
    (fn [x]
      (eden.get-char x))
    eden.p-char-all))

(fn eden.p-string []
  (p.p-map (fn [s]
             (eden.get-string s))
           (p.p-chain
             [(p.p-discard (p.p-char "\""))
              (p.p-str-until (p.p-choose
                               [eden.p-char-all
                                (p.p-char-negative "\"")]))
              (p.p-discard (p.p-char "\""))])))

(fn eden.p-integer []
  (p.p-map-fallible
    (fn [digits info-result info-input]
      (local num-as-str (p.result-to-str digits))
      (let [num (if (= "N" (num-as-str:sub -1)) (num-as-str:sub 1 (- (length num-as-str) 1)) num-as-str)]
        (if (= nil (tonumber num))
          (p.gen-failure "Failed parsing to int" info-input.remaining info-input.line info-input.col)
          (p.gen-success (eden.get-integer (tonumber num)) info-result.remaining info-result.line info-result.col))))
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

; TODO this needs to be reworked so ints don't get parsed as floats
(fn eden.p-float []
  (p.p-map-fallible
    (fn [digits info-result info-input]
      (local num-as-str (accumulate [result "" i current (ipairs (p.flatten digits))] (.. result current)))
      (let [num (if (= "M" (num-as-str:sub -1)) (num-as-str:sub 1 (- (length num-as-str) 1)) num-as-str)]
        (if (= nil (tonumber num))
          (p.gen-failure "Failed parsing to float" info-input.remaining info-input.line info-input.col)
          (p.gen-success (eden.get-float (+ 0.0 (tonumber num))) info-result.remaining info-result.line info-result.col))))
    (p.p-chain
      [(p.p-option (p.p-or (p.p-char "-") (p.p-char "+")))
       (p.p-many eden.p-digit)
       (p.p-option (p.p-chain [(p.p-char ".") (p.p-many eden.p-digit) (p.p-option eden.p-exponent)]))
       (p.p-option eden.p-exponent)
       (p.p-option (p.p-char "M"))])))
           
(def-parser :p-symbol-part
  (p.p-map
    (fn [x]
      (accumulate [result "" i current (ipairs (p.flatten x))] (.. result current)))
    (p.p-or
      (p.p-chain
        [eden.p-letter
         (p.p-many eden.p-valid-symbol-char)])
      (p.p-chain
        [eden.p-valid-special-symbol-start-char
         (p.p-option 
           (p.p-chain
             [eden.p-letter
              (p.p-option (p.p-many eden.p-valid-symbol-char))]))]))))

(fn eden.p-symbol []
  (p.p-map
    (fn [x]
      (match (accumulate [result "" i current (ipairs (p.flatten [ x ]))] (.. result current))
        "/" (eden.get-symbol nil nil)
        (where s (not (s:find "/"))) (eden.get-symbol nil s)
        s (eden.get-symbol (table.unpack (p.split s "/")))))
    (p.p-choose
      [(p.p-chain
         [eden.p-symbol-part
          (p.p-option (p.p-and (p.p-char "/") eden.p-symbol-part))])
       (p.p-char "/")])))

(fn eden.p-keyword []
  (p.p-map
    (fn [x]
      (eden.symbol-to-keyword x))
    (p.p-and (p.p-discard (p.p-char ":")) (eden.p-symbol))))

(fn eden.p-edn-type []
  (fn [input]
    (var done false)
    (var return {})
    (each [i parser (ipairs
                      [(eden.p-list)
                       (eden.p-vector)
                       (eden.p-set)
                       (eden.p-map)
                       (eden.p-nil)
                       (eden.p-string)
                       (eden.p-float)
                       (eden.p-integer)
                       (eden.p-bool)
                       (eden.p-keyword)
                       (eden.p-symbol)
                       (eden.p-char)])]
      (let [result (parser input)]
        (if (and (not done) (= result.status p.status.ok))
          (do
            (set done true)
            (set return result)))))
    (if (not done)
      (set return (p.gen-failure "Not an edn type" input.remaining input.line input.col)))
    return))

(fn eden.p-list []
  (p.p-map
    (fn [x]
      (eden.get-list x))
    (p.p-chain
      [(p.p-discard (p.p-and (p.p-char "(") (p.p-option eden.p-whitespace)))
       (p.p-option (eden.p-edn-type))
       (p.p-many (p.p-and eden.p-whitespace (eden.p-edn-type)))
       eden.p-whitespace-optional
       (p.p-discard (p.p-char ")"))])))

(fn eden.p-vector []
  (p.p-map
    (fn [x]
      (eden.get-vector x))
    (p.p-chain
      [(p.p-discard (p.p-and (p.p-char "[") (p.p-option eden.p-whitespace)))
       (p.p-option (eden.p-edn-type))
       (p.p-many (p.p-and eden.p-whitespace (eden.p-edn-type)))
       eden.p-whitespace-optional
       (p.p-discard (p.p-char "]"))])))

(fn eden.p-map []
  (p.p-map-fallible
    (fn [x info-result info-input]
      (if (= 0 (% (length x) 2))
        (do
          (var result {})
          (each [i value (ipairs x)]
            (if (= 1 (% i 2))
              (tset result value (. x (+ 1 i)))))
          (p.gen-success (eden.get-map result) info-result.remaining info-result.line info-result.col))
        (p.gen-failure "Expected even number of values for map" info-input.remaining info-input.line info-input.col)))
    (p.p-chain
      [(p.p-discard (p.p-and (p.p-char "{") (p.p-option eden.p-whitespace)))
       (p.p-option (eden.p-edn-type))
       (p.p-many (p.p-and eden.p-whitespace (eden.p-edn-type)))
       eden.p-whitespace-optional
       (p.p-discard (p.p-char "}"))])))

(fn eden.p-set []
  (p.p-map
    (fn [x]
      (eden.get-set x))
    (p.p-chain
      [(p.p-discard (p.p-and (p.p-str "#{") (p.p-option eden.p-whitespace)))
       (p.p-option (eden.p-edn-type))
       (p.p-many (p.p-and eden.p-whitespace (eden.p-edn-type)))
       eden.p-whitespace-optional
       (p.p-discard (p.p-char "}"))])))

eden
