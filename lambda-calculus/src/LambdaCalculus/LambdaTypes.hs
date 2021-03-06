{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}

module LambdaCalculus.LambdaTypes where

import qualified Utils.Parsing as P
import Utils.Parsing ((<|>))
import Data.Functor (($>))

import Control.Exception (Exception, throw)
import Data.Dynamic (Typeable)
import Utils.Maths

data ApplicativeType b
    = Basic b
    | Application (ApplicativeType b) (ApplicativeType b)
    | Bot
    deriving (Eq)

class (Show b, Show a, Typeable a, Typeable b, PartialOrd b) => Typed a b where  -- items of haskell type a have basic types from b
    typeOf :: a -> ApplicativeType b

instance (Show b) => Show (ApplicativeType b) where
    show (Basic x) = show x
    show (Application a b) = "(" <> show a <> " -> " <> show b <> ")"
    show Bot = "*"

instance (P.Parseable b) => P.Parseable (ApplicativeType b) where
    parser = parseTypeExpr

parseTypeExpr :: (P.Parseable b) => P.Parser (ApplicativeType b)
parseTypeExpr = P.makeExprParser parseTypeTerm
    [ [ P.InfixR (P.operator "->" $> Application) ]
    ]

parseTypeTerm :: (P.Parseable b) => P.Parser (ApplicativeType b)
parseTypeTerm
    =   P.braces parseTypeExpr
    <|> (Basic <$> P.parser)

instance MSemiLattice b => MSemiLattice (ApplicativeType b) where
    (/\) (Basic x) (Basic y) = Basic $ (/\) x y
    (/\) (Application a1 a2) (Application b1 b2) = Application ((/\) a1 b1) ((/\) a2 b2)
    (/\) Bot x = x
    (/\) x Bot = x
    (/\) x y = throw $ CannotMeet x y

instance HasBot (ApplicativeType b) where
    bot = Bot

instance PartialOrd b => PartialOrd (ApplicativeType b) where
    (<!) (Basic x)           (Basic y)           = (<!) x y
    (<!) (Application a1 a2) (Application b1 b2) = ((<!) a1 b1) && ((<!) a2 b2)
    (<!) Bot    Bot          = True
    (<!) Bot    _            = False
    (<!) _      Bot          = True
    (<!) _      _            = False

transform :: (t1 -> t2) -> ApplicativeType t1 -> ApplicativeType t2
transform f (Basic x)           = Basic $ f x
transform f (Application a b)   = Application (transform f a) (transform f b)
transform _ Bot                 =Bot

data TypeException t
    = CannotMeet t t
    | WrongLambdaType t
    deriving (Typeable)

deriving instance Show t => Show (TypeException t)

instance (Show t, Typeable t) => Exception (TypeException t)
