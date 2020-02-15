port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Encode as Encode
import RTTL


port sendRingtone : Encode.Value -> Cmd msg


type alias Model =
    { userInput : String
    , alertMessage : String
    }


type Msg
    = UserInput String
    | Play


initialModel : Model
initialModel =
    { userInput = "32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4f1 8- 32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4#d2 8- 32c2 32- 32#d2 4f2 16#g2 32- 16g2 32- 32f2 32- 4#d2 8- 32c2 32f2 32c2 32f2 4c2 8#a1 4f1"
    , alertMessage = ""
    }


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "container" ]
        [ Html.h1 [] [ Html.text "NOKIA" ]
        , Html.textarea
            [ Attr.id "nokia-composer"
            , Attr.value model.userInput
            , Events.onInput UserInput
            ]
            []
        , Html.button [ Events.onClick Play ] [ Html.text "Play" ]
        , Html.text model.alertMessage
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserInput newInput ->
            ( { model | userInput = newInput }, Cmd.none )

        Play ->
            case RTTL.parseComposer { tempo = 64 } model.userInput of
                Ok value ->
                    ( { model | alertMessage = Debug.toString value }
                    , sendRingtone (RTTL.encode value)
                    )

                Err _ ->
                    ( { model | alertMessage = "Could not parse ringtone, sorry!" }, Cmd.none )
