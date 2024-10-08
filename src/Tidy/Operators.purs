module Tidy.Operators where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldl, foldr)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..), snd, uncurry)
import PureScript.CST.Errors (ParseError)
import PureScript.CST.Lexer as Lexer
import PureScript.CST.TokenStream (TokenStep(..), TokenStream)
import PureScript.CST.TokenStream as TokenStream
import PureScript.CST.Types (Declaration(..), Export(..), FixityOp(..), IntValue(..), Module(..), ModuleBody(..), ModuleHeader(..), Name(..), Operator(..), Separated(..), Token(..), Wrapped(..))
import Tidy.Precedence (OperatorNamespace(..), Precedence, PrecedenceMap, QualifiedOperator(..), insertOperator, lookupOperator, remapOperators)

parseOperatorTable :: Array String -> PrecedenceMap
parseOperatorTable = foldr (uncurry insertOperator) Map.empty <<< Array.mapMaybe parseOperatorPrec

parseOperatorPrec :: String -> Maybe (Tuple QualifiedOperator Precedence)
parseOperatorPrec = Lexer.lex >>> tokenStreamToArray >>> case _ of
  Right [ TokSymbolName modName op, TokInt _ (SmallInt prec) ] ->
    Just $ Tuple (QualifiedOperator modName OperatorValue (Operator op)) prec
  Right [ TokSymbolName modName op, TokLowerName Nothing "type", TokInt _ (SmallInt prec) ] ->
    Just $ Tuple (QualifiedOperator modName OperatorType (Operator op)) prec
  _ ->
    Nothing
  where
    tokenStreamToArray :: TokenStream -> Either ParseError (Array Token)
    tokenStreamToArray = go []
      where
        go acc = TokenStream.step >>> case _ of
          TokenEOF _ _ ->
            Right acc
          TokenError _ err _ _ ->
            Left err
          TokenCons tok _ next _ ->
            go (Array.snoc acc tok.value) next

resolveOperatorExports :: forall e. PrecedenceMap -> Module e -> PrecedenceMap
resolveOperatorExports
  precMap
  mod@
    ( Module
        { header: ModuleHeader { exports, name: Name { name: modName } }
        , body: ModuleBody { decls }
        }
    ) =
  case exports of
    Nothing ->
      foldl goDecl precMap decls
    Just (Wrapped { value: Separated { head, tail } }) ->
      foldl goExport precMap $ Array.cons head $ map snd tail

  where
    remappedPrecMap =
      remapOperators precMap mod

    goExport pm = fromMaybe pm <<< case _ of
      ExportOp (Name { name: op }) -> do
        prec <- lookupOperator (QualifiedOperator Nothing OperatorValue op) remappedPrecMap
        pure $ insertOperator (QualifiedOperator (Just modName) OperatorValue op) prec pm
      ExportTypeOp _ (Name { name: op }) -> do
        prec <- lookupOperator (QualifiedOperator Nothing OperatorType op) remappedPrecMap
        pure $ insertOperator (QualifiedOperator (Just modName) OperatorType op) prec pm
      ExportModule _ (Name { name: exportModName }) -> do
        prec <- Map.lookup (Just exportModName) remappedPrecMap
        pure $ Map.insertWith Map.union (Just modName) prec pm
      _ ->
        Nothing

    goDecl pm = case _ of
      DeclFixity { prec: Tuple _ prec, operator } ->
        case operator of
          FixityValue _ _ (Name { name: op }) ->
            insertOperator (QualifiedOperator (Just modName) OperatorValue op) prec pm
          FixityType _ _ _ (Name { name: op }) ->
            insertOperator (QualifiedOperator (Just modName) OperatorType op) prec pm
      _ ->
        pm
