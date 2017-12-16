module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (..)
import Html.Events exposing (onClick, onInput)
import Pie exposing (generate)


main =
    program
        { init = init "paulhoughton"
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias LangCount =
    { lang : String, count : Int }


type alias LangList =
    List LangCount


type alias Model =
    { username : String
    , data : LangList
    }


init : String -> ( Model, Cmd Msg )
init username =
    ( Model username []
    , getLanguages username
    )


type Msg
    = Username String
    | Go
    | DataResult (Result Http.Error LangList)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username name ->
            ( { model | username = name }, Cmd.none )

        Go ->
            ( model, getLanguages model.username )

        DataResult (Ok data) ->
            ( { model | data = data }, Cmd.none )

        DataResult (Err _) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        colours i =
            "hsl(200, 100%, " ++ toString ((i * 100) // List.length (model.data) + 1) ++ "%)"

        total =
            List.foldr (\a b -> a.count + b) 0 model.data

        data =
            List.scanl (\a b -> { lang = a.lang, count = a.count, running = a.count + b.running }) { lang = "", count = 0, running = 0 } model.data
    in
        div []
            [ header []
                [ input [ type_ "text", placeholder "Username", onInput Username, Html.Attributes.value model.username ] []
                , button [ onClick Go ] [ text "Go" ]
                ]
            , Html.main_ []
                [ div []
                    [ ul [] (List.indexedMap (\i l -> li [ style [ ( "color", colours (i) ) ] ] [ text (l.lang ++ " " ++ toString (100 * l.count // total) ++ "%") ]) (List.reverse model.data))
                    ]
                , div []
                    [ generate colours total data
                    ]
                ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


getLanguages : String -> Cmd Msg
getLanguages username =
    let
        url =
            "/languages/" ++ username

        request =
            Http.get url (decodeList)
    in
        Http.send DataResult request


decodeList : Decoder LangList
decodeList =
    Json.Decode.list decodeData


decodeData : Decoder LangCount
decodeData =
    map2 LangCount
        (field "language" Json.Decode.string)
        (field "count" int)
