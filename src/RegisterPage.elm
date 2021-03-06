module RegisterPage exposing (..)

import Character
import Hash
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Lamdera
import Misc exposing (attrIf, none)
import Rumkin exposing (RumkinResult, Strength(..))
import Types exposing (..)


init : RegisterModel
init =
    { username = ""
    , password = ""
    , password2 = ""
    , characterPicker = False
    , character = Nothing
    , failed = False
    , blurred = False
    }


update msg model =
    case msg of
        InputUsername string ->
            ( { model | username = string, failed = False }, Cmd.none )

        InputPassword string ->
            ( { model | password = string }, Cmd.none )

        InputPassword2 string ->
            ( { model | password2 = string }, Cmd.none )

        SelectedCharacter int ->
            ( { model | character = Just int }, Cmd.none )

        Blurred ->
            ( { model | blurred = True }, Cmd.none )

        Next ->
            if model.password == model.password2 && (Rumkin.getStats model.password).strength /= VeryWeak then
                ( model, Lamdera.sendToBackend (CheckName model.username) )

            else
                ( model, Cmd.none )

        Register ->
            case
                ( model.character |> Maybe.andThen Character.create
                , String.length model.password > 6 && model.password == model.password2
                )
            of
                ( Just character, True ) ->
                    ( model
                    , Lamdera.sendToBackend
                        (CreateAccount model.username
                            (Hash.fromString model.password)
                            character.skin
                        )
                    )

                _ ->
                    ( model, Cmd.none )


view model =
    if not model.characterPicker then
        let
            stats =
                Rumkin.getStats model.password
        in
        Html.form [ class "form", onSubmit Next ]
            [ label []
                [ text "Username"
                , input [ onInput InputUsername, value model.username ] []
                ]
            , if model.failed then
                text "Username already taken"

              else
                text ""
            , label []
                [ text "Password"
                , input
                    [ onInput InputPassword
                    , value model.password
                    , type_ "password"
                    ]
                    []
                , if model.password == "" then
                    none

                  else
                    viewStrength stats
                ]
            , label []
                [ text "Repeat password"
                , input
                    [ onInput InputPassword2
                    , onBlur Blurred
                    , value model.password2
                    , type_ "password"
                    ]
                    []
                ]
            , if model.blurred && model.password2 /= model.password then
                text "The passwords don't match"

              else
                text ""
            , button [ attrIf (model.password /= model.password2 || stats.strength == VeryWeak) (class "disabled") ]
                [ text "Next" ]
            ]

    else
        div [ class "main" ]
            [ characterPicker model.character
            , button
                [ class "big"
                , if model.character == Nothing then
                    class "disabled"

                  else
                    onClick Register
                ]
                [ text "Enter world" ]
            ]


viewStrength : RumkinResult -> Html msg
viewStrength { strength } =
    let
        ( color, string ) =
            case strength of
                VeryWeak ->
                    ( "red", "Very weak" )

                Weak ->
                    ( "orange", "Weak" )

                Reasonable ->
                    ( "yellow", "Reasonable" )

                Strong ->
                    ( "limegreen", "Strong" )

                VeryStrong ->
                    ( "limegreen", "Very Strong" )
    in
    span [ style "color" color ] [ text string ]


characterPicker selected =
    div [ class "characterPicker" ]
        (h2 [] [ text "Choose your appearance" ]
            :: (Character.skinList
                    |> List.map
                        (\skin ->
                            Html.button
                                [ classList [ ( "character", True ), ( "selected", selected == Just skin ) ]
                                , style "background-image" ("url(" ++ Character.url skin ++ ")")
                                , onClick (SelectedCharacter skin)
                                ]
                                []
                        )
               )
        )
