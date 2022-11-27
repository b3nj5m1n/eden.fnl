(local up (require :uglyprint))

; Simple parser combinator

(var paco {})

(fn paco.is-empty [x]
  "Check if the variable is empty.
  (in case of string, check if string is literally empty, whitespace doesn't
  count as empty since you might want to do something with that)"
  (match (type x)
    "string" (or (= x nil) (= x ""))
    "table" (not (next x))
    "nil" true
    _ false))

(fn paco.reduce [reduce-func list]
  "Apply function to every pair of elements in the list, taking the result as
  the first element in the next iteration to reduce to single value"
  (var val (reduce-func (. list 1) (. list 2)))
  (each [i elem (ipairs list)]
    (when (> i 2)
      (set val (reduce-func val elem))))
  val)

(fn paco.flatten [input flattened]
  "Flatten multi-dimensional array to single dimension while preserving order"
  (set-forcibly! flattened (or flattened {}))
  (each [i element (ipairs input)]
    (if (and (= (type element) :table))
        (paco.flatten element flattened)
        (table.insert flattened element)))
  flattened)

; https://stackoverflow.com/a/40180465/11110290
(fn paco.split [s sep]
  "Split string by delimiter"
  (let [fields {}
        sep (or sep " ")
        pattern (string.format "([^%s]+)" sep)]
    (string.gsub s pattern
                 (fn [c]
                   (tset fields (+ (length fields) 1) c)))
    fields))

(fn paco.combine-results [result-1 result-2]
  "Split string by delimiter"
  (match [ result-1.result result-2.result]
    (where [x y] (and (not (paco.is-empty x))) (not (paco.is-empty y))) [x y]
    (where [x y] (and (not (not (paco.is-empty x)))) (not (paco.is-empty y))) y
    (where [x y] (and (not (paco.is-empty x))) (not (not (paco.is-empty y)))) x))


(set paco.status {:ok 1 :error 0})

(fn paco.gen-success [result remaining line col]
  "Generate input/output table for successful parsing"
  {:status paco.status.ok
   :result result
   :remaining remaining
   :line line
   :col col})
(fn paco.gen-failure [message remaining line col]
  "Generate input/output table for unsuccessful parsing"
  {:status paco.status.error
   :result message
   :remaining remaining
   :line line
   :col col})
   

(fn paco.p-char [char-to-match]
  "Parse a single character
  (character as in byte, use str for unicode character)"
  (fn [input]
    (if (paco.is-empty input.remaining)
      (paco.gen-failure "No more input" input.line input.col)
      (let [first (input.remaining:sub 1 1)]
        (if (= first char-to-match)
          (let [line (if (= first "\n") (+ input.line 1) input.line)
                col (if (= first "\n") 0 (+ input.col 1))]
            (paco.gen-success first (input.remaining:sub 2) line col))
          (paco.gen-failure (.. "Expecting '" char-to-match "', got '" first "'.") input.remaining input.line input.col))))))

(fn paco.p-char-negative [char-to-match]
  "Parse any character except the one provided
  (character as in byte, use str for unicode character)"
  (fn [input]
    (if (paco.is-empty input.remaining)
      (paco.gen-failure "No more input" input.line input.col)
      (let [first (input.remaining:sub 1 1)]
        (if (= first char-to-match)
          (paco.gen-failure (.. "Not expecting '" first "'.") input.remaining input.line input.col)
          (let [line (if (= first "\n") (+ input.line 1) input.line)
                col (if (= first "\n") 0 (+ input.col 1))]
            (paco.gen-success first (input.remaining:sub 2) line col)))))))

(fn paco.p-str [string-to-match]
  "Parse a string"
  (var parsers [])
  (each [c (string-to-match:gmatch ".")]
    (table.insert parsers (paco.p-char c)))
  (paco.p-map 
    (fn [s] 
      (accumulate [result "" i current (ipairs (paco.flatten s))] (.. result current)))
    (paco.p-chain parsers)))

(fn paco.p-str-until [delimiter]
  "Consume input into a string until a delimiter parser"
  (paco.p-map 
    (fn [s] 
      (accumulate [result "" i current (ipairs (paco.flatten s))] (.. result current)))
    (paco.p-many delimiter)))


(fn paco.p-and [parser-1 parser-2]
  "Combine two parsers, succeed if both succeed"
  (fn [input]
    (let [result-1 (parser-1 input)]
      (if (= result-1.status paco.status.error)
        (paco.gen-failure result-1.result input.remaining input.line input.col)
        (let [result-2 (parser-2 result-1)]
          (if (= result-2.status paco.status.error)
            (paco.gen-failure result-2.result input.remaining input.line input.col)
            (paco.gen-success (paco.combine-results result-1 result-2) result-2.remaining result-2.line result-2.col)))))))

