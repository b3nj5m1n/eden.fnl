
(local t (require :fspec))

(local p (require :paco))

; is-empty
(t.eq (p.is-empty "") true)
(t.eq (p.is-empty nil) true)
(t.eq (p.is-empty "    ") false)
(t.eq (p.is-empty "\n") false)
(t.eq (p.is-empty "\t") false)
(t.eq (p.is-empty " \n  \t") false)
(t.eq (p.is-empty "test") false)
(t.eq (p.is-empty "🧁") false)

; reduce
(t.eq (p.reduce (fn [a b] (+ a b)) [1 2 3]) 6)
(t.eq (p.reduce (fn [a b] (.. a b)) ["a" "b" "c" "d" "e" "f" "g"]) "abcdefg")

; flatten
(t.eq (p.flatten [[[1 2] 3] 4]) [1 2 3 4])
(t.eq (p.flatten [1 [2 [3] 4] 5]) [1 2 3 4 5])
(t.eq (p.flatten [1 2 3]) [1 2 3])

; gen-success
(t.eq (p.gen-success "" "test" 15 2) { :status p.status.ok :result "" :remaining "test" :line 15 :col 2})
(t.eq (p.gen-success [1 2 3] "test" 15 2) { :status p.status.ok :result [1 2 3] :remaining "test" :line 15 :col 2})
; gen-failure
(t.eq (p.gen-failure "" "test" 15 2) { :status p.status.error :result "" :remaining "test" :line 15 :col 2})
(t.eq (p.gen-failure [1 2 3] "test" 15 2) { :status p.status.error :result [1 2 3] :remaining "test" :line 15 :col 2})

; p-char
(t.eq (p.parse (p.p-char "a") "abc") (p.gen-success "a" "bc" 0 1))
(t.eq (p.parse (p.p-char "A") "abc") (p.gen-failure "Expecting 'A', got 'a'." "abc" 0 0))
(t.eq (p.parse (p.p-char "🐨") "🐨test") (p.gen-failure "Expecting '🐨', got '\240'." "🐨test" 0 0)) ; No unicode support

; p-str
(t.eq (p.parse (p.p-str "abc") "abcdef") (p.gen-success "abc" "def" 0 3))
(t.eq (p.parse (p.p-str "🐶") "🐶abcdef") (p.gen-success "🐶" "abcdef" 0 4))
(t.eq (p.parse (p.p-str "aBc") "abcdef") (p.gen-failure "Expecting 'B', got 'b'." "abcdef" 0 0))

; p-and
(t.eq (p.parse (p.p-and (p.p-char "a") (p.p-char "b")) "abcdef") (p.gen-success ["a" "b"] "cdef" 0 2))
(t.eq (p.parse (p.p-and (p.p-char "a") (p.p-char "b")) "bcdef") (p.gen-failure "Expecting 'a', got 'b'." "bcdef" 0 0))
(t.eq (p.parse (p.p-and (p.p-char "a") (p.p-char "b")) "acdef") (p.gen-failure "Expecting 'b', got 'c'." "acdef" 0 0))

; p-or
(t.eq (p.parse (p.p-or (p.p-char "a") (p.p-char "b")) "abcdef") (p.gen-success "a" "bcdef" 0 1))
(t.eq (p.parse (p.p-or (p.p-char "a") (p.p-char "b")) "bcdef") (p.gen-success "b" "cdef" 0 1))
(t.eq (p.parse (p.p-or (p.p-char "a") (p.p-char "b")) "cdef") (p.gen-failure "Either: Expecting 'a', got 'c'., or Expecting 'b', got 'c'." "cdef" 0 0))

; p-chain
(t.eq (p.parse (p.p-chain [(p.p-char "a") (p.p-char "b") (p.p-char "c")]) "abcdef") (p.gen-success ["a" "b" "c"] "def" 0 3))

; p-choose
(t.eq (p.parse (p.p-choose [(p.p-char "a") (p.p-char "b") (p.p-char "c")]) "abcdef") (p.gen-success "a" "bcdef" 0 1))
(t.eq (p.parse (p.p-choose [(p.p-char "a") (p.p-char "b") (p.p-char "c")]) "bcdef") (p.gen-success "b" "cdef" 0 1))
(t.eq (p.parse (p.p-choose [(p.p-char "a") (p.p-char "b") (p.p-char "c")]) "cdef") (p.gen-success "c" "def" 0 1))

; p-map
(t.eq (p.parse (p.p-map
                 (fn [chars]
                   (icollect [i char (ipairs chars)]
                     (.. char "-")))
                 (p.p-chain [(p.p-char "a") (p.p-char "b") (p.p-char "c")])) "abcdef")
      (p.gen-success ["a-" "b-" "c-"] "def" 0 3))

; p-any
(t.eq (p.parse (p.p-any ["a" "b" "c"]) "abcdef") (p.gen-success "a" "bcdef" 0 1))

; p-zero-or-more
(t.eq (p.parse (p.p-zero-or-more (p.p-char "a")) "abcdef") (p.gen-success [ "a" "" ] "bcdef" 0 1))
(t.eq (p.parse (p.p-zero-or-more (p.p-char "a")) "aaaaabcdef") (p.gen-success [ "a" "a" "a" "a" "a" "" ] "bcdef" 0 5))
(t.eq (p.parse (p.p-zero-or-more (p.p-char "a")) "bcdef") (p.gen-success "" "bcdef" 0 0))

; p-many
(t.eq (p.parse (p.p-many (p.p-char "a")) "abcdef") (p.parse (p.p-zero-or-more (p.p-char "a")) "abcdef"))
(t.eq (p.parse (p.p-many (p.p-char "a")) "aaaaabcdef") (p.parse (p.p-zero-or-more (p.p-char "a")) "aaaaabcdef"))
(t.eq (p.parse (p.p-many (p.p-char "a")) "bcdef") (p.parse (p.p-zero-or-more (p.p-char "a")) "bcdef"))

; p-many1
(t.eq (p.parse (p.p-many1 (p.p-char "a")) "abcdef") (p.gen-success [ "a" "" ] "bcdef" 0 1))
(t.eq (p.parse (p.p-many1 (p.p-char "a")) "aaaaabcdef") (p.gen-success [ "a" "a" "a" "a" "a" "" ] "bcdef" 0 5))
(t.eq (p.parse (p.p-many1 (p.p-char "a")) "bcdef") (p.gen-failure "Expecting 'a', got 'b'." "bcdef" 0 0))

; p-option
(t.eq (p.parse (p.p-option (p.p-char "a")) "abcdef") (p.gen-success "a" "bcdef" 0 1))
(t.eq (p.parse (p.p-option (p.p-char "a")) "bcdef") (p.gen-success "" "bcdef" 0 0))

; p-option
(t.eq (p.parse (p.p-discard (p.p-char "a")) "abcdef") (p.gen-success "" "bcdef" 0 1))
