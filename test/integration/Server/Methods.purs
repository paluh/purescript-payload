module Payload.Test.Integration.Server.Methods where

import Prelude

import Payload.ResponseTypes (Empty(..))
import Payload.Server.Response as Response
import Payload.Server.Status as Status
import Payload.Spec (DELETE, GET, HEAD, POST, PUT, Spec(Spec))
import Payload.Test.Helpers (respMatches, withRoutes)
import Payload.Test.Helpers as Helpers
import Test.Unit (TestSuite, suite, test)
  
tests :: TestSuite
tests = do
  let { get, put, post, head, delete } = Helpers.request "http://localhost:3000"
  suite "Methods" do
    suite "GET" do
      test "GET succeeds" $ do
        let spec = Spec :: _ { foo :: GET "/foo"
                                       { response :: String } }
        let handlers = { foo: \_ -> pure "Response" }
        withRoutes spec handlers do
          res <- get "/foo"
          respMatches { status: 200, body: "Response" } res

    suite "POST" do
      test "POST succeeds" $ do
        let spec = Spec :: _ { foo :: POST "/foo"
                                       { body :: { message :: String }
                                       , response :: String } }
        let handlers = { foo: \({body: {message}}) -> pure $ "Received '" <> message <> "'" }
        withRoutes spec handlers do
          res <- post "/foo" "{ \"message\": \"Hi there\" }"
          respMatches { status: 200, body: "Received 'Hi there'" } res
      test "POST succeeds with empty body route" $ do
        let spec = Spec :: _ { foo :: POST "/foo"
                                       { body :: String
                                       , response :: String } }
        let handlers = { foo: \_ -> pure $ "fooEmpty" }
        withRoutes spec handlers do
          res <- post "/foo" ""
          respMatches { status: 200, body: "fooEmpty" } res

    suite "HEAD" do
      test "HEAD succeeds" $ do
        let spec = Spec :: _ { foo :: HEAD "/foo" {} }
        let handlers = { foo: \_ -> pure Empty }
        withRoutes spec handlers do
          res <- head "/foo"
          respMatches { status: 200, body: "" } res
      test "HEAD is accepted where GET route is defined" $ do
        let spec = Spec :: _ { fooGet :: GET "/foo" { response :: String } }
        let handlers = { fooGet: \_ -> pure "get" }
        withRoutes spec handlers do
          res <- head "/foo"
          respMatches { status: 200, body: "" } res
      test "user-specified HEAD route overrides default GET HEAD route" $ do
        let spec = Spec :: _ { fooGet :: GET "/foo" { response :: String }, fooHead :: HEAD "/foo" {} }
        let handlers = { fooGet: \_ -> pure "get", fooHead: \_ -> pure (Response.status Status.accepted Empty) }
        withRoutes spec handlers do
          res <- head "/foo"
          respMatches { status: 202, body: "" } res

    suite "PUT" do
      test "PUT succeeds" $ do
        let spec = Spec :: _ { foo :: PUT "/foo" { response :: String } }
        let handlers = { foo: \_ -> pure "Put" }
        withRoutes spec handlers do
          res <- put "/foo" ""
          respMatches { status: 200, body: "Put" } res

    suite "DELETE" do
      test "DELETE succeeds" $ do
        let spec = Spec :: _ { foo :: DELETE "/foo" { response :: String } }
        let handlers = { foo: \_ -> pure "Delete" }
        withRoutes spec handlers do
          res <- delete "/foo"
          respMatches { status: 200, body: "Delete" } res
