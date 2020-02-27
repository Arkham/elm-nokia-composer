port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Encode as Encode
import RTTL


port play : Encode.Value -> Cmd msg


port stop : () -> Cmd msg


port finished : (String -> msg) -> Sub msg


type alias Model =
    { userInput : String
    , status : Status
    , bpm : Int
    , alertMessage : String
    }


type Msg
    = SetInput String
    | ChangeBPM Int
    | SetRingtone Ringtone
    | Play
    | Stop


type Status
    = Playing
    | Idle


type alias Ringtone =
    { name : String
    , value : String
    , tempo : Int
    }


theGoodTheBad : Ringtone
theGoodTheBad =
    { name = "The Good, the Bad..."
    , value = "32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4f1 8- 32c2 32f2 32c2 32f2 4c2 8#g1 8#a1 4#d2 8- 32c2 32- 32#d2 4f2 16#g2 32- 16g2 32- 32f2 32- 4#d2 8- 32c2 32f2 32c2 32f2 4c2 8#a1 4f1 8-"
    , tempo = 63
    }


barbieGirl : Ringtone
barbieGirl =
    { name = "Barbie Girl"
    , value = "8#g2 8e2 8#g2 8#c3 4a2 4- 8#f2 8#d2 8#f2 8b2 4#g2 8#f2 8e2 4- 8e2 8#c2 4#f2 4#c2 4- 8#f2 8e2 4#g2 4#f2 4-"
    , tempo = 125
    }


theSimpsons : Ringtone
theSimpsons =
    { name = "The Simpsons"
    , value = "4c2 4e2 4#f2 8a2 4.g2 4e2 4c2 8a1 8#f1 8#f1 8#f1 2g1 4- 8#f1 8#f1 8#f1 8g1 4#a1 8c2 8c2 8c2 4c2 4-"
    , tempo = 160
    }


neverGonna : Ringtone
neverGonna =
    { name = "Big Surprise"
    , value = "8g1 8a1 8c2 8a1 4e2 8- 4e2 8- 4.d2 4- 8- 8g1 8a1 8c2 8a1 4d2 8- 4d2 8- 4c2 8b1 4.a1 8g1 8a1 8c2 8a1 2c2 4d2 4b1 8a1 4.g1 8- 4g1 2d2 2.c2 4-"
    , tempo = 200
    }


classic : Ringtone
classic =
    { name = "Grande Valse"
    , value = "16g2 16f2 8a1 8b1 16e2 16d2 8f1 8g1 16d2 16c2 8e1 8g1 4.c2 8- 4-"
    , tempo = 125
    }


allRingtones : List Ringtone
allRingtones =
    [ theGoodTheBad, barbieGirl, theSimpsons, classic, neverGonna ]


initialModel : Model
initialModel =
    { userInput = theGoodTheBad.value
    , status = Idle
    , bpm = 63
    , alertMessage = ""
    }


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> finished (\_ -> Stop)
        }


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "container" ]
        [ Html.h1 [] [ Html.text "NOKIA" ]
        , Html.textarea
            [ Attr.id "nokia-composer"
            , Attr.value model.userInput
            , Events.onInput SetInput
            ]
            []
        , Html.div [ Attr.class "controls" ]
            [ Html.label [] [ Html.text "BPM " ]
            , Html.input
                [ Attr.type_ "range"
                , Attr.min "40"
                , Attr.max "225"
                , Attr.step "1"
                , Attr.value (String.fromInt model.bpm)
                , Events.onInput
                    (\str ->
                        case String.toInt str of
                            Nothing ->
                                ChangeBPM 10

                            Just int ->
                                ChangeBPM int
                    )
                ]
                []
            , Html.span [] [ Html.text (String.fromInt model.bpm) ]
            ]
        , Html.text model.alertMessage
        , case model.status of
            Playing ->
                Html.button
                    [ Attr.class "play"
                    , Events.onClick Stop
                    ]
                    [ Html.text "Stop" ]

            Idle ->
                Html.button
                    [ Attr.class "play"
                    , Events.onClick Play
                    ]
                    [ Html.text "Play" ]
        , Html.div [ Attr.class "ringtones" ] <|
            List.map
                (\ringtone ->
                    Html.button
                        [ Attr.class "ringtone"
                        , Events.onClick (SetRingtone ringtone)
                        ]
                        [ Html.text ringtone.name ]
                )
                allRingtones
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetInput newInput ->
            ( { model | userInput = newInput, status = Idle }, stop () )

        ChangeBPM newValue ->
            ( { model | bpm = newValue }, Cmd.none )

        SetRingtone { value, tempo } ->
            ( { model | userInput = value, bpm = tempo, status = Idle }, stop () )

        Play ->
            case RTTL.parseComposer { tempo = model.bpm } model.userInput of
                Ok value ->
                    ( { model | status = Playing }
                    , play (RTTL.encode value)
                    )

                Err _ ->
                    ( { model | alertMessage = "Could not parse ringtone, sorry!" }, Cmd.none )

        Stop ->
            case model.status of
                Playing ->
                    ( { model | status = Idle }, stop () )

                _ ->
                    ( model, Cmd.none )
