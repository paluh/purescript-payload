module Payload.Server.DecodeBody
       ( class DecodeBody
       , decodeBody
       ) where

import Prelude

import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Simple.JSON as SimpleJson

class DecodeBody body where
  decodeBody :: String -> Either String body

instance decodeBodyRecord :: SimpleJson.ReadForeign (Record r) => DecodeBody (Record r) where
  decodeBody = SimpleJson.readJSON >>> lmap show

instance decodeBodyArray :: SimpleJson.ReadForeign (Array r) => DecodeBody (Array r) where
  decodeBody = SimpleJson.readJSON >>> lmap show

instance decodeBodyString :: DecodeBody String where
  decodeBody = Right
