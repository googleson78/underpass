{-# LANGUAGE OverloadedStrings #-}

module Ccg.TypeSystemSpec (main, spec) where

import Test.Hspec

import LambdaCalculus.LambdaTypes
import Utils.Maths

import Ccg.TypeSystem

main :: IO ()
main = hspec spec

data Base = E | F | R | S deriving (Show, Eq)

instance PartialOrd Base where
    (<!) = (==)

instance MSemiLattice Base where
    a /\ b
        | a == b    = a
        | otherwise = error "trying to meet unequal base items"

tA :: WrappedType Base
tA = Basic $ SubType "A" tB
tB :: WrappedType Base
tB = Basic $ SubType "B" (Application tC tD)
tC :: WrappedType Base
tC = Basic $ SubType "C" tE
tD :: WrappedType Base
tD = Basic $ SubType "F" tF
tE :: WrappedType Base
tE = Basic $ Type E
tF :: WrappedType Base
tF = Basic $ Type F
tP :: WrappedType Base
tP = Basic $ SubType "P" (Application tR tS)
tR :: WrappedType Base
tR = Basic $ Type R
tS :: WrappedType Base
tS = Basic $ Type S

tp :: WrappedType Base -> TypeBox Base
tp t = TypeBox True t

tn :: WrappedType Base -> TypeBox Base
tn t = TypeBox False t

checkLt :: WrappedType Base -> WrappedType Base -> Expectation
checkLt a b = do
    a == b `shouldBe` False
    tp a <! tp b `shouldBe` True
    tp a <! tn b `shouldBe` False
    tn a <! tp b `shouldBe` True
    tn a <! tn b `shouldBe` False

    tp a !> tp b `shouldBe` False
    tp a !> tn b `shouldBe` False
    tn a !> tp b `shouldBe` False
    tn a !> tn b `shouldBe` False

    tp a /\ tp b `shouldBe` tp a

checkEq :: WrappedType Base -> WrappedType Base -> Expectation
checkEq a b = do
    a == b `shouldBe` True
    tp a <! tp b `shouldBe` True
    tp a <! tn b `shouldBe` True
    tn a <! tp b `shouldBe` True
    tn a <! tn b `shouldBe` True

    tp a !> tp b `shouldBe` True
    tp a !> tn b `shouldBe` True
    tn a !> tp b `shouldBe` True
    tn a !> tn b `shouldBe` True

    tp a /\ tp b `shouldBe` tp a
    tp a /\ tp b `shouldBe` tp b

checkUnrelated :: WrappedType Base -> WrappedType Base -> Expectation
checkUnrelated a b = do
    a == b `shouldBe` False
    tp a <! tp b `shouldBe` False
    tp a <! tn b `shouldBe` False
    tn a <! tp b `shouldBe` False
    tn a <! tn b `shouldBe` False

    tp a !> tp b `shouldBe` False
    tp a !> tn b `shouldBe` False
    tn a !> tp b `shouldBe` False
    tn a !> tn b `shouldBe` False


spec :: Spec
spec = do
  describe "meet and less-than" $ do
    it "works on simple examples" $ do
      checkLt tA tB
      checkEq tB tB
      checkEq tP tP
    it "works on examples with application" $ do
      checkLt tA (Application tC tD)
      checkEq (Application tA tA) (Application tA tA)
    it "works on examples with transitive application" $ do
      checkLt tA (Application tE tF)
    it "works on examples with parallel application" $ do
      checkLt (Application tA tP) (Application (Application tE tF) (Application tR tS))
    it "works on examples with *" $ do
      checkLt (Application tA tP) (Application (Application tE tF) (Application tR Bot))
  describe "less-than in unrelated cases" $ do
    it "works on simple example" $ do
      checkUnrelated tA tP
      checkUnrelated tB tR
  describe "meet in non-branch cases" $ do
    it "works on example with two *'s" $ do
      (tp $ Application Bot tP) /\ (tp $ Application (Application tE tF) (Application tR Bot))
        `shouldBe`
            (tp $ Application (Application tE tF) (Application tR tS))
