module App where

import Effects exposing (Effects, Never)
import String exposing (startsWith, contains, isEmpty, toLower, concat)
import Html exposing (..)
import Utils exposing (linkCss, onInput)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, (:=))
import Task exposing (Task, andThen)
import Debug

-- MODEL

baseUrl = "http://swapi.co/api/people/"

type alias Character =
  { name: String,
    height: String,
    mass: String,
    gender: String
  }

type alias Characters = List Character
type alias Next = String
type alias Data = { characters: Characters, next: Maybe Next}


type alias Model =
  { characters: Characters,
    next: Maybe Next,
    term: String
  }


newCharacter : String -> String -> String -> String -> Character
newCharacter name height mass gender =
  { name = name ,
    height = height,
    mass = mass,
    gender = gender
  }


init : (Model, Effects Action)
init = (
  Model [] Nothing "",
  fetchCharacters Nothing
  )

-- UPDATE


type Action
  = NoOp
  | LoadMore
  | ShowCharacters (Maybe Data)
  | Search (String)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp ->
      (model, Effects.none)

    LoadMore ->
      case model.next of
        Just n -> (model, fetchCharacters model.next)
        Nothing -> (model, Effects.none)

    ShowCharacters modelDef ->
      case modelDef of
        Just m ->
          ( Model ((++) model.characters m.characters) m.next model.term
          , Effects.none)
        Nothing ->
          (model, Effects.none)

    Search t ->
      ({model | term = t}, Effects.none)


-- VIEW


view : Signal.Address Action -> Model -> Html
view address model =
  div [ ]
    [
    linkCss "style.css",
    header [] [
      h2 [ ] [text "Star Wars App - Elm lang"]
      , input
          [ type' "text",
            placeholder "Search Characters...",
            value model.term,
            name "characters",
            autofocus True,
            onInput address Search,
            class "search"
          ]
          [ ]
    ]
    , viewCharacters model.term model.characters
    , button [classList [("hidden", (model.next == Nothing))],
        onClick address LoadMore]
        [ text "Load More Characters" ]
    ]


makeHighlight: String -> String -> Html
makeHighlight term name =
  let
    parts = String.split term name
    front = Maybe.withDefault "" (List.head parts)
    back = String.slice
      ((String.length front) + (String.length term)) (String.length name) name
  in
    if isEmpty term || not (contains term name)
      then span [] [text name]
    else
      span [] [
        span [class "front"] [text (" " ++ front)],
        span [class "highlight"] [text term],
        span [class "back"] [text back]
      ]


characterView: String -> Character -> Html
characterView term character =
    li [ class "characterView" ]
      [div [] [
          li [ class "cname"] [
            makeHighlight term character.name
          ]
        , ul [] [
            li [] [text ("Name: " ++ character.name)]
          , li [] [text ("Mass (kg): " ++ character.mass)]
          , li [] [text ("Height (cm): " ++ character.height)]
          , li [] [text ("Gender: " ++ character.gender)]
          ]
      ]]


viewCharacters: String -> Characters -> Html
viewCharacters term characters =
  let
    activeCharacters =
      List.map (characterView term)
        (List.filter (\c -> contains (toLower term) (toLower c.name)) characters)
  in
    ul [ class "characters" ] activeCharacters


-- EFFECTS

fetchFilms x =
  let
    b = Debug.log "fetchFilms" x
  in
    Http.get results (Maybe.withDefault baseUrl x.next)

    
fetchCharacters : Maybe String -> Effects Action
fetchCharacters requestURL =
  Http.get results (Maybe.withDefault baseUrl requestURL) `andThen` fetchFilms
    |> Task.toMaybe
    |> Task.map ShowCharacters
    |> Effects.task


decoder: Decoder Character
decoder =
  Decode.object4 Character
    ("name" := Decode.string)
    ("height" := Decode.string)
    ("mass" := Decode.string)
    ("gender" := Decode.string)


results: Decoder Data
results =
  Decode.object2 Data
    ("results" := Decode.list decoder)
    (Decode.maybe ("next" := Decode.string))
