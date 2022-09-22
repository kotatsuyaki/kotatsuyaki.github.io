{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wunused-imports #-}
{-# OPTIONS_GHC -Wunused-matches #-}

{-# HLINT ignore "Use <&>" #-}

import Control.Monad.State
import Data.Functor.Identity (runIdentity)
import Data.List (isInfixOf)
import Data.Maybe (fromMaybe)
import Data.Text (Text, unlines)
import Hakyll
import System.FilePath.Posix
import Text.Pandoc (Block (Header, Null, RawBlock), Format (Format), HTMLMathMethod (MathJax), Inline (Span, Str), Pandoc, Template, WriterOptions (writerHTMLMathMethod, writerTOCDepth, writerTableOfContents, writerTemplate), compileTemplate, getDefaultExtensions, writerExtensions)
import Text.Pandoc.Walk

---------
-- Config
---------
root :: String
root = "https://blog.kotatsu.dev"

siteName :: String
siteName =
  "kotatsuyaki's blog"

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "dist",
      ignoreFile = const False,
      previewHost = "127.0.0.1",
      previewPort = 8000,
      providerDirectory = "src",
      storeDirectory = "_cache",
      tmpDirectory = "_tmp"
    }

--------
-- Build
--------

main :: IO ()
main = hakyllWith config $ do
  forM_
    [ "CNAME",
      "robots.txt",
      "images/*",
      ".nojekyll"
    ]
    $ \f -> match f $ do
      route idRoute
      compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match "posts/*" $ do
    let ctx =
          constField "root" root
            <> constField "type" "article"
            <> constField "siteName" siteName
            <> constField "lang" "en"
            <> postCtx

    route niceRoute
    compile $ do
      -- Compile and save the teaser
      _ <- pandocTeaserCompiler >>= saveSnapshot "teaser"

      -- Compile the post and apply post template
      pandocPostCompiler
        >>= loadAndApplyTemplate "templates/postbody.html" ctx
        >>= loadAndApplyTemplate "templates/shared.html" ctx

  create ["index.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAllSnapshots "posts/*" "teaser"

      let indexCtx =
            listField "posts" postCtx (return posts)
              <> constField "root" root
              <> constField "siteName" siteName
              <> constField "lang" "en"
              <> defaultContext

      makeItem ("" :: String)
        >>= loadAndApplyTemplate "templates/shared.html" indexCtx
        >>= removeIndexHtml

  match "templates/*" $
    compile templateBodyCompiler

  create ["sitemap.xml"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"

      let pages = posts
          sitemapCtx =
            constField "root" root
              <> constField "siteName" siteName
              <> listField "pages" postCtx (return pages)

      makeItem ("" :: String)
        >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

  create ["rss.xml"] $ do
    route idRoute
    compile (feedCompiler renderRss)

  create ["atom.xml"] $ do
    route idRoute
    compile (feedCompiler renderAtom)

-----------
-- Contexts
-----------

feedCtx :: Context String
feedCtx =
  titleCtx
    <> postCtx
    <> bodyField "description"

postCtx :: Context String
postCtx =
  constField "root" root
    <> constField "siteName" siteName
    <> dateField "date" "%Y-%m-%d"
    <> defaultContext

titleCtx :: Context String
titleCtx =
  field "title" updatedTitle

----------------
-- Title Helpers
----------------
updatedTitle :: Item a -> Compiler String
updatedTitle =
  fmap replaceTitleAmp . getMetadata . itemIdentifier

replaceAmp :: String -> String
replaceAmp =
  replaceAll "&" (const "&amp;")

replaceTitleAmp :: Metadata -> String
replaceTitleAmp =
  replaceAmp . safeTitle

safeTitle :: Metadata -> String
safeTitle =
  fromMaybe "no title" . lookupString "title"

------------
-- Compilers
------------

-- Post compiler without any additional transformations
pandocPostCompiler :: Compiler (Item String)
pandocPostCompiler =
  baseCompiler id tocTemplate

-- Teaser compiler & its Pandoc transformations
pandocTeaserCompiler :: Compiler (Item String)
pandocTeaserCompiler =
  baseCompiler (removeAfterMore . removeSidenotes . lowerHeaders) plainTemplate

removeAfterMore :: Pandoc -> Pandoc
removeAfterMore doc = evalState (walkM ram doc) False
  where
    ram :: Block -> State Bool Block
    ram (RawBlock (Format "html") "<!-- more -->") = do
      put True
      return Null
    ram x = do
      hasSeenMore <- get
      return (if hasSeenMore then Null else x)

removeSidenotes :: Pandoc -> Pandoc
removeSidenotes = walk rs
  where
    rs :: Inline -> Inline
    rs sp@(Span (_identifier, classes, _kvpairs) _inlines) =
      if "sidenote-wrapper" `elem` classes
        then Str ""
        else sp
    rs x = x

lowerHeaders :: Pandoc -> Pandoc
lowerHeaders = walk lh
  where
    lh :: Block -> Block
    lh (Header level attrs text) =
      Header (min 6 (level - 3)) attrs text
    lh x = x

-- Base compiler shared between the teaser and the post compiler
baseCompiler :: (Pandoc -> Pandoc) -> Text.Pandoc.Template Text -> Compiler (Item String)
baseCompiler transf template = do
  getResourceBody
    >>= withItemBody
      ( unixFilter
          "pandoc"
          [ "--filter",
            "pandoc-sidenote",
            "--filter",
            "pandoc-crossref",
            "-t",
            "markdown"
          ]
      )
    >>= readPandocWith defaultHakyllReaderOptions
    >>= return . fmap transf
    >>= return
      . writePandocWith
        ( defaultHakyllWriterOptions
            { writerExtensions = getDefaultExtensions "markdown+raw_attribute",
              writerHTMLMathMethod = MathJax "",
              writerTOCDepth = 2,
              writerTableOfContents = True,
              writerTemplate = Just template
            }
        )

plainTemplate :: Text.Pandoc.Template Text
plainTemplate = either error id . runIdentity . compileTemplate "" $ "$body$"

tocTemplate :: Text.Pandoc.Template Text
tocTemplate =
  either error id . runIdentity . compileTemplate "" $
    Data.Text.unlines
      [ "<nav id=\"TOC\" role=\"doc-toc\">",
        "  <strong>Contents</strong> <label for=\"contents\">⊕</label>",
        "  <input type=\"checkbox\" id=\"contents\">",
        "  $table-of-contents$",
        "</nav>",
        "<main>$body$</main>"
      ]

-------
-- Feed
-------
type FeedRenderer =
  FeedConfiguration ->
  Context String ->
  [Item String] ->
  Compiler (Item String)

feedCompiler :: FeedRenderer -> Compiler (Item String)
feedCompiler renderer =
  renderer feedConfiguration feedCtx
    =<< recentFirst
    =<< loadAllSnapshots "posts/*" "teaser"

feedConfiguration :: FeedConfiguration
feedConfiguration =
  FeedConfiguration
    { feedTitle = "kotatsuyaki's blog",
      feedDescription = "I jumped through these hoops and wrote about them so that you don't have to.",
      feedAuthorName = "kotatsuyaki (Ming-Long Huang)",
      feedAuthorEmail = "",
      feedRoot = root
    }

---------
-- Routes
---------

niceRoute :: Routes
niceRoute = customRoute createIndexRoute
  where
    createIndexRoute identifier =
      takeDirectory p </> takeBaseName p </> "index.html"
      where
        p = toFilePath identifier

removeIndexHtml :: Item String -> Compiler (Item String)
removeIndexHtml item =
  return $
    fmap (withUrls removeIndexStr) item

removeIndexStr :: String -> String
removeIndexStr url = case splitFileName url of
  (dir, "index.html")
    | isLocal dir -> dir
    | otherwise -> url
  _ -> url
  where
    isLocal :: String -> Bool
    isLocal uri = not ("://" `isInfixOf` uri)
