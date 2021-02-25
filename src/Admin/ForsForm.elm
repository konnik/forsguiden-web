module Admin.ForsForm exposing (Model, Msg, init, nytt, redigera, update, view)

import Api exposing (Fors, Resurs(..), Vattendrag)
import Auth exposing (Session)
import Element exposing (Attribute, Element, alignRight, centerX, centerY, column, el, fill, height, maximum, minimum, padding, paddingEach, px, rgb255, row, shrink, spacing, text, width)
import Element.Background as Bg
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Http
import Process
import Task


type alias Model =
    { id : Maybe Int
    , form : Form
    , status : Status
    , meddelande : Maybe Meddelande
    }


type Status
    = Inmatning
    | Sparar
    | BekraftaRadera
    | Raderar
    | Raderad


type alias Meddelande =
    { typ : MeddelandeTyp
    , text : String
    }


type MeddelandeTyp
    = Info
    | Fel


type alias Form =
    { namn : String
    , langd : String
    , fallhojd : String
    , klass : String
    , lyft : String
    , koordinater : String
    , smhipunkt : String
    , minimum : String
    , optimal : String
    , maximum : String
    , lan : String
    , vattendrag : String
    }


type Msg
    = InputNamn String
    | InputLangd String
    | InputFallhojd String
    | InputKlass String
    | InputLyft String
    | InputKoordinater String
    | InputSmhipunkt String
    | InputMinimum String
    | InputOptimal String
    | InputMaximum String
    | InputVattendrag String
    | InputLan String
    | Spara
    | SparaResult (Result Http.Error (Resurs Fors))
    | Radera
    | RaderaBekraftad
    | RaderaAvbruten
    | RaderaResult (Result Http.Error ())
    | UppdateraModel Model


init : Session -> ( Model, Cmd Msg )
init =
    nytt


emptyForm : Form
emptyForm =
    { namn = ""
    , langd = ""
    , klass = ""
    , lyft = ""
    , fallhojd = ""
    , koordinater = ""
    , smhipunkt = ""
    , minimum = ""
    , optimal = ""
    , maximum = ""
    , lan = ""
    , vattendrag = ""
    }


nytt : Session -> ( Model, Cmd Msg )
nytt session =
    ( { id = Nothing
      , form = emptyForm
      , status = Inmatning
      , meddelande = Nothing
      }
    , Cmd.none
    )


