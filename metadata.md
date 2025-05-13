# Description of bacteria.db
The relational database bacteria.db is implemented using SQLite and contains normalized tables that store information derived from a systematic literature review focused on bacterial diversity associated with bats. The schema includes four primary tables with defined foreign key relationships to support structured querying and data integration.

## 1. articles_filtered
This table stores bibliographic records of peer-reviewed articles selected through a predefined search strategy. Each entry corresponds to a unique publication and serves as the central reference for all included studies. It is linked to downstream tables via article identifiers.

### Fields:
idarticle: Primary key (unique identifier for each article)
title: Title of the publication
source: Database or repository source (e.g., PubMed, Europe PMC)
doi: Digital Object Identifier
abstract: Abstract text
This table provides access to basic bibliographic metadata and is used to link publications with methodological and biological data stored in other tables.

## 2. metadata
Contains methodological and experimental metadata extracted from each selected article. Designed to enable comparative analysis based on variability in research methods across studies.

### Fields:
id_article: Foreign key referencing articles_filtered(idarticle)
amplicon_sequencing: Binary flag (yes/no) indicating use of amplicon sequencing
shotgun_sequencing: Binary flag indicating use of shotgun sequencing
culturomics: Binary flag indicating use of culturomics approaches
maldi: Binary flag indicating use of MALDI-TOF MS
illumina: Binary flag indicating use of Illumina sequencing
OxfordNanopore: Binary flag indicating use of Oxford Nanopore sequencing
Ion_Torrent: Binary flag indicating use of Ion Torrent sequencing
Roche: Binary flag indicating use of Roche 454 sequencing
PacBio: Binary flag indicating use of PacBio sequencing
PCR: Binary flag indicating use of PCR-based techniques
country: Country where bat samples were collected
guano: Binary flag indicating sampling from guano
gut: Binary flag indicating sampling from gut
oral: Binary flag indicating oral cavity sampling
rectal: Binary flag indicating rectal sampling
skin: Binary flag indicating skin sampling
blood: Binary flag indicating blood sampling
intern_organ: Binary flag indicating internal organ sampling
Urogenital: Binary flag indicating urogenital tract sampling
This table allows filtering and comparison of studies by methodology, geographic origin, and sample type.

## 3. articles1 (to articles47)
Each table (from articles1 to articles47) corresponds to one of the selected articles and stores taxonomic records of bacterial taxa identified in that specific study.

Note: This denormalized structure was chosen to simplify data entry from heterogeneous sources. Future versions may consolidate these into a single table with an article identifier. 

### Fields:
id: Unique record identifier
article: Foreign key referencing metadata(id_article) (links to the corresponding article)
bat_sp: Scientific name of the bat species evaluated
bacteria_sp: Scientific name of the bacteria reported in the article
These tables allow querying bacterial diversity reported across studies and linking microbial taxa to specific bat species and methodologies.

## Schema Relationships
articles_filtered acts as the core entity.
metadata links to articles_filtered via id_article.
Each articlesX table links to metadata via article.
