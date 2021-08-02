module HTML where

import Halogen.HTML as HH
import Halogen.HTML.Events as HE

-- Adapted from:
-- https://github.com/purescript-halogen/purescript-halogen/blob/master/examples/higher-order-components/src/Harness.purs
render state =
  HH.div_
    [ HH.div_ [ HH.button
        [ HE.onClick \_ -> CheckButtonState ]
        [ HH.text "Check button state" ]
        , HH.p_
            [

            HH.text ("Last result: " <> printButtonState state.buttonCheckState)]
        ]
    , HH.div_
        [ HH.p_
            [ HH.text ("Last message from the button: " <> printButtonState state.buttonMessageState
            )
            ]
              ]
    ]
