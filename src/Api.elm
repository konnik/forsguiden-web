module Api exposing (Fors, Lan, Resurs(..), Vattendrag, hamtaForsar, hamtaLan, hamtaVattendrag, nyttVattendrag, raderaVattendrag, uppdateraVattendrag)

import Api.Common exposing (..)
import Auth exposing (Session)
import Http
import Json.Decode as D
import Json.Encode as E
import Maybe


type Resurs a
    = Resurs Int a


type alias Fors =
    { namn : String
    , langd : Int
    , fallhojd : Int
    , gradering :
        { klass : Grad
        , lyft : List Grad
        }
    }


type Grad
    = Grad1
    | Grad2
    | Grad3 GradExtra
    | Grad4 GradExtra
    | Grad5 GradExtra
    | Grad6


type GradExtra
    = Inget
    | Plus
    | Minus


type alias Vattendrag =
    { namn : String
    , beskrivning : String
    , lan : List Lan
    }


type alias Lan =
    { id : Int, namn : String }



-- forsar


hamtaForsar : (Result Http.Error (List (Resurs Fors)) -> msg) -> Cmd msg
hamtaForsar toMsg =
    Http.get
        { url = "https://forsguiden-api.herokuapp.com/forsstracka"
        , expect = Http.expectJson toMsg (D.field "forsstracka" (D.list (resurs forsDecoder)))
        }


forsDecoder : D.Decoder Fors
forsDecoder =
    D.map4 Fors
        (D.field "namn" D.string)
        (D.field "langd" D.int)
        (D.field "fallhojd" D.int)
        (D.field "gradering" graderingDecoder)


graderingDecoder : D.Decoder { klass : Grad, lyft : List Grad }
graderingDecoder =
    D.map2
        (\klass lyft ->
            { klass = klass
            , lyft = lyft
            }
        )
        (D.field "klass" gradDecoder)
        (D.field "lyft" (D.list gradDecoder))


gradDecoder : D.Decoder Grad
gradDecoder =
    D.string
        |> D.andThen
            (\gradStr ->
                case parseGrad gradStr of
                    Just grad ->
                        D.succeed grad

                    Nothing ->
                        D.fail <| "Ogiltig grad: '" ++ gradStr ++ "'"
            )


parseGrad : String -> Maybe Grad
parseGrad grad =
    case grad of
        "1" ->
            Just Grad1

        "2" ->
            Just Grad2

        "3-" ->
            Just <| Grad3 Minus

        "3" ->
            Just <| Grad3 Inget

        "3+" ->
            Just <| Grad3 Plus

        "4-" ->
            Just <| Grad4 Minus

        "4" ->
            Just <| Grad4 Inget

        "4+" ->
            Just <| Grad4 Plus

        "5-" ->
            Just <| Grad5 Minus

        "5" ->
            Just <| Grad5 Inget

        "5+" ->
            Just <| Grad5 Plus

        "6" ->
            Just <| Grad6

        _ ->
            Nothing



-- vattendrag


hamtaVattendrag : (Result Http.Error (List (Resurs Vattendrag)) -> msg) -> Cmd msg
hamtaVattendrag toMsg =
    Http.get
        { url = "https://forsguiden-api.herokuapp.com/vattendrag"
        , expect = Http.expectJson toMsg (D.field "vattendrag" (D.list (resurs vattendragDecoder)))
        }


raderaVattendrag : Session -> Int -> (Result Http.Error () -> msg) -> Cmd msg
raderaVattendrag session id toMsg =
    delete session
        { url = "https://forsguiden-api.herokuapp.com/vattendrag/" ++ String.fromInt id
        , expect = Http.expectWhatever toMsg
        }


nyttVattendrag : Session -> Vattendrag -> (Result Http.Error (Resurs Vattendrag) -> msg) -> Cmd msg
nyttVattendrag session vattendrag toMsg =
    let
        lanJson : E.Value
        lanJson =
            vattendrag.lan
                |> E.list
                    (\x ->
                        E.object
                            [ ( "id", E.int x.id )
                            , ( "namn", E.string x.namn )
                            ]
                    )

        body =
            E.object <|
                [ ( "id", E.int -1 )
                , ( "namn", E.string vattendrag.namn )
                , ( "beskrivning", E.string vattendrag.beskrivning )
                , ( "lan", lanJson )
                ]
    in
    post session
        { url = "https://forsguiden-api.herokuapp.com/vattendrag"
        , expect = Http.expectJson toMsg (resurs vattendragDecoder)
        , body = Http.jsonBody body
        }


uppdateraVattendrag :
    Session
    -> Resurs Vattendrag
    -> (Result Http.Error (Resurs Vattendrag) -> msg)
    -> Cmd msg
uppdateraVattendrag session (Resurs id vattendrag) toMsg =
    let
        lanJson : E.Value
        lanJson =
            vattendrag.lan
                |> E.list
                    (\x ->
                        E.object
                            [ ( "id", E.int x.id )
                            , ( "namn", E.string x.namn )
                            ]
                    )

        body =
            E.object <|
                [ ( "id", E.int id )
                , ( "namn", E.string vattendrag.namn )
                , ( "beskrivning", E.string vattendrag.beskrivning )
                , ( "lan", lanJson )
                ]
    in
    put session
        { url = "https://forsguiden-api.herokuapp.com/vattendrag/" ++ String.fromInt id
        , expect = Http.expectJson toMsg (resurs vattendragDecoder)
        , body = Http.jsonBody body
        }


resurs : D.Decoder a -> D.Decoder (Resurs a)
resurs decoder =
    D.map2 Resurs
        (D.field "id" D.int)
        decoder


vattendragDecoder : D.Decoder Vattendrag
vattendragDecoder =
    D.map3 Vattendrag
        (D.field "namn" D.string)
        (D.field "beskrivning" D.string)
        (D.field "lan" (D.list lanDecoder))



-- län


hamtaLan : (Result Http.Error (List Lan) -> msg) -> Cmd msg
hamtaLan toMsg =
    Http.get
        { url = "https://forsguiden-api.herokuapp.com/lan"
        , expect = Http.expectJson toMsg (D.field "lan" (D.list lanDecoder))
        }


lanDecoder : D.Decoder Lan
lanDecoder =
    D.map2 Lan
        (D.field "id" D.int)
        (D.field "namn" D.string)
