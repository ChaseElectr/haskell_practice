{-# OPTIONS_GHC -Wall #-}
module LogAnalysis where
import           Log

isNum :: String -> Bool
isNum (x:xs) = (x `elem` ['0'..'9']) && isNum xs
isNum []     = True

parseMessage :: String -> LogMessage
parseMessage s = parseMessageHelper (words s)
        where parseMessageHelper ("I":t1:xs)
                |isNum t1 = LogMessage Info (read t1::Int) (unwords xs)
              parseMessageHelper ("W":t2:xs)
                |isNum t2 = LogMessage Warning (read t2::Int) (unwords xs)
              parseMessageHelper ("E":num:t3:xs)
                |isNum num && isNum t3 = LogMessage (Error (read num::Int)) (read t3::Int) (unwords xs)
              parseMessageHelper _ = Unknown s


parse :: String -> [LogMessage]
parse "" = []
parse s  = [parseMessage x | x <- lines s]

insert :: LogMessage -> MessageTree -> MessageTree
insert (Unknown _) msgtree = msgtree
insert m@LogMessage {} Leaf = Node Leaf m Leaf
insert m1@(LogMessage _ t1 _) (Node l m2@(LogMessage _ t2 _) r)
        |t1 < t2 = Node (insert m1 l) m2 r
        |otherwise = Node l m2 (insert m1 r)
insert _ _ = error "Wrong trees"

build :: [LogMessage] -> MessageTree
build []     = Leaf
build (x:xs) = insert x (build xs)

inOrder :: MessageTree -> [LogMessage]
inOrder Leaf         = []
inOrder (Node l m r) = inOrder l ++ [m] ++ inOrder r

whatWentWrong :: [LogMessage] -> [String]
whatWentWrong messages = converToStringList (inOrder (build messages))
        where converToStringList = map converToString
              converToString (LogMessage (Error _) _ s) = s
              converToString _                          = []