redigera : Session -> Resurs Fors -> ( Model, Cmd Msg )
redigera session (Resurs id fors) =
    ( { id = Just id
      , form =
            { emptyForm
                | namn = fors.namn
                , langd = fors.langd |> String.fromInt
                , fallhojd = fors.fallhojd |> String.fromInt
                , klass = Api.gradToString fors.gradering.klass
                , lyft = fors.gradering.lyft |> List.map Api.gradToString |> String.join ", "
                , koordinater = [ fors.koordinater.lat, fors.koordinater.long ] |> List.map String.fromFloat |> String.join ", "
                , smhipunkt = fors.flode.smhipunkt |> String.fromInt
                , maximum = fors.flode.maximum |> String.fromInt
                , minimum = fors.flode.minimum |> String.fromInt
                , optimal = fors.flode.optimal |> String.fromInt
                , vattendrag = fors.vattendrag |> List.map (.id >> String.fromInt) |> String.join ", "
                , lan = fors.lan |> List.map (.id >> String.fromInt) |> String.join ", "
            }
      , status = Inmatning
      , meddelande = Nothing
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        Radera ->
            ( { model | status = BekraftaRadera }, Cmd.none )

        RaderaBekraftad ->
            case model.id of
                Just id ->
                    ( { model | status = Raderar }, Api.raderaFors session id RaderaResult )

                _ ->
                    ( model, Cmd.none )

        RaderaAvbruten ->
            ( { model | status = Inmatning }, Cmd.none )

        RaderaResult (Ok ()) ->
            ( model, fordrojUppdatering 1000 { model | id = Nothing, status = Raderad, meddelande = Just <| info "Forsen har raderats." } )

        RaderaResult (Err err) ->
            ( model, fordrojUppdatering 1000 { model | status = Inmatning, meddelande = Just <| fel "Det gick inte att radera forsen." } )

        Spara ->
            case validera model.form of
                Ok fors ->
                    ( { model | status = Sparar, meddelande = Nothing }
                    , case model.id of
                        Nothing ->
                            Api.nyFors session fors SparaResult

                        Just id ->
                            Api.uppdateraFors session (Resurs id fors) SparaResult
                    )

                Err valideringsFel ->
                    ( { model | status = Inmatning, meddelande = Just <| fel valideringsFel }, Cmd.none )

        SparaResult (Ok (Resurs id fors)) ->
            ( model, fordrojUppdatering 1000 { model | id = Just id, status = Inmatning, meddelande = Just <| info "Forsen har sparats." } )

        SparaResult (Err err) ->
            ( model, fordrojUppdatering 1000 { model | status = Inmatning, meddelande = Just <| fel "Det gick inte att spara forsen." } )

        -- form input
        InputNamn str ->
            model |> updateForm (\f -> { f | namn = str })

        InputLangd str ->
            model |> updateForm (\f -> { f | langd = str })

        InputFallhojd str ->
            model |> updateForm (\f -> { f | fallhojd = str })

        InputKlass str ->
            model |> updateForm (\f -> { f | klass = str })

        InputLyft str ->
            model |> updateForm (\f -> { f | lyft = str })

        InputKoordinater str ->
            model |> updateForm (\f -> { f | koordinater = str })

        InputSmhipunkt str ->
            model |> updateForm (\f -> { f | smhipunkt = str })

        InputMinimum str ->
            model |> updateForm (\f -> { f | minimum = str })

        InputMaximum str ->
            model |> updateForm (\f -> { f | maximum = str })

        InputOptimal str ->
            model |> updateForm (\f -> { f | optimal = str })

        InputVattendrag str ->
            model |> updateForm (\f -> { f | vattendrag = str })

        InputLan str ->
            model |> updateForm (\f -> { f | lan = str })

        UppdateraModel newModel ->
            ( newModel, Cmd.none )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd msg )
updateForm updateFunc model =
    ( { model | form = updateFunc model.form }, Cmd.none )


fordrojUppdatering : Float -> Model -> Cmd Msg
fordrojUppdatering millis model =
    let
        task =
            Process.sleep millis
                |> Task.map (\_ -> model)
    in
    Task.perform UppdateraModel task


info : String -> Meddelande
info text =
    { text = text, typ = Info }


fel : String -> Meddelande
fel text =
    { text = text, typ = Fel }


validera : Form -> Result String Fors
validera form =
    Err "not implemented"


view : Model -> Element Msg
view model =
    column [ spacing 20, centerX, centerY, width (fill |> maximum 600) ]
        [ if model.status /= Raderad then
            redigeraView model

          else
            el [ Font.color (rgb255 0 100 0) ] <| text "Forsen har raderats."
        ]


redigeraView : Model -> Element Msg
redigeraView model =
    let
        omId : Element Msg -> Element Msg
        omId elem =
            if model.id /= Nothing then
                elem

            else
                Element.none
    in
    column [ spacing 20, width fill ]
        [ rubrikView model.id
        , formView model.form
        , row [ spacing 20, width fill ]
            [ viewRadera model.status |> omId
            , knappSpara model.status
            ]
        , model.meddelande |> Maybe.map meddelandeView |> Maybe.withDefault Element.none
        ]


meddelandeView : Meddelande -> Element msg
meddelandeView meddelande =
    let
        msgBox : List (Attribute msg) -> String -> Element msg
        msgBox attrs msg =
            el (attrs ++ [ alignRight ]) <| text msg
    in
    case meddelande.typ of
        Info ->
            msgBox [ Font.color (rgb255 0 100 0) ] meddelande.text

        Fel ->
            msgBox [ Font.color (rgb255 200 0 0) ] meddelande.text


rubrikView : Maybe Int -> Element Msg
rubrikView maybeId =
    let
        rubrik =
            "Fors " ++ (maybeId |> Maybe.map (\id -> " (" ++ String.fromInt id ++ ")") |> Maybe.withDefault "( nytt )")
    in
    el [ Font.size 30 ] (text rubrik)


formView : Form -> Element Msg
formView form =
    column [ spacing 20, width fill ]
        [ input "Namn" form.namn InputNamn
        , row [ spacing 20 ]
            [ input "Längd" form.langd InputLangd
            , input "Fallhöjd" form.fallhojd InputFallhojd
            ]
        , row [ spacing 20 ]
            [ input "Klass" form.klass InputKlass
            , input "Lyft" form.lyft InputLyft
            ]
        , input "Smhipunkt" form.smhipunkt InputSmhipunkt
        , row [ spacing 20 ]
            [ input "Min" form.minimum InputMinimum
            , input "Max" form.maximum InputMaximum
            , input "Optimal" form.optimal InputOptimal
            ]
        , input "Vattendrag" form.vattendrag InputVattendrag
        , input "Län" form.lan InputLan
        ]


viewRadera : Status -> Element Msg
viewRadera status =
    case status of
        BekraftaRadera ->
            row [ spacing 20, alignRight ]
                [ knapp { label = "Bekräfta radera", state = Aktiv } RaderaBekraftad
                , knapp { label = "Avbryt", state = Aktiv } RaderaAvbruten
                ]

        Raderar ->
            row [ spacing 20, alignRight ]
                [ knapp { label = "Raderar...", state = Spinning } RaderaAvbruten
                , knapp { label = "Avbryt", state = Inaktiverad } RaderaAvbruten
                ]

        Inmatning ->
            el [ alignRight ] <| knapp { label = "Radera", state = Aktiv } Radera

        _ ->
            el [ alignRight ] <| knapp { label = "Radera", state = Inaktiverad } Radera


knappSpara : Status -> Element Msg
knappSpara status =
    case status of
        Inmatning ->
            knapp { label = "Spara", state = Aktiv } Spara

        Sparar ->
            knapp { label = "Sparar...", state = Spinning } Spara

        _ ->
            knapp { label = "Spara", state = Inaktiverad } Spara


input : String -> String -> (String -> msg) -> Element msg
input label value toMsg =
    Input.text [ width fill ]
        { label = Input.labelAbove [] (text label)
        , placeholder = Nothing
        , onChange = toMsg
        , text = value
        }


textbox : String -> String -> (String -> msg) -> Element msg
textbox label value toMsg =
    Input.multiline [ width fill ]
        { onChange = toMsg
        , text = value
        , placeholder = Nothing
        , label = Input.labelAbove [] (text label)
        , spellcheck = False
        }


type KnappState
    = Aktiv
    | Inaktiverad
    | Spinning


knapp : { label : String, state : KnappState } -> msg -> Element msg
knapp { label, state } toMsg =
    Input.button
        [ Font.center
        , Border.width 1
        , paddingEach { left = 10, right = 10, top = 0, bottom = 0 }
        , alignRight
        , width (shrink |> minimum 100)
        , height (px 40)
        ]
        { onPress =
            if state == Aktiv then
                Just toMsg

            else
                Nothing
        , label =
            case state of
                Spinning ->
                    Element.image [ centerX, centerY, width (px 30) ] { src = "/spinner.svg", description = label }

                Aktiv ->
                    el [ centerX, centerY ] <| text label

                Inaktiverad ->
                    el [ centerX, centerY, Font.color (rgb255 200 200 200) ] <| text label
        }