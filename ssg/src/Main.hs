{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wunused-imports #-}
{-# OPTIONS_GHC -Wunused-matches #-}

{-# HLINT ignore "Use <&>" #-}

import Control.Monad.State
import Data.Functor.Identity (runIdentity)
import Data.List (isInfixOf)
import Data.Maybe (fromMaybe, isJust)
import Data.Text (Text, unlines)
import Hakyll
import System.Environment (getArgs, withArgs)
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
main = do
  originalArgs <- getArgs
  let enableDraftsFlag = "--enable-drafts"
  let isDraftsEnabled = enableDraftsFlag `elem` originalArgs

  let remove element = filter (/= element)
  let newArgs = remove enableDraftsFlag originalArgs

  let postsPattern =
        if isDraftsEnabled
          then fromGlob "posts/*" .||. fromGlob "drafts/*"
          else fromGlob "posts/*"
  when isDraftsEnabled $ putStrLn "WARNING: Drafts enabled"

  withArgs newArgs $
    hakyllWith config $ do
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

      match postsPattern $ do
        route niceRoute
        compile $ do
          -- Compile and save the teaser
          _ <- pandocTeaserCompiler >>= saveSnapshot "teaser"

          -- Compile the post and apply post template
          pandocPostCompiler
            >>= loadAndApplyTemplate "templates/postbody.html" postCtx
            >>= loadAndApplyTemplate "templates/shared.html" postCtx

      create ["index.html"] $ do
        route idRoute
        compile $ do
          posts <- recentFirst =<< loadAllSnapshots postsPattern "teaser"

          makeItem ("" :: String)
            >>= loadAndApplyTemplate "templates/shared.html" (indexCtxOf posts)
            >>= removeIndexHtml

      match "templates/*" $
        compile templateBodyCompiler

      create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
          posts <- recentFirst =<< loadAll postsPattern

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

indexCtxOf :: [Item String] -> Context String
indexCtxOf posts =
  listField "posts" postCtx (return posts)
    <> constField "root" root
    <> constField "siteName" siteName
    <> constField "lang" "en"
    <> defaultContext

postCtx :: Context String
postCtx =
  constField "root" root
    <> constField "siteName" siteName
    <> dateField "date" "%Y-%m-%d"
    <> constField "type" "article"
    <> constField "lang" "en"
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
  baseCompiler id tocTemplateIfEnabled
  where
    tocTemplateIfEnabled True = tocPostTemplate
    tocTemplateIfEnabled False = plainPostTemplate

-- Teaser compiler & its Pandoc transformations
pandocTeaserCompiler :: Compiler (Item String)
pandocTeaserCompiler =
  baseCompiler (removeAfterMore . removeSidenotes . lowerHeaders) (const summaryTemplate)

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
baseCompiler :: (Pandoc -> Pandoc) -> (Bool -> Text.Pandoc.Template Text) -> Compiler (Item String)
baseCompiler transf getTemplate = do
  metadata <- getMetadata =<< getUnderlying
  let isTocEnabled = isJust $ lookupString "enable-toc" metadata
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
              writerTemplate = Just (getTemplate isTocEnabled)
            }
        )

summaryTemplate :: Text.Pandoc.Template Text
summaryTemplate = either error id . runIdentity . compileTemplate "" $ "$body$"

tocPostTemplate :: Text.Pandoc.Template Text
tocPostTemplate =
  either error id . runIdentity . compileTemplate "" $
    Data.Text.unlines
      [ "<nav id=\"TOC\" role=\"doc-toc\">",
        "  <strong>Contents</strong> <label for=\"contents\">⊕</label>",
        "  <input type=\"checkbox\" id=\"contents\">",
        "  $table-of-contents$",
        "</nav>",
        "<main>$body$</main>"
      ]

plainPostTemplate :: Text.Pandoc.Template Text
plainPostTemplate = either error id . runIdentity . compileTemplate "" $ "<main>$body$</main>"

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
