(local sn (require :supernova))

(print (sn.gradient "Running tests for uglyprint" ["#38bdf8" "#bae6fd"]))

(local t-uglyprint (require :test.uglyprint))

(print (sn.gradient "Running tests for paco" ["#38bdf8" "#bae6fd"]))

(local t-paco (require :test.paco))

(print "\n")

(print (sn.gradient "Running tests for eden" ["#38bdf8" "#bae6fd"]))

(local t-eden (require :test.eden))


