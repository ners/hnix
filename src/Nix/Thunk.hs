{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Nix.Thunk where

import Control.Exception hiding (catch)
import Data.Typeable

class Monad m => MonadThunk v t m | t -> m, t -> v where
    thunk :: m v -> m t
    thunkId :: t -> Int
    query :: t -> r -> (v -> r) -> r
    queryM :: t -> m r -> (v -> m r) -> m r
    force :: t -> (v -> m r) -> m r
    forceEff :: t -> (v -> m r) -> m r
    wrapValue :: v -> t
    getValue :: t -> Maybe v

newtype ThunkLoop = ThunkLoop (Maybe Int)
    deriving (Show, Typeable)

instance Exception ThunkLoop
