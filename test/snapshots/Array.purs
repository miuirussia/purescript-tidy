module Array where

records :: Array { foo :: Int, bar :: String }
records = [ { foo: 10, bar: "Hello" }
          ,
                           { foo:
                                  10
                           , bar: "Hello world"},
          {            foo: 10
                       , bar: "Goodbye"
          }
]

ints :: Array Int
ints = [ 10, 9, 8, 7, 6, 5 ]

bools :: Array Boolean
bools =
  [ (a && b || c)
  , (a &&
      (b || (
            c && d)))
      , (a && (
              c && d))]

strings :: Array String
strings
  = ["hello", "world",
     "strings"
             , "go",
                      """
                        Multiline string
                      """
    ]

nested :: Array (Array Int)
nested =
  [ [ [], [], [ 1, 2, 3 ]],
      [ [ 1, 2
        , 3,
          4 ]]
  ,
      [ [ 1],
        [1]
        ,                     [ 1
                              , 2,
                                                3, 4
                                                    , 5]]
  ]
