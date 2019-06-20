require_relative "../../lib/ontologies_linked_data"
require_relative "../../config/config.rb"


##
# This class uses some basic convention to allow a set of rake tasks to create/delete sample data.
# USAGE:
#   To add a new object type, simply create two methods. For example, for object Person:
#      def create_people
#      def delete_people
#
#   The method should output a message stating what it's doing:
#      puts "Creating people..."
#      puts "Deleting people..."
#
#   The create/delete methods will be automatically invoked by the GenerateTestData::create and GenerateTestData::delete
#   methods, as they look for methods that start with "create_" and "delete_" respectively.
#
#   Data used in the creation of objects can be stored in class constants (see USERNAMES, ONT_FORMATS, etc).
module LinkedData
  module TestData
    class Generate
      USERNAMES = %w(emiko mina demetra noe anisa latoria nicholle amelia ona jacquelyne reginia dwana curt corrie percy audrie shizue nevada lorrine awilda elyse arlena monnie samual shon chantelle laurie clark raylene marcelino karry alejandra laurine yolando marine richie anderson samatha somer vincent porsche johnette daryl lindy brande bronwyn signe alessandra vernice kara)
      USER_EMAILS = %w(emiko@example.com mina@example.com demetra@example.com noe@example.com anisa@example.com latoria@example.com nicholle@example.com amelia@example.com ona@example.com jacquelyne@example.com reginia@example.com dwana@example.com curt@example.com corrie@example.com percy@example.com audrie@example.com shizue@example.com nevada@example.com lorrine@example.com awilda@example.com elyse@example.com arlena@example.com monnie@example.com samual@example.com shon@example.com chantelle@example.com laurie@example.com clark@example.com raylene@example.com marcelino@example.com karry@example.com alejandra@example.com laurine@example.com yolando@example.com marine@example.com richie@example.com anderson@example.com samatha@example.com somer@example.com vincent@example.com porsche@example.com johnette@example.com daryl@example.com lindy@example.com brande@example.com bronwyn@example.com signe@example.com alessandra@example.com vernice@example.com kara@example.com)
      ONT_FORMATS = %w(owl obo umls)
      ONT_NAMES = ["COSTART", "Physico-chemical process", "NMR-instrument specific component of metabolomics investigations", "HOM-ORTHO", "Cerebrotendinous xanthomatosis", "HOM-OSHPD-SC", "Ontology of Physics for Biology", "BioPAX", "Cell line ontology", "Ontology of Adverse Events", "HOM-ICD9_DXandVCODES_OSHPD", "Cell Culture Ontology", "HEALTH_INDICATORS", "Amphibian taxonomy", "Environment Ontology", "Role Ontology", "Systems Chemical Biology/Chemogenomics ", "Hymenoptera Anatomy Ontology", "NIF-Subcellular", "Exposure Ontology", "Molecule role (INOH Protein name/family name ontology)", "Plant Anatomy", "HOM-ORTHOSURGERY", "SemanticScience Integrated Ontology", "Plant Trait Ontology", "Enzyme Mechanism Ontology", "ABA Adult Mouse Brain", "Nursing Interventions Classification (NIC)", "Infectious Disease Ontology", "Subcellular Anatomy Ontology (SAO)", "MedlinePlus Health Topics", "eagle-i research resource ontology", "Gazetteer", "C. elegans development", "nhds", "Common Anatomy Reference Ontology", "thesaurus alternativa", "Cell Line Ontology", "HOM-UCARE", "Cardiac Electrophysiology Ontology", "HOM-ICD9PCS", "HOM-CHICMS", "Reproductive trait and phenotype ontology", "Common Terminology Criteria for Adverse Events", "Ontology for General Medical Science", "HOM-EPICI2B2TEST", "Software Ontology", "Natural Products Ontology", "Pathway ontology", "HOM-DXPROCS_MDCDRG", "HOM-DXVCODES2_OSHPD", "BD Test2", "Ontology of General Purpose Datatypes", "Master Drug Data Base", "PTSD", "Dictyostelium discoideum anatomy", "Ontologia proj alternativa", "Ontology of homology and related concepts in biology", "HOM-ICD9CM", "C. elegans phenotype", "Eurofut", "AI/RHEUM", "Immune Disorder Ontology", "Spatial Ontology", "General Formal Ontology", "Galen", "Mosquito insecticide resistance", "Variation Ontology", "Read Codes, Clinical Terms Version 3 (CTV3) ", "HOMERUN Ontology", "Translational Medicine Ontology", "Smoking Behavior Risk Ontology", "microRNA Ontology", "Neuro Behavior Ontology", "SoyOntology", "Gene Ontology", "Student Health Record", "Medical Subject Headings (MeSH)", "Mosquito gross anatomy", "HOM-I910TESTPLUS", "Breast tissue cell lines", "BioAssay Ontology", "Phenotype Fragment Ontology", "Ontology for MicroRNA Target Prediction", "Proteomics data and process provenance", "Neural Motor Recovery Ontology", "Plant Ontology", "BioTop", "Ontology for Newborn Screening and Translational Research", "Protein Ontology", "Human developmental anatomy, abstract version", "Fission Yeast Phenotype Ontology", "Pharmacovigilance Ontology", "Semantic Web for Earth and Environment Technology", "Ontology of Data Mining Investigations", "Anatomical Entity Ontology", "Phylogenetic Ontology", "vertebrate Homologous Organ Groups", "Breast Cancer Grading Ontology", "Medaka fish anatomy and development", "Bioinformatics operations, types of data, data formats, and topics", "HOM-PCSTEST", "Cell line ontology", "HOM-DATASOURCE_OSHPD", "Metagenome/Microbes Environmental Ontology", "Cereal Plant Development", "apollo-akesios", "Quadrupedal Gait", "Chemical Information Ontology", "Anatomical Therapeutic Chemical (ATC) Classification (OWL version)", "profectus.oshpd.installation", "HOM-NHDS", "NIF Cell", "Ontology for Genetic Interval", "PhenX Terms", "ICD-10-PCS", "Bleeding History Phenotype", "NIF Dysfunction", "ICD_Oncology-3", "Terminology for the Description of Dynamics", "HOM-ICU", "Ontology of Data Mining", "Traditional Medicine Constitution Value Set", "Basic Formal Ontology", "PROV-O", "Traditional Medicine Signs and Symptoms Value Set", "HOM-CHI", "CEEROntology", "MedDRA", "International Classification of  External Causes of Injuries", "International Classification of Functioning, Disability and Health (ICF)", "i2b2-patient_visit_dimensions", "Amino Acid", "Synapse Ontology", "HOM-HARVARD", "Bioinformatics Web Service Ontology", "PharmGKB-in-OWL", "VANDF", "The Biomedical Research Integrated Domain Group (BRIDG) model", "Dengue Fever Ontology", "Moja ontologija", "eVOC (Expressed Sequence Annotation for Humans)", "Terminology of Anatomy of Human Histology", "Darwin Core terms (test)", "NanoParticle Ontology", "Solanaceae Phenotype Ontology", "Drosophila gross anatomy", "Comparative Data Analysis Ontology", "Evidence codes", "Family Health History Ontology", "Mouse gross anatomy and development", "Units Ontology", "Foundational Model of Anatomy", "NIFSTD", "Human disease in Bioactivity", "PRotein Ontology", "Ontology of Language Disorder in Autism", "Xenopus anatomy and development", "Ontology of Clinical Research (OCRe)", "3 Digit Zipcodes", "C. elegans gross anatomy", "chi", "Darwin Core translations", "Bone Dysplasia Ontology", "Physical Medicine and Rehabilitation", "Wheat trait ", "Clinical Evaluation", "HOM-ORTHOCHILDTEST", "Neural-Immune Gene Ontology", "FlyBase Controlled Vocabulary", "PhenomeBLAST ontology", "African Traditional Medicine", "Cognitive Paradigm Ontology", "Zebrafish anatomy and development", "Multiple alignment", "Influenza Ontology", "Malaria Ontology", "SANOU", "Epoch Clinical Trial Ontologies", "HOM-DATASRC_TEST_new", "BOOK", "Parasite Experiment Ontology", "Leukocyte Surface Markers", "HOM-TESTKM", "GeoSpecies Ontology", "Lipid Ontology", "Mobile genetic element ontology", "Darwin Core terms (test)", "Non Randomized Controlled Trials Ontology", "Vertebrate Skeletal Anatomy Ontology", "Sleep Domain Ontology", "Pathogen transmission", "Body System", "Human developmental anatomy, timed version", "Computational Neuroscience Ontology", "Physico-chemical methods and properties", "Cognitive Atlas", "RadLex", "HOM-GLOB", "Mouse Experimental Design Ontology", "Maize gross anatomy", "HOM-OCCUPATION Ontology", "Rat Strain Ontology", "Syndromic Surveillance Ontology", "PhenX Toolkit ", "Crop Ontology", "Ontology for Drug Discovery Investigations", "CRISP Thesaurus, 2006", "Glycomics-Ontology", "Regulation of Gene Expression Ontolology", "Darwin Core Terms", "Kinetic Simulation Algorithm Ontology", "HOM-DATASRC_TEST_old", "Event (INOH pathway ontology)", "Human disease ontology", "Gastroenterology Clinical Cases ", "GBIF_test", "PKO_Re", "OBOE", "GPI Medications", "FDA Medical Devices (2010)", "Biomedical Resource Ontology", "Bilateria anatomy", "Pilot Ontology", "RxNORM", "HOM-ICD9CM-ECODES", "HOM-OSHPD", "Traditional Medicine Meridian Value Sets", "Metathesaurus CPT Hierarchical Terms", "Spider Ontology", "cms", "Platynereis stage ontology", "Ontology for Parasite LifeCycle", "BRENDA tissue / enzyme source", "RAPID Phenotype Ontology", "Cell Behavior Ontology", "Experimental Conditions Ontology", "Orphanet Ontology of Rare Diseases", "Human Phenotype Ontology", "Clinical Measurement Ontology", "yipd_test", "Physical Medicine and Rehabilitation", "Mass spectrometry", "Tissue Microarray Ontology", "Minimal anatomical terminology", "MGED Ontology", "Brucellosis Ontology", "Ontology of Medically Related Social Entities", "SANOU", "Basic Vertebrate Anatomy", "DIKB-Evidence-Ontology", "PMA 2010", "Dendritic cell", "Interaction Ontology", "ICPC-2 PLUS", "Drosophila development", "WHO Adverse Reaction Terminology", "Fly taxonomy", "BIRNLex", "HOM-CPT", "Interaction Network Ontology", "HOM-I9I10CMMOST", "Fungal gross anatomy", "Mouse pathology", "Tick gross anatomy", "HOM-UPENN_EPICMEDS", "uni-ece", "Teleost taxonomy", "Physician Data Query", "Habronattus courtship", "Computer-based Patient Record Ontology", "HOM-ICD9_PROCS_OSHPD", "Robert Hoehndorf's Version of MeSH", "Gene Regulation Ontology", "Measurement Method Ontology", "MaHCO - An MHC Ontology", "Gene Ontology Extension", "Neglected Tropical Disease Ontology (NTDO)", "Vaccine Ontology", "Diagnostic Ontology", "Neomark Oral Cancer Ontology", "Protein-protein interaction", "Yeast phenotypes", "SNOMED Clinical Terms", "Teleost Anatomy Ontology", "linkingkin2pep", "Epilepsy", "Plant environmental conditions", "HOM-DATASRC-ORTHO", "shrine", "Neomark Oral Cancer-Centred Ontology", "International Classification for Nursing Practice", "Cell Phenotype Ontology", "Time Event Ontology", "Biological imaging methods", "Sample processing and separation techniques", "Logical Observation Identifier Names and Codes", "Mouse adult gross anatomy", "Ontology of Geographical Region", "Cell type", "National Drug Data File", "PHARE", "Electrocardiography Ontology", "Hewan Invertebrata", "OBO relationship types", "RNA ontology", "Genomic Clinical Decision Support - Genomic CDS", "MetaCT Ontology", "ICD10CM", "Chemical entities of biological interest", "Cancer Research and Management ACGT Master Ontology", "CAO", "HOM-I9toI10PCS-Maps", "Regulation of Transcription Ontolology", "Mental Functioning Ontology", "InformedConsentPermissionOntology", "ThomCan: Upper-level Cancer Ontology ", "Terminological and ontological Knowledge resources", "BioPortal Metadata", "Gene Expression Ontology", "Amphibian gross anatomy", "Randomized Controlled Trials (RCT) Ontology", "IMGT-ONTOLOGY", "Ontology of Experimental Variables and Values", "HOM-EPIC", "i2b2 Labs", "Cell Cycle Ontology", "Situation-Based Access Control", "OntoPneumo", "HOM-CLINIC Ontology", "Fanconi Anemia (FA) Ontology", "HOM-Transplant Ontology", "gs1", "SysMO-JERM", "HOM_MDCs-DRGS", "Mammalian phenotype", "thesaurus", "International Classification of Diseases", "HOM-PROCS2_OSHPD", "Plant Structure Development Stage", "HOM-DATASOURCE_EPIC", "Cereal plant gross anatomy", "CareLex", "NCBI organismal classification", "Animal natural history and life history", "Uber anatomy ontology", "Protein modification", "National Drug File", "Units of measurement", "HOM-DEMOGR", "HOM-ORTHOTEST", "HOM_ElixhauserScores", "XEML Environment Ontology", "Emotion Ontology", "Terminology of Anatomy of Human Embryology", "SNP-Ontology", "Quantitative Imaging Biomarker Ontology", "Health Level Seven", "Bio-health ontological knowledge base- cystic fibrosis", "OBOE SBC", "Symptom Ontology", "HOM-I9TO10MAPS", "HOM-OSHPD_UseCase", "Adverse Event Reporting ontology", "MIxS Controlled Vocabularies", "Ontology for Biomedical Investigations", "Ascomycete phenotype ontology", "Healthcare Common Procedure Coding System", "ICPS Network", "HOM-TEST", "PhysicalFields", "Pseudogene", "Population and Community Ontology", "HOM-MEDABBS", "Human developmental anatomy, abstract version, v2", "HOM-DATASOURCE_OSHPDSC", "HUGO", "Suggested Ontology for Pharmacogenomics", "oshpd", "Systems Biology", "Sequence types and features", "Ontology of Glucose Metabolism Disorder", "HOM-CMS", "NCI Thesaurus", "Host Pathogen Interactions Ontology", "General Formal Ontology: Biology", "GeneTrial Ontology", "Proteomics Pipeline Infrastructure for CPTAC", "Gene Regulation Ontology", "Vertebrate Trait Ontology", "ICD10", "Ontology for disease genetic investigation", "Pediatric Terminology", "Current Procedural Terminology", "Skin Physiology Ontology", "Phenotypic quality", "HOM-ICD910PCS-150", "Loggerhead nesting", "Quantities, Units, Dimensions and Types", "HOM-MDCDRG", "Traditional Medicine Other Factors Value Set", "BioModels Ontology", "International Classification of Primary Care", "Web-Service Interaction Ontology", "VIVO", "Taxonomic rank vocabulary", "Online Mendelian Inheritance in Man", "DermLex: The Dermatology Lexicon", "Cancer Chemoprevention Ontology", "Experimental Factor Ontology", "Neural ElectroMagnetic Ontologies", "Vital Sign Ontology", "Information Artifact Ontology"]
      ONT_ACRONYMS = ["CST-API-TST", "REX-API-TST", "NMR-API-TST", "HOM-ORTHO-API-TST", "CTX-API-TST", "HOM-OSHPD-SC-API-TST", "OPB.properties-API-TST", "BP-API-TST", "MCCL-API-TST", "OAE-API-TST", "HOM-VCODES_OSHPD-API-TST", "CCONT-API-TST", "HLTH_INDICS-API-TST", "ATO-API-TST", "ENVO-API-TST", "RoleO-API-TST", "Chem2Bio2OWL-API-TST", "HAO-API-TST", "NIF-Subcell-API-TST", "ExO-API-TST", "IMR-API-TST", "PO_PAE-API-TST", "HOM-ORTHOSURG-API-TST", "SIO-API-TST", "TO-API-TST", "EMO-API-TST", "ABA-API-TST", "NIC-API-TST", "IDO-API-TST", "SAO-API-TST", "MEDLINEPLUS-API-TST", "ERO-API-TST", "GAZ-API-TST", "WBls-API-TST", "nhds.13896-API-TST", "CARO-API-TST", "thealternativa-API-TST", "CLO-API-TST", "HOM-UCARE-API-TST", "EP-API-TST", "HOM-I9PCS-API-TST", "HOM-CHICMS-API-TST", "REPO-API-TST", "CTCAE-API-TST", "OGMS-API-TST", "HOM-EPICI2B2-API-TST", "SWO-API-TST", "NatPrO-API-TST", "PW-API-TST", "HOM-DXPCS_MDCDRG-API-TST", "HOM-DXVCODES2-API-TST", "bd-test2-API-TST", "OntoDT-API-TST", "MDDB-API-TST", "PTSD-API-TST", "DDANAT-API-TST", "ontologia-API-TST", "HOM-API-TST", "HOM-I9CM-API-TST", "WBPhenotype-API-TST", "eufut-API-TST", "AIR-API-TST", "ImmDis-API-TST", "BSPO-API-TST", "GFO-API-TST", "GALEN-API-TST", "MIRO-API-TST", "VariO-API-TST", "RCD-API-TST", "HOMERUN-API-TST", "TMO-API-TST", "SBRO-API-TST", "miRNAO-API-TST", "NBO-API-TST", "SOY-API-TST", "GO-API-TST", "SHR-API-TST", "MSH-API-TST", "TGMA-API-TST", "HOM-I910TESTPLUS-API-TST", "MCBCC-API-TST", "BAO-API-TST", "PFO-API-TST", "OMIT-API-TST", "ProPreO-API-TST", "NeuMORE-API-TST", "PO-API-TST", "BT-API-TST", "ONSTR-API-TST", "pro-ont-API-TST", "EHDAA-API-TST", "FYPO-API-TST", "PVOnto-API-TST", "SWEET-API-TST", "OntoDM-KDD-API-TST", "AEO-API-TST", "PhylOnt-API-TST", "vHOG-API-TST", "BCGO-API-TST", "MFO-API-TST", "EDAM-API-TST", "HOM-PCSTEST-API-TST", "MCCL-API-TST", "HOM-SRCE_OSHPD-API-TST", "MEO-API-TST", "GRO_CPD-API-TST", "apollo-API-TST", "CAMRQ-API-TST", "CHEMINF-API-TST", "ATC-API-TST", "profectus.oshpd.installation.5931-API-TST", "HOM-NHDS-API-TST", "NIF_Cell-API-TST", "OGI-API-TST", "PhenX-API-TST", "ICD10PCS-API-TST", "BHO-API-TST", "NIF_Dysfunction-API-TST", "ICDO3-API-TST", "TEDDY-API-TST", "HOM-ICU-API-TST", "OntoDM-API-TST", "TM-CONST-API-TST", "BFO-API-TST", "prov-o-API-TST", "TM-SIGNS-AND-SYMPTS-API-TST", "HOM-CHI-API-TST", "CEEROntology-API-TST", "MDR-API-TST", "ICECI-API-TST", "ICF-API-TST", "i2b2-patvisdims-API-TST", "amino-acid-API-TST", "SYN-API-TST", "HOM_HARVARD-API-TST", "OBIws-API-TST", "pharmgkb-owl-API-TST", "VANDF-API-TST", "BRIDG-API-TST", "IDODEN-API-TST", "dsfs-API-TST", "EV-API-TST", "TAHH-API-TST", "DwC_test-API-TST", "NPO-API-TST", "SPTO-API-TST", "FBbt-API-TST", "CDAO-API-TST", "ECO-API-TST", "FHHO-API-TST", "EMAP-API-TST", "UnitsOntology-API-TST", "FMA-API-TST", "nif-API-TST", "TestHDB-API-TST", "PR-API-TST", "LDA-API-TST", "XAO-API-TST", "OCRe-API-TST", "ZIP3-API-TST", "WBbt-API-TST", "chi.63559-API-TST", "DwC_translations-API-TST", "BDO-API-TST", "PhyMeRe-API-TST", "CO_Wheat-API-TST", "Clinical_Eval-API-TST", "HOM-OCHILDTEST-API-TST", "NIGO-API-TST", "FBcv-API-TST", "phenomeblast-owl-API-TST", "ATMO-API-TST", "CogPO-API-TST", "ZFA-API-TST", "MAO-API-TST", "FLU-API-TST", "IDOMAL-API-TST", "OntoMA-API-TST", "ClinicalTrialOntology-API-TST", "HOM-DATASRCTESTn-API-TST", "BO-API-TST", "PEO-API-TST", "LSM-API-TST", "HOM-TESTKM-API-TST", "geospecies-API-TST", "LiPrO-API-TST", "MeGO-API-TST", "DwC_test-API-TST", "NonRCTOntology-API-TST", "VSAO-API-TST", "SDO-API-TST", "TRANS-API-TST", "bodysystem-API-TST", "EHDA-API-TST", "CNO-API-TST", "FIX-API-TST", "cogat-API-TST", "RID-API-TST", "HOM-GLOB-API-TST", "MEDO-API-TST", "ZEA-API-TST", "HOM-OCC-API-TST", "RS-API-TST", "SSO-API-TST", "PhenXTK-API-TST", "CO-API-TST", "DDI-API-TST", "CSP-API-TST", "GlycO-API-TST", "ReXO-API-TST", "DwC-API-TST", "KiSAO-API-TST", "HOM-DATSRCTESTo-API-TST", "IEV-API-TST", "DOID-API-TST", "GCC-API-TST", "DC_test-API-TST", "PKO-API-TST", "OBOE-API-TST", "GPI-API-TST", "FDA-MedDevice-API-TST", "BRO-API-TST", "BILA-API-TST", "POL-API-TST", "RXNORM-API-TST", "HOM-I9-ECODES-API-TST", "HOM-OSHPD-API-TST", "TM-MER-API-TST", "MTHCH-API-TST", "SPD-API-TST", "cms.36739-API-TST", "PD_ST-API-TST", "OPL-API-TST", "BTO-API-TST", "RPO-API-TST", "CBO-API-TST", "XCO-API-TST", "OntoOrpha-API-TST", "HP-API-TST", "CMO-API-TST", "yipd-API-TST", "PMR-API-TST", "MS-API-TST", "TMA-API-TST", "MAT-API-TST", "MO-API-TST", "IDOBRU-API-TST", "OMRSE-API-TST", "OntoMA-API-TST", "basic-vertebrate-gross-anatomy-API-TST", "dikb-evidence-API-TST", "pma-API-TST", "DC_CL-API-TST", "IxnO-API-TST", "ICPC2P-API-TST", "FBdv-API-TST", "WHO-API-TST", "FBsp-API-TST", "birnlex-API-TST", "HOM-CPT-API-TST", "INO-API-TST", "I9I10CMMOST-API-TST", "FAO-API-TST", "MPATH-API-TST", "TADS-API-TST", "HOM-UPENNMEDS-API-TST", "uni-ece-API-TST", "TTO-API-TST", "PDQ-API-TST", "HC-API-TST", "CPR-API-TST", "HOM-PCS_OSHPD-API-TST", "RH-MESH-API-TST", "BOOTStrep-API-TST", "MMO-API-TST", "MHC-API-TST", "GO-EXT-API-TST", "NTDO-API-TST", "VO-API-TST", "DiagnosticOnt-API-TST", "NeoMark-API-TST", "MI-API-TST", "YPO-API-TST", "SNOMEDCT-API-TST", "TAO-API-TST", "k2p-API-TST", "EpilepOnto-API-TST", "EO-API-TST", "DATASRC-ORTHO-API-TST", "shrine.20676-API-TST", "NeoMarkOntology-API-TST", "ICNP-API-TST", "CPO-API-TST", "TEO-API-TST", "FBbi-API-TST", "SEP-API-TST", "LNC-API-TST", "MA-API-TST", "OGR-API-TST", "CL-API-TST", "NDDF-API-TST", "PHARE-API-TST", "ECG-API-TST", "invertebrata-API-TST", "OBO_REL-API-TST", "RNAO-API-TST", "Genomic-CDS-API-TST", "MetaCT-API-TST", "ICD10CM-API-TST", "CHEBI-API-TST", "ACGT-API-TST", "CAO-API-TST", "ICD9toICD10PCS-API-TST", "ReTO-API-TST", "MF-API-TST", "ConsentOntology-API-TST", "ThomCan-API-TST", "TOK-API-TST", "BPMetadata-API-TST", "GeXO-API-TST", "AAO-API-TST", "RCTOntology-API-TST", "IMGT-API-TST", "OoEVV-API-TST", "HOM-EPIC-API-TST", "LOINC-API-TST", "CCO-API-TST", "SitBAC-API-TST", "OntoPneumo-API-TST", "HOM-CLINIC-API-TST", "IFAR-API-TST", "HOM-TX-API-TST", "gs1-API-TST", "JERM-API-TST", "HOM_MDCs_DRGs-API-TST", "MP-API-TST", "thesaurus-API-TST", "ICD9CM-API-TST", "HOM-PROCS2-API-TST", "PO_PSDS-API-TST", "EPIC-SRC-API-TST", "GRO_CPGA-API-TST", "CareLex-API-TST", "NCBITaxon-API-TST", "ADW-API-TST", "UBERON-API-TST", "MOD-API-TST", "NDFRT-API-TST", "UO-API-TST", "HOM-DEMOGR-API-TST", "HOM-ORTHOTEST-API-TST", "HOM_EHS-API-TST", "XeO-API-TST", "MFOEM-API-TST", "TAHE-API-TST", "SNPO-API-TST", "QIBO-API-TST", "HL7-API-TST", "OntoKBCF-API-TST", "oboe-sbc-API-TST", "SYMP-API-TST", "HOM-I9I10MAPS-API-TST", "HOM-OSHPD_UseCas-API-TST", "AERO-API-TST", "MCV-API-TST", "OBI-API-TST", "APO-API-TST", "HCPCS-API-TST", "ICPS-API-TST", "HOM-TEST-API-TST", "Field-API-TST", "pseudo-API-TST", "pco-API-TST", "HOM-MEDABBS-API-TST", "EHDAA2-API-TST", "SRC-OSHPDSC-API-TST", "HUGO-API-TST", "SOPHARM-API-TST", "oshpd.33038-API-TST", "SBO-API-TST", "SO-API-TST", "OGMD-API-TST", "HOM-CMS-API-TST", "NCIt-API-TST", "HPIO-API-TST", "GFO-Bio-API-TST", "GeneTrial-API-TST", "CPTAC-API-TST", "GRO-API-TST", "VT-API-TST", "ICD10-API-TST", "ODGI-API-TST", "PedTerm-API-TST", "CPT-API-TST", "SPO-API-TST", "PATO-API-TST", "HOMICD910PCS-150-API-TST", "LHN-API-TST", "QUDT-API-TST", "HOM-MDCDRG-API-TST", "TM-OTHER-FACTORS-API-TST", "BioModels-API-TST", "ICPC-API-TST", "WSIO-API-TST", "vivo-API-TST", "TAXRANK-API-TST", "OMIM-API-TST", "DermLex-API-TST", "CanCO-API-TST", "EFO-API-TST", "NEMO-API-TST", "VSO-API-TST", "IAO-API-TST"]

      def self.create
        puts "Creating all..."
        methods = self.public_methods(false)
        methods.each do |method|
          self.send(method) if method.to_s.start_with?("create_")
        end
      end

      def self.delete
        puts "Deleting all..."
        methods = self.public_methods(false)
        methods.each do |method|
          self.send(method) if method.to_s.start_with?("delete_")
        end
      end

      def self.create_users
        puts "Creating users..."
        USERNAMES.each_with_index do |name, index|
          u = LinkedData::Models::User.new(username: name, email: USER_EMAILS[index], password: "test+pass")
          u.save if u.valid?
        end
      end

      def self.delete_users
        puts "Deleting users..."
        USERNAMES.each do |name|
          u = LinkedData::Models::User.find(name)
          u.delete unless u.nil?
        end
      end

      def self.delete_ontology_formats
        puts "Deleting ontology formats..."
        ONT_FORMATS.each do |format|
          of = LinkedData::Models::OntologyFormat.find(format.upcase).to_a.first
          of.delete unless of.nil?
        end
      end

      def self.create_ontologies(limit = 50)
        puts "Creating ontology metadata..."
        user_count = LinkedData::Models::User.where.all.length
        if user_count < 50
          puts "#{user_count} users in the system ... not enough"
          self.create_users
        end

        contact_name = "Sheila"
        contact_email = "sheila@example.org"
        contact = LinkedData::Models::Contact.where(name: contact_name, email: contact_email).to_a
        if contact.empty?
          contact = LinkedData::Models::Contact.new(name: contact_name, email: contact_email)
          contact = [contact.save]
        end

        count = 0
        ONT_ACRONYMS.each_with_index do |acronym, index|
          break if count >= limit

          name = ONT_NAMES[index]

          o = LinkedData::Models::Ontology.new({
            acronym: acronym,
            administeredBy: LinkedData::Models::User.find(USERNAMES.shuffle.first).to_a,
            name: name
          })
          o.save unless o.exist?

          o = LinkedData::Models::Ontology.find(o.acronym.to_s).include(:acronym, :submissions).to_a[0] unless o.persistent?

          os = LinkedData::Models::OntologySubmission.new({
            ontology: o,
            hasOntologyLanguage: LinkedData::Models::OntologyFormat.find(ONT_FORMATS.shuffle.first.upcase).first,
            summaryOnly: true,
            submissionId: o.next_submission_id,
            contact: contact,
            released: DateTime.now - 3
          })
          os.save unless os.exist?
          count += 1
        end
      end

      def self.delete_ontologies
        puts "Deleting ontology metadata..."
        ONT_ACRONYMS.each do |acronym|
          o = LinkedData::Models::Ontology.find(acronym).first
          o.delete unless o.nil?

          # os = LinkedData::Models::OntologySubmission.where(ontology: {acronym: acronym})
          # os.each do |s|
          #   s.delete unless s.nil?
          # end
        end
      end

    end
  end
end