(fn paco.p-or [parser-1 parser-2]
  "Combine two parsers, succeed if one of them succeeds"
  (fn [input]
    (let [result-1 (parser-1 input)]
      (if (= result-1.status paco.status.ok)
        result-1
        (let [result-2 (parser-2 input)]
          (if (= result-2.status paco.status.ok)
            result-2
            (let [error-1 result-1.result
                  error-2 result-2.result
                  pos-1 { :line result-1.line :col result-1.col}
                  pos-2 { :line result-2.line :col result-2.col}]
              (paco.gen-failure (.. "Either: " error-1 ", or " error-2) input.remaining input.line input.col))))))))

(fn paco.p-chain [parsers]
  "Combine an arbitrary amount of parsers, succeed if all of them succeed"
  (if (> (length parsers) 1)
    (paco.reduce paco.p-and parsers)
    (fn [input]
      (let [result ((. parsers 1) input)]
        (if (= result.status paco.status.error)
          (paco.gen-failure result.result input.remaining input.line input.col)
          (paco.gen-success result.result result.remaining result.line result.col))))))

(fn paco.p-choose [parsers]
  "Combine an arbitrary amount of parsers, succeed if one of them succeeds"
  (if (> (length parsers) 1)
    (paco.reduce paco.p-or parsers)
    (fn [input]
      (let [result ((. parsers 1) input)]
        (if (= result.status paco.status.error)
          (paco.gen-failure result.result input.remaining input.line input.col)
          (paco.gen-success result.result result.remaining result.line result.col))))))

(fn paco.p-map [f parser]
  "Apply function to result of parser"
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.ok)
        (paco.gen-success (f result.result) result.remaining result.line result.col)
        result))))

(fn paco.p-any [chars]
  "Match any of the passed characters"
  (var parsers [])
  (each [i char (ipairs chars)] 
    (table.insert parsers (paco.p-char char)))
  (paco.p-choose parsers))

(fn paco.p-zero-or-more [parser]
  "Match parser zero or an arbitrary number of times"
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        (paco.gen-success "" input.remaining input.line input.col)
        (let [more ((paco.p-zero-or-more parser) result)]
          (paco.gen-success (paco.combine-results result more) more.remaining more.line more.col))))))

(fn paco.p-many [parser]
  "Match parser zero or an arbitrary number of times (alias)"
  (fn [input]
    ((paco.p-zero-or-more parser) input)))

(fn paco.p-many1 [parser]
  "Match parser one or more times"
  (fn [input]
    (local first-result (parser input))
    (if (= first-result.status paco.status.error)
      first-result
      (let [more ((paco.p-zero-or-more parser) first-result)]
        (paco.gen-success (paco.combine-results first-result more) more.remaining more.line more.col)))))

(fn paco.p-option [parser]
  "Match parser zero or one time"
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        (paco.gen-success "" input.remaining input.line input.col)
        result))))

(fn paco.p-discard [parser]
  "Match parser one time but discard the result"
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        result
        (paco.gen-success [] result.remaining result.line result.col)))))

(fn paco.parse [parser input]
  "Apply parser"
  (parser (paco.gen-success "" input 0 0)))


(local p-A (paco.p-char "A"))
(local p-B (paco.p-char "B"))
(local p-C (paco.p-char "C"))
(local p-D (paco.p-char "D"))
(local p-AB (paco.p-and p-A p-B))
(local p-CD (paco.p-and p-C p-D))
(local p-A-or-B (paco.p-or p-AB p-CD))
(local p-ABCD (paco.p-chain [p-A p-B p-C p-D]))
(local p-A-or-B-or-C (paco.p-choose [p-A p-B p-C]))
(local p-digit (paco.p-any ["0" "1" "2" "3" "4" "5" "6" "7" "8" "9"]))
(local p-whitespace (paco.p-map (fn [s] "") (paco.p-many (paco.p-any [" " "\t" "\n"]))))
(local p-number
  (paco.p-chain
    [p-whitespace
     (paco.p-map
       (fn [digits]
         (local num-as-str (accumulate [result "" i current (ipairs digits)] (.. result current)))
         (tonumber num-as-str))
       (paco.p-and (paco.p-option (paco.p-char "-")) (paco.p-many1 p-digit)))]))

(local p-quoted-number
  (paco.p-chain
    [(paco.p-discard (paco.p-char "\'"))
     p-number
     (paco.p-discard (paco.p-char "'"))]))

; (up.pp (paco.parse p-whitespace "   \n1ojnsen"))
; (up.pp (paco.parse p-whitespace " 1ojnsen"))
; (up.pp (paco.parse p-number "   69ojnsen"))
; (up.pp (paco.parse p-number "   -69ojnsen"))
; (up.pp (paco.parse p-number "5"))
; (up.pp (paco.parse p-quoted-number "'5'"))
; (up.pp (paco.parse (paco.p-str "moin") "mojnsen"))
; (up.pp (paco.parse (paco.p-and p-whitespace p-digit) "   1ojnsen"))
; (up.pp (paco.parse (paco.p-zero-or-more (paco.p-str "moin")) "moinmoinsen"))

paco
