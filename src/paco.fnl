(local up (require :uglyprint))

; Simple parser combinator

(fn is-empty [s]
  (or (= s nil) (= s "")))

(fn reduce [reduce-func parsers]
  (var val (reduce-func (. parsers 1) (. parsers 2)))
  (each [i parser (ipairs parsers)]
    (when (> i 2)
      (set val (reduce-func val parser))))
  val)

(fn flatten [input flattened]
  (set-forcibly! flattened (or flattened {}))
  (each [i element (ipairs input)]
    (if (and (= (type element) :table))
        (flatten element flattened)
        (when (not= element "")
          (table.insert flattened element))))
  flattened)




(var paco {})

(set paco.status {:ok 1 :error 0})

(fn paco.gen-success [result remaining line col]
  {:status paco.status.ok
   :result result
   :remaining remaining
   :line line
   :col col})
(fn paco.gen-failure [message remaining line col]
  {:status paco.status.error
   :result message
   :remaining remaining
   :line line
   :col col})
   

(fn paco.p-char [char-to-match]
  (fn [input]
    (if (is-empty input.remaining)
      (paco.gen-failure "No more input" input.line input.col)
      (let [first (input.remaining:sub 1 1)]
        (if (= first char-to-match)
          (let [line (if (= first "\n") (+ input.line 1) input.line)
                col (+ input.col 1)]
            (paco.gen-success char-to-match (input.remaining:sub 2) line col))
          (paco.gen-failure (.. "Expecting '" char-to-match "', got '" first "'.") input.remaining input.line input.col))))))

(fn paco.p-str [string-to-match]
  (var parsers [])
  (each [c (string-to-match:gmatch ".")]
    (table.insert parsers (paco.p-char c)))
  (paco.p-map 
    (fn [s] 
      (accumulate [result "" i current (ipairs s)] (.. result current)))
    (paco.p-chain parsers)))


(fn paco.p-and [parser-1 parser-2]
  (fn [input]
    (let [result-1 (parser-1 input)]
      (if (= result-1.status paco.status.error)
        result-1
        (let [result-2 (parser-2 result-1)]
          (if (= result-2.status paco.status.error)
            result-2
            (paco.gen-success (flatten [ result-1.result result-2.result ]) result-2.remaining result-2.line result-2.col)))))))

(fn paco.p-or [parser-1 parser-2]
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
  (reduce paco.p-and parsers))

(fn paco.p-chooose [parsers]
  (reduce paco.p-or parsers))

(fn paco.parse [parser input]
  (parser (paco.gen-success "" input 0 0)))

(fn paco.p-map [f parser]
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.ok)
        (paco.gen-success (f result.result) result.remaining result.line result.col)
        result))))

(fn paco.p-any [chars]
  (var parsers [])
  (each [i char (ipairs chars)] 
    (table.insert parsers (paco.p-char char)))
  (paco.p-chooose parsers))

(fn paco.p-return [x]
  (fn [input]
    (paco.gen-success x input.remaining input.line input.col)))

(fn paco.p-zero-or-more [parser]
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        (paco.gen-success "" input.remaining input.line input.col)
        (let [more ((paco.p-zero-or-more parser) result)]
          (paco.gen-success (flatten [ result.result more.result ]) more.remaining more.line more.col))))))

(fn paco.p-many [parser]
  (fn [input]
    ((paco.p-zero-or-more parser) input)))

(fn paco.p-many1 [parser]
  (fn [input]
    (local first-result (parser input))
    (if (= first-result.status paco.status.error)
      first-result
      (let [more ((paco.p-zero-or-more parser) first-result)]
        (paco.gen-success (flatten [ first-result.result more.result ]) more.remaining more.line more.col)))))

(fn paco.p-option [parser]
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        (paco.gen-success "" input.remaining input.line input.col)
        result))))

(fn paco.p-discard [parser]
  (fn [input]
    (let [result (parser input)]
      (if (= result.status paco.status.error)
        result
        (paco.gen-success "" result.remaining result.line result.col)))))



(local p-A (paco.p-char "A"))
(local p-B (paco.p-char "B"))
(local p-C (paco.p-char "C"))
(local p-D (paco.p-char "D"))
(local p-AB (paco.p-and p-A p-B))
(local p-CD (paco.p-and p-C p-D))
(local p-A-or-B (paco.p-or p-AB p-CD))
(local p-ABCD (paco.p-chain [p-A p-B p-C p-D]))
(local p-A-or-B-or-C (paco.p-chooose [p-A p-B p-C]))
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
