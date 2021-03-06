{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.CommSec.KeyExchange
-- import Network.CommSec
import qualified Data.ByteString as B
import Data.ByteString.Char8 ()
import Crypto.PubKey.OpenSsh
import Crypto.Types.PubKey.RSA
import Control.Concurrent
import System.FilePath


port :: PortNumber
port = 1874
host = "127.0.0.1"

readSSHKeys :: FilePath -> IO (PublicKey, PrivateKey)
readSSHKeys fp = do
    OpenSshPublicKeyRsa pub _ <- (either error id . decodePublic) `fmap` B.readFile (fp <.> "pub")
    OpenSshPrivateKeyRsa priv <- (either error id . (\x -> decodePrivate x)) `fmap` B.readFile fp
    return (pub,priv)

main = do
    (pubA,privA) <- readSSHKeys "id_rsa"
    (pubB,privB) <- readSSHKeys "id_rsa2"
    {-print pubB
    print pubA
    print privB
    print privA
    -}
    forkIO $ listener privA pubB
    threadDelay 1000000
    connecter privB pubA

listener priv pub = do
    conn <- snd `fmap` accept port [pub] priv
    recv conn >>= print
    send conn "Hello to you too!"
    return ()

connecter priv pub = do
    conn <- snd `fmap` connect host port [pub] priv
    send conn "Hello!"
    recv conn >>= print
    return ()
