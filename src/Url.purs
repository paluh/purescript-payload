module Payload.Url where

import Prelude

import Data.Either (Either(..))
import Data.List (List(..), (:))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Payload.Params (class FromParam, class FromSegments, class ToParam, fromParam, fromSegments, toParam)
import Payload.UrlParsing (class ParseUrl, FProxy(..), Key, Lit, Multi, UrlCons, UrlNil, kind UrlList)
import Prim.Row as Row
import Record as Record
import Type.Equality (class TypeEquals, to)
import Type.Prelude (class IsSymbol, SProxy(..), reflectSymbol)
import Type.Proxy (Proxy(..))

class EncodeUrl (urlStr :: Symbol) params | urlStr -> params where
  encodeUrl :: SProxy urlStr -> Record params -> String

instance encodeUrlRecord ::
  ( ParseUrl urlStr urlParts
  , WriteUrl urlParts params
  ) => EncodeUrl urlStr params where
  encodeUrl _ params = writeUrl (FProxy :: FProxy urlParts) params

class WriteUrl (urlParts :: UrlList) params where
  writeUrl :: FProxy urlParts -> Record params -> String

instance writeUrlUrlNil :: WriteUrl UrlNil params where
  writeUrl _ params = ""

instance writeUrlConsKey ::
  ( IsSymbol key
  , Row.Cons key valType from params
  , ToParam valType
  , WriteUrl rest params
  ) => WriteUrl (UrlCons (Key key) rest) params where
  writeUrl _ params = "/" <> encodedParam <> restOfUrl
    where
      encodedParam = toParam (Record.get (SProxy :: SProxy key) params)
      restOfUrl = writeUrl (FProxy :: FProxy rest) params

instance writeUrlConsLit ::
  ( IsSymbol lit
  , WriteUrl rest params
  ) => WriteUrl (UrlCons (Lit lit) rest) params where
  writeUrl _ params = "/" <> litStr <> restOfUrl
    where
      litStr = reflectSymbol (SProxy :: SProxy lit)
      restOfUrl = writeUrl (FProxy :: FProxy rest) params

class DecodeUrl (urlStr :: Symbol) params | urlStr -> params where
  decodeUrl :: SProxy urlStr -> Proxy (Record params) -> List String -> Either String (Record params)

instance decodeUrlSymbol ::
  ( ParseUrl urlStr urlParts
  , MatchUrl urlParts params () params
  ) => DecodeUrl urlStr params where
  decodeUrl _ paramsType path = match (FProxy :: FProxy urlParts) paramsType {} path

class MatchUrl (urlParts :: UrlList) params from to | urlParts -> from to where
  match :: FProxy urlParts -> Proxy (Record params) -> Record from -> List String -> Either String (Record to)

instance matchUrlUrlNil ::
  ( TypeEquals (Record from) (Record to)
  ) => MatchUrl UrlNil params from to where
  match _ _ params Nil = Right (to params)
  match _ _ _ path = Left $ "Path mismatch: Ran out of params when path still had '" <> show path <> "'"

instance matchUrlMulti ::
  ( IsSymbol key
  , Row.Cons key valType from to
  , Row.Lacks key from
  , FromSegments valType
  ) => MatchUrl (UrlCons (Multi key) UrlNil) to from to where
  match _ paramsType params segments = case fromSegments segments of
    Left errors -> Left $ show errors
    Right decoded -> Right $ Record.insert (SProxy :: SProxy key) decoded params

instance matchUrlConsKey ::
  ( IsSymbol key
  , MatchUrl rest params from' to
  , Row.Cons key valType from from'
  , Row.Cons key valType _params params
  , Row.Lacks key from
  , FromParam valType
  ) => MatchUrl (UrlCons (Key key) rest) params from to where
  match _ paramsType params Nil = Left "Decoding error at key"
  match _ paramsType params (segment : rest) = case fromParam segment of
    Left errors -> Left $ show errors
    Right decoded -> let newParams = Record.insert (SProxy :: SProxy key) decoded params in
      match (FProxy :: FProxy rest) paramsType newParams rest

instance matchUrlConsLit ::
  ( IsSymbol lit
  , MatchUrl rest params from to
  ) => MatchUrl (UrlCons (Lit lit) rest) params from to where
  match _ paramsType params Nil = Left "Decoding error at literal"
  match _ paramsType params (segment : rest) =
    match (FProxy :: FProxy rest) paramsType params rest
