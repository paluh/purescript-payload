-- | This module contains all of the types and kinds that can appear
-- | in an API spec.
module Payload.Spec
       ( Spec(Spec)
       , Route(Route)
       , GET
       , HEAD
       , POST
       , PUT
       , DELETE
       , Routes(Routes)
       , Guards(Guards)
       , kind GuardList
       , GNil
       , GCons
       , type (:)
       , Nil
       ) where

-- | Wrapper for writing type-level specs
data Spec apiSpec = Spec

-- | Type-level representation of an endpoint route, meant to be used
-- | in combination with the method convenience types below.
-- |
-- | Examples:
-- | ```purescript
-- | GET "/api/user/<id>"
-- | DELETE "/api/posts/<..rest>"
-- | ```
data Route (method :: Symbol) (path :: Symbol) spec = Route

type GET = Route "GET"

-- | HEAD responses will not contain a body.
type HEAD = Route "HEAD"

type POST = Route "POST"
type PUT = Route "PUT"
type DELETE = Route "DELETE"

-- | Defines a type-level parent route. Takes a path, which
-- | is prepended to all child routes, and a spec, which must
-- | be a type-level record. If the path contains named URL parameters,
-- | the types of those parameters must be given in the `params` field
-- | of the spec record. Can optionally contain a `guards` field with
-- | a list of guards to run before calling child routes. All other
-- | fields are treated as endpoint routes or sub-parent routes.
-- | 
-- | Example:
-- | ```purescript
-- | Routes "/users/<userId>" {
-- |   guards :: Guards ("apiKey" : Nil),
-- |   params :: { userId :: Int },
-- |   posts :: GET "/posts" {
-- |     response :: UserPosts
-- |   }
-- | }
-- | ```
-- |
-- |
data Routes (path :: Symbol) routesSpec = Routes

-- | Type-level list of guard names that will be run before calling
-- | a route or child routes.
data Guards (g :: GuardList) = Guards

foreign import kind GuardList
foreign import data GNil :: GuardList
foreign import data GCons :: Symbol -> GuardList -> GuardList

infixr 1 type GCons as :
type Nil = GNil
