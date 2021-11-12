module Lab.BDBLab exposing (members, papers, memberLPC)

import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Shared
import DataSource.Glob as Glob
import DataSource.File
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode

import SiteMarkdown
import Lab.Lab as Lab

projectGMGC =
    { title = "Global Microbial Gene Catalog"
    , short_description = ""
    , long_description = ""
    }

paperSemiBin =
    { title = "SemiBin: Incorporating information from reference genomes with semi-supervised deep learning leads to better metagenomic assembled genomes (MAGs)"
    , slug = "2021_semibin"
    , short_description = "SemiBin is a better binner"
    , abstract = ""
    , status = Lab.Preprint
    , date = "2021"
    , year = 2021
    , doi = "https://doi.org/10.1101/2021.08.16.456517"
    , journal = "BioRxiv"
    , authors = [
            "Shaojun Pan",
            "Chengkai Zhu",
            "Xing-Ming Zhao",
            "Luis Pedro Coelho"]
    }

memberLPC =
    { name = "Luis Pedro Coelho"
    , title = "PI"
    , slug = "luispedrocoelho"
    , joined = "2018-09-01"
    , left = Nothing
    , short_bio = """
Luis Pedro Coelho leads the Big Data Biology Lab. He has background in both
computer science and computational biology."""
    , long_bio = """
Luis Pedro Coelho leads the Big Data Biology Lab. He has background in both
computer science and computational biology.

Personal website: [http://luispedro.org](http://luispedro.org)
"""
    , email = Just "luispedro@big-data-biology.org"
    , github = Just "luispedro"
    , twitter = Just "luispedrocoelho"
    , gscholar = Just "qTYua0cAAAAJ"
    , orcid = Just "0000-0002-9280-7885"
    , projects = [projectGMGC]
    , papers = [paperSemiBin]
    }

papers : DataSource (List Lab.Publication)
papers =
    SiteMarkdown.mdFiles "papers/"
        |> DataSource.map
            (List.map
                (\mdpage ->
                    DataSource.File.bodyWithFrontmatter
                        (readPaper mdpage.slug)
                        mdpage.path
                )
            )
        |> DataSource.resolve
        |> DataSource.map (List.sortBy .date)
        |> DataSource.map List.reverse


readPaper : String -> String -> Decoder Lab.Publication
readPaper slug abstract =
    Decode.decode Lab.Publication
        |> Decode.required "title" Decode.string
        |> Decode.hardcoded slug
        |> Decode.required "short_description" Decode.string
        |> Decode.hardcoded abstract
        |> Decode.hardcoded Lab.Published
        |> Decode.required "journal" Decode.string
        |> Decode.required "date" Decode.string
        |> Decode.required "year" Decode.int
        |> Decode.required "doi" Decode.string
        |> Decode.required "authors" (Decode.list Decode.string)

members : DataSource (List Lab.Member)
members =
    let
        enrich : List Lab.Member -> List Lab.Publication -> List Lab.Member
        enrich ms pubs = List.map (enrich1 pubs) ms

        enrich1 : List Lab.Publication -> Lab.Member -> Lab.Member
        enrich1 pubs m = { m | papers = List.filter (\p -> List.member m.name p.authors) pubs}
    in
    DataSource.map2 enrich
            membersNoPapers
            papers
membersNoPapers : DataSource (List Lab.Member)
membersNoPapers =
    SiteMarkdown.mdFiles "people/"
        |> DataSource.map
            (List.map
                (\mdpage ->
                    DataSource.File.bodyWithFrontmatter
                        (mdDecoder mdpage)
                        mdpage.path
                )
            )
        |> DataSource.resolve
        |> DataSource.map (List.sortBy .joined)


decodeOptional name
    = Decode.optional name (Decode.map Maybe.Just Decode.string) Nothing

mdDecoder : SiteMarkdown.MarkdownFile -> String -> Decoder Lab.Member
mdDecoder finfo body =
    Decode.decode Lab.Member
        |> Decode.required "name" Decode.string
        |> Decode.required "title" Decode.string
        |> Decode.required "joined" Decode.string
        |> decodeOptional "left"
        |> Decode.hardcoded finfo.slug
        |> Decode.required "short_bio" Decode.string
        |> Decode.hardcoded body
        |> decodeOptional "email"
        |> decodeOptional "github"
        |> decodeOptional "twitter"
        |> decodeOptional "gscholar"
        |> decodeOptional "orcid"
        |> Decode.hardcoded []
        |> Decode.hardcoded []
