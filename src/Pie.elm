module Pie exposing (circ, generate)

import Svg exposing (..)
import Svg.Attributes exposing (..)


circ colour position =
    circle [ cx "16", cy "16", r "16", stroke colour, strokeDasharray (String.fromInt position ++ " 100") ]


generate colours total data =
    svg
        [ viewBox "0 0 32 32"
        , width
            (if List.length data > 0 then
                "35vw"

             else
                ""
            )
        ]
        (List.indexedMap (\i l -> circ (colours i) (100 * l.running // total) []) (List.reverse data))
