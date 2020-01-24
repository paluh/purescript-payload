module Payload.Docs.DocumentedApi where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol, SProxy(..), reflectSymbol)
import Foreign.Object as Object
import Payload.Docs.DocumentedEndpoint (class DocumentedEndpoint, mkEndpointOpenApi)
import Payload.Docs.OpenApi (OpenApiSpec)
import Payload.Docs.OpenApi as OpenApi
import Payload.Internal.Route (DefaultParentRoute, Undefined)
import Payload.Spec (Docs(..), Guards(..), Route(Route), Routes, Spec)
import Prim.Row as Row
import Prim.RowList (class RowToList, kind RowList)
import Prim.RowList as RowList
import Prim.Symbol as Symbol
import Type.Data.RowList (RLProxy(..))
import Type.Equality (class TypeEquals)
import Type.Proxy (Proxy(..))

class DocumentedApi routesSpec where
  mkOpenApiSpec :: forall r. Spec { routes :: routesSpec | r } -> OpenApiSpec

instance openApiSpecRootRecord ::
  ( -- Parse out child routes from root
    Row.Union rootSpec DefaultParentRoute mergedSpec
  , Row.Nub mergedSpec rootSpecWithDefaults
  , TypeEquals
      (Record rootSpecWithDefaults)
      { params :: Record rootParams
      , guards :: guards
      , docs :: Docs docsSpec
      | childRoutes}

  -- Recurse through child routes
  , RowToList childRoutes childRoutesList
  , DocumentedApiList
      childRoutesList
      "" -- child base path
      rootParams -- child base params

  , DocsInfo docsSpec
  ) => DocumentedApi (Record rootSpec) where
  mkOpenApiSpec routesSpec = mkOpenApiSpecList
                           (RLProxy :: _ childRoutesList)
                           (SProxy :: _ "")
                           (Proxy :: _ (Record rootParams))
                           # addDocsInfo docsInfo
    where
      docsInfo = getDocsInfo (Proxy :: _ docsSpec)

class DocumentedApiList
  (routesSpecList :: RowList)
  (basePath :: Symbol)
  (baseParams :: # Type)
  where
    mkOpenApiSpecList ::
      RLProxy routesSpecList
      -> SProxy basePath
      -> Proxy (Record baseParams)
      -> OpenApiSpec

instance openApiSpecListNil :: DocumentedApiList RowList.Nil basePath baseParams where
  mkOpenApiSpecList _ _ _ =
    { openapi: "3.0.2"
    , info: defaultInfo
    , paths: Object.empty
    , servers: [] }

instance openApiSpecListConsRoute ::
  ( IsSymbol routeName
  , IsSymbol method
  , IsSymbol path
  , IsSymbol basePath
  , DocumentedEndpoint (Route method path routeSpec) basePath baseParams payload res
  , DocumentedApiList remRoutes basePath baseParams
  ) => DocumentedApiList
         (RowList.Cons routeName (Route method path routeSpec) remRoutes)
         basePath
         baseParams where
  mkOpenApiSpecList _ _ _ = rest { paths = Object.insert
                                             endpointOpenApi.path
                                             endpointOpenApi.item
                                             rest.paths }
    where
      endpointOpenApi = mkEndpointOpenApi
                       (Route :: Route method path routeSpec)
                       (SProxy :: _ basePath)
                       (Proxy :: _ (Record baseParams))
      rest = mkOpenApiSpecList (RLProxy :: _ remRoutes)
                               (SProxy :: _ basePath)
                               (Proxy :: _ (Record baseParams))

instance openApiSpecListConsRoutes ::
  ( IsSymbol parentName
  , IsSymbol basePath
  , IsSymbol path

  -- Parse out child routes from parent params
  , Row.Union parentSpec DefaultParentRoute mergedSpec
  , Row.Nub mergedSpec parentSpecWithDefaults
  , TypeEquals
      (Record parentSpecWithDefaults)
      { params :: Record parentParams
      , guards :: guards
      , docs :: Docs docsSpec
      | childRoutes}
  , Row.Union baseParams parentParams childParams

  -- Recurse through child routes
  , RowToList childRoutes childRoutesList
  , Symbol.Append basePath path childBasePath
  , DocumentedApiList childRoutesList childBasePath childParams

  , DocumentedApiList remRoutes basePath baseParams
  , DocsInfo docsSpec
  ) => DocumentedApiList
         (RowList.Cons parentName (Routes path (Record parentSpec)) remRoutes)
         basePath
         baseParams where
  mkOpenApiSpecList _ _ _ = OpenApi.union childRoutes rest
                            # addDocsInfo docsInfo
    where
      childRoutes = mkOpenApiSpecList
                      (RLProxy :: _ childRoutesList)
                      (SProxy :: _ childBasePath)
                      (Proxy :: _ (Record childParams))
      rest = mkOpenApiSpecList (RLProxy :: _ remRoutes)
                               (SProxy :: _ basePath)
                               (Proxy :: _ (Record baseParams))
      docsInfo = getDocsInfo (Proxy :: _ docsSpec)

class DocsInfo docsSpec where
  getDocsInfo :: Proxy docsSpec -> Maybe OpenApi.Info

instance docsInfoUndefined :: DocsInfo Undefined where
  getDocsInfo _ = Nothing

type DefaultDocsSpec =
  ( title :: SProxy "Payload Live API Documentation"
  , version :: SProxy "0.0.0" )

defaultInfo :: OpenApi.Info
defaultInfo =
  { title: "Payload Live API Documentation"
  , version: "0.0.0" }

instance docsInfoRecord ::
  ( Row.Union docsSpec DefaultDocsSpec mergedSpec
  , Row.Nub mergedSpec docsSpecWithDefaults
  , TypeEquals
      (Record docsSpecWithDefaults)
      { title :: SProxy title
      , version :: SProxy version | r }
  , IsSymbol title
  , IsSymbol version
  ) => DocsInfo (Record docsSpec) where
  getDocsInfo _ = Just
    { title: reflectSymbol (SProxy :: _ title)
    , version: reflectSymbol (SProxy :: _ version) }

addDocsInfo :: Maybe OpenApi.Info -> OpenApiSpec -> OpenApiSpec
addDocsInfo Nothing spec = spec
addDocsInfo (Just info) spec = spec { info = info }