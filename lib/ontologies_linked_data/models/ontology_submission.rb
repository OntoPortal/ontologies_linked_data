require 'net/ftp'
require 'net/http'
require 'uri'
require 'open-uri'
require 'cgi'
require 'benchmark'
require 'csv'
require 'fileutils'

module LinkedData
  module Models

    class OntologySubmission < LinkedData::Models::Base

      FILES_TO_DELETE = ['labels.ttl', 'mappings.ttl', 'obsolete.ttl', 'owlapi.xrdf', 'errors.log']

      model :ontology_submission, name_with: lambda { |s| submission_id_generator(s) }
      attribute :submissionId, enforce: [:integer, :existence]

      # Configurable properties for processing
      attribute :prefLabelProperty, enforce: [:uri]
      attribute :definitionProperty, enforce: [:uri]
      attribute :synonymProperty, enforce: [:uri]
      attribute :authorProperty, enforce: [:uri]
      attribute :classType, enforce: [:uri]
      attribute :hierarchyProperty, enforce: [:uri]
      attribute :obsoleteProperty, enforce: [:uri]
      attribute :obsoleteParent, enforce: [:uri]

      # Ontology metadata
      attribute :hasOntologyLanguage, namespace: :omv, enforce: [:existence, :ontology_format]
      attribute :homepage
      # attribute :homepage, namespace: :foaf
      #attribute :publication #COMMENTED BY ECOPORTAL
      attribute :publication, enforce: [:existence] #ECOPORTAL URL for DATACITE DOI REQUEST IS MANDATORY
      attribute :uri, namespace: :omv
      attribute :naturalLanguage, namespace: :omv
      attribute :documentation, namespace: :omv
      attribute :version, namespace: :omv
      attribute :creationDate, namespace: :omv, enforce: [:date_time], default: lambda { |record| DateTime.now }
      attribute :description, namespace: :omv
      attribute :status, namespace: :omv
      attribute :contact, enforce: [:existence, :contact, :list]
      # attribute :released, enforce: [:date_time, :existence]

      # Internal values for parsing - not definitive
      attribute :uploadFilePath
      attribute :diffFilePath
      attribute :masterFileName
      attribute :submissionStatus, enforce: [:submission_status, :list], default: lambda { |record| [LinkedData::Models::SubmissionStatus.find("UPLOADED").first] }
      attribute :missingImports, enforce: [:list]

      # URI for pulling ontology
      attribute :pullLocation, enforce: [:uri]

      # Link to ontology
      attribute :ontology, enforce: [:existence, :ontology]

      # Ecoportal - BEGIN
      attribute :identifierRequests, inverse: {on: :identifier_request, attribute: :submission}

      attribute :identifier, namespace: :datacite, extractedMetadata: true, metadataMappings: ["dc:identifier", "skos:notation", "adms:identifier"],
      helpText: "An unambiguous reference to the ontology. Use the ontology URI if not provided in the ontology metadata."

      attribute :identifierType, namespace: :datacite, extractedMetadata: true, metadataMappings: ["dc:identifier", "dct:identifier"]

      attribute :released, enforce: [:date_time, :existence], extractedMetadata: true, label: "Release date", helpText: "Date of the ontology release.",
      metadataMappings: ["omv:creationDate", "dc:date", "dct:date", "dct:issued", "mod:creationDate", "doap:created", "schema:dateCreated",
        "prov:generatedAtTime", "pav:createdOn", "pav:authoredOn", "pav:contributedOn", "oboInOwl:date", "oboInOwl:hasDate"]

      attribute :creators, namespace: :datacite, enforce: [:existence, :creator, :list], extractedMetadata: true, label: "Creators",
      metadataMappings: ["dc:creator", "dct:creator", "omv:hasCreator", "foaf:maker", "prov:wasAttributedTo", "doap:maintainer", "pav:authoredBy", "pav:createdBy", "schema:author", "schema:creator"],
      helpText: "The main researchers involved working on the data, or the authors of the publication in priority order."

      attribute :titles, namespace: :datacite, enforce: [:existence, :title, :list], extractedMetadata: true, label: "Titles",
      metadataMappings: ["dc:title", "dcterms:title"],
      helpText: "A name or title by which a resource is known. May be the title of a dataset or the name of a piece of software."
      
      #attribute :cancellami, namespace: :datacite, enforce: [:existence, :creatorIdentifier, :list]
      
      attribute :publisher, namespace: :datacite, extractedMetadata: true, metadataMappings: ["dc:publisher", "dct:publisher", "schema:publisher"], display: "license",
      helpText: "An entity responsible for making the ontology available."

      #Ecoportal: il valore di questo attributo deve essere ricavato dal campo obbligatorio ':released'. E' il caso di aggiungere
      # una nuova opzione, ad esempio calculatedFrom: :released, operation: :yearFromDate
      attribute :publicationYear, namespace: :datacite, extractedMetadata: true, metadataMappings: ["dc:date", "dcterms:issued"]

      attribute :resourceType, namespace: :datacite, extractedMetadata: true, metadataMappings: ["dc:type", "dct:type"],
      helpText: "The nature of the content of the ontology.&lt;br&gt;Properties taken from &lt;a target=&quot;_blank&quot; href=&quot;http://wiki.dublincore.org/index.php/NKOS_Vocabularies#KOS_Types_Vocabulary&quot;&gt;DCMI KOS type vocabularies&lt;/a&gt;",
      enforcedValues: {
          "http://omv.ontoware.org/2005/05/ontology#ApplicationOntology" => "Application Ontology",
          "http://omv.ontoware.org/2005/05/ontology#CoreOntology" => "Core Ontology",
          "http://omv.ontoware.org/2005/05/ontology#DomainOntology" => "Domain Ontology",
          "http://omv.ontoware.org/2005/05/ontology#TaskOntology" => "Task Ontology",
          "http://omv.ontoware.org/2005/05/ontology#UpperLevelOntology" => "Upper Level Ontology",
          "http://omv.ontoware.org/2005/05/ontology#Vocabulary" => "Vocabulary"
      }

      #Ecoportal: prevede una controlled list; nel nostro caso dovrebbe essere sempre impostato al valore "dataset".
      # dovrebbe essese aggiunta l'opzione stringValue: :dataset
      attribute :resourceTypeGeneral,  extractedMetadata: true, metadataMappings: ["dc:type", "dct:type"], namespace: :datacite 
      
      # attribute :creator
      # Ecoportal - END


      #Link to metrics
      attribute :metrics, enforce: [:metrics]

      # Hypermedia settings
      embed :contact, :ontology, :creators, :titles #, :creators => [:affiliations, :creatorIdentifiers]
      embed_values :submissionStatus => [:code], :hasOntologyLanguage => [:acronym] #, :creators => [:affiliations => [:affiliationIdentifierScheme, :affiliationIdentifier, :affiliation]]
      serialize_default :contact, :ontology, :hasOntologyLanguage, :released, :creationDate, :homepage,
                        :publication, :documentation, :version, :description, :status, :submissionId, :creators, :titles,
                        :identifier, :identifierType, :publisher, :publicationYear, :resourceType, :resourceTypeGeneral, :identifierRequests

      # Links
      links_load :submissionId, ontology: [:acronym]
      link_to LinkedData::Hypermedia::Link.new("metrics", lambda {|s| "ontologies/#{s.ontology.acronym}/submissions/#{s.submissionId}/metrics"}, self.type_uri)
              LinkedData::Hypermedia::Link.new("download", lambda {|s| "ontologies/#{s.ontology.acronym}/submissions/#{s.submissionId}/download"}, self.type_uri)

      # HTTP Cache settings
      cache_timeout 3600
      cache_segment_instance lambda {|sub| segment_instance(sub)}
      cache_segment_keys [:ontology_submission]
      cache_load ontology: [:acronym]

      # Access control
      read_restriction_based_on lambda {|sub| sub.ontology}
      access_control_load ontology: [:administeredBy, :acl, :viewingRestriction]

      def self.segment_instance(sub)
        sub.bring(:ontology) unless sub.loaded_attributes.include?(:ontology)
        sub.ontology.bring(:acronym) unless sub.ontology.loaded_attributes.include?(:acronym)
        [sub.ontology.acronym] rescue []
      end

      def self.submission_id_generator(ss)
        if !ss.ontology.loaded_attributes.include?(:acronym)
          ss.ontology.bring(:acronym)
        end
        if ss.ontology.acronym.nil?
          raise ArgumentError, "Submission cannot be saved if ontology does not have acronym"
        end
        return RDF::URI.new(
          "#{(Goo.id_prefix)}ontologies/#{CGI.escape(ss.ontology.acronym.to_s)}/submissions/#{ss.submissionId.to_s}"
        )
      end

      def self.copy_file_repository(acronym, submissionId, src, filename = nil)
        path_to_repo = File.join([LinkedData.settings.repository_folder, acronym.to_s, submissionId.to_s])
        name = filename || File.basename(File.new(src).path)
        # THIS LOGGER IS JUST FOR DEBUG - remove after NCBO-795 is closed
        logger = Logger.new(Dir.pwd + "/create_permissions.log")
        if not Dir.exist? path_to_repo
          FileUtils.mkdir_p path_to_repo
          logger.debug("Dir created #{path_to_repo} | #{"%o" % File.stat(path_to_repo).mode} | umask: #{File.umask}") # NCBO-795
        end
        dst = File.join([path_to_repo, name])
        FileUtils.copy(src, dst)
        logger.debug("File created #{dst} | #{"%o" % File.stat(dst).mode} | umask: #{File.umask}") # NCBO-795
        if not File.exist? dst
          raise Exception, "Unable to copy #{src} to #{dst}"
        end
        return dst
      end

      def valid?
        valid_result = super
        return false unless valid_result
        sc = self.sanity_check
        return valid_result && sc
      end

      def sanity_check
        self.bring(:ontology) if self.bring?(:ontology)
        self.ontology.bring(:summaryOnly) if self.ontology.bring?(:summaryOnly)
        self.bring(:uploadFilePath) if self.bring?(:uploadFilePath)
        self.bring(:pullLocation) if self.bring?(:pullLocation)
        self.bring(:masterFileName) if self.bring?(:masterFileName)
        self.bring(:submissionStatus) if self.bring?(:submissionStatus)

        if self.submissionStatus
          self.submissionStatus.each do |st|
            st.bring(:code) if st.bring?(:code)
          end
        end

        # TODO: this code was added to deal with intermittent issues with 4store, where the error:
        # Attribute `summaryOnly` is not loaded for http://data.bioontology.org/ontologies/GPI
        # was thrown for no apparent reason!!!
        sum_only = nil

        begin
          sum_only = self.ontology.summaryOnly
        rescue Exception => e
          i = 0
          num_calls = 3
          sum_only = nil

          while sum_only.nil? && i < num_calls do
            i += 1
            puts "Exception while getting summaryOnly for #{self.id.to_s}. Retrying #{i} times..."
            sleep(1)

            begin
              self.ontology.bring(:summaryOnly)
              sum_only = self.ontology.summaryOnly
              puts "Success getting summaryOnly for #{self.id.to_s} after retrying #{i} times..."
            rescue Exception => e1
              sum_only = nil

              if i == num_calls
                raise $!, "#{$!} after retrying #{i} times...", $!.backtrace
              end
            end
          end
        end

        if sum_only == true || self.archived?
          return true
        elsif self.uploadFilePath.nil? && self.pullLocation.nil?
          self.errors[:uploadFilePath] = ["In non-summary only submissions a data file or url must be provided."]
          return false
        elsif self.pullLocation
          self.errors[:pullLocation] = ["File at #{self.pullLocation.to_s} does not exist"]
          if self.uploadFilePath.nil?
            return remote_file_exists?(self.pullLocation.to_s)
          end
          return true
        end

        zip = LinkedData::Utils::FileHelpers.zip?(self.uploadFilePath)
        files =  LinkedData::Utils::FileHelpers.files_from_zip(self.uploadFilePath) if zip

        if not zip and self.masterFileName.nil?
          return true
        elsif zip and files.length == 1
          self.masterFileName = files.first
          return true
        elsif zip && self.masterFileName.nil? && LinkedData::Utils::FileHelpers.automaster?(self.uploadFilePath, self.hasOntologyLanguage.file_extension)
          self.masterFileName = LinkedData::Utils::FileHelpers.automaster(self.uploadFilePath, self.hasOntologyLanguage.file_extension)
          return true
        elsif zip and self.masterFileName.nil?
          #zip and masterFileName not set. The user has to choose.
          if self.errors[:uploadFilePath].nil?
            self.errors[:uploadFilePath] = []
          end

          #check for duplicated names
          repeated_names =  LinkedData::Utils::FileHelpers.repeated_names_in_file_list(files)
          if repeated_names.length > 0
            names = repeated_names.keys.to_s
            self.errors[:uploadFilePath] <<
            "Zip file contains file names (#{names}) in more than one folder."
            return false
          end

          #error message with options to choose from.
          self.errors[:uploadFilePath] << {
            :message => "Zip file detected, choose the master file.", :options => files }
          return false

        elsif zip and not self.masterFileName.nil?
          #if zip and the user chose a file then we make sure the file is in the list.
          files =  LinkedData::Utils::FileHelpers.files_from_zip(self.uploadFilePath)
          if not files.include? self.masterFileName
            if self.errors[:uploadFilePath].nil?
              self.errors[:uploadFilePath] = []
              self.errors[:uploadFilePath] << {
                :message =>
              "The selected file `#{self.masterFileName}` is not included in the zip file",
                :options => files }
            end
          end
        end
        return true
      end

      def data_folder
        bring(:ontology) if bring?(:ontology)
        self.ontology.bring(:acronym) if self.ontology.bring?(:acronym)
        bring(:submissionId) if bring?(:submissionId)
        return File.join(LinkedData.settings.repository_folder,
                         self.ontology.acronym.to_s,
                         self.submissionId.to_s)
      end

      def zip_folder
        return File.join([self.data_folder, "unzipped"])
      end

      def csv_path
        return File.join(self.data_folder, self.ontology.acronym.to_s + ".csv.gz")
      end

      def metrics_path
        return File.join(self.data_folder, "metrics.csv")
      end

      def rdf_path
        return File.join(self.data_folder, "owlapi.xrdf")
      end

      def parsing_log_path
        return File.join(self.data_folder, 'parsing.log')
      end

      def triples_file_path
        self.bring(:uploadFilePath) if self.bring?(:uploadFilePath)
        self.bring(:masterFileName) if self.bring?(:masterFileName)
        triples_file_name = File.basename(self.uploadFilePath.to_s)
        full_file_path = File.join(File.expand_path(self.data_folder.to_s), triples_file_name)
        zip = LinkedData::Utils::FileHelpers.zip?(full_file_path)
        triples_file_name = File.basename(self.masterFileName.to_s) if zip && self.masterFileName
        file_name = File.join(File.expand_path(self.data_folder.to_s), triples_file_name)
        File.expand_path(file_name)
      end

      def unzip_submission(logger)
        zip = LinkedData::Utils::FileHelpers.zip?(self.uploadFilePath)
        zip_dst = nil

        if zip
          zip_dst = self.zip_folder

          if Dir.exist? zip_dst
            FileUtils.rm_r [zip_dst]
          end
          FileUtils.mkdir_p zip_dst
          extracted = LinkedData::Utils::FileHelpers.unzip(self.uploadFilePath, zip_dst)

          # Set master file name automatically if there is only one file
          if extracted.length == 1 && self.masterFileName.nil?
            self.masterFileName = extracted.first.name
            self.save
          end

          logger.info("Files extracted from zip #{extracted}")
          logger.flush
        end
        return zip_dst
      end

      def delete_old_submission_files
        path_to_repo = data_folder
        submission_files = FILES_TO_DELETE.map { |f| File.join(path_to_repo, f) }
        submission_files.push(csv_path)
        submission_files.push(parsing_log_path) unless parsing_log_path.nil?
        FileUtils.rm(submission_files, force: true)
      end

      # accepts another submission in 'older' (it should be an 'older' ontology version)
      def diff(logger, older)
        begin
          self.bring_remaining
          self.bring(:diffFilePath)
          self.bring(:uploadFilePath)
          older.bring(:uploadFilePath)
          LinkedData::Diff.logger = logger
          bubastis = LinkedData::Diff::BubastisDiffCommand.new(
              File.expand_path(older.uploadFilePath),
              File.expand_path(self.uploadFilePath)
          )
          self.diffFilePath = bubastis.diff
          self.save
          logger.info("Bubastis diff generated successfully for #{self.id}")
          logger.flush
        rescue Exception => e
          logger.error("Bubastis diff for #{self.id} failed - #{e.class}: #{e.message}")
          logger.flush
          raise e
        end
      end

      def class_count(logger=nil)
        logger ||= LinkedData::Parser.logger || Logger.new($stderr)
        count = -1
        count_set = false
        self.bring(:metrics) if self.bring?(:metrics)

        begin
          mx = self.metrics
        rescue Exception => e
          logger.error("Unable to retrieve metrics in class_count for #{self.id.to_s} - #{e.class}: #{e.message}")
          logger.flush
          mx = nil
        end

        self.bring(:hasOntologyLanguage) unless self.loaded_attributes.include?(:hasOntologyLanguage)

        if mx
          mx.bring(:classes) if mx.bring?(:classes)
          count = mx.classes

          if self.hasOntologyLanguage.skos?
            mx.bring(:individuals) if mx.bring?(:individuals)
            count += mx.individuals
          end
          count_set = true
        else
          mx = metrics_from_file(logger)

          unless mx.empty?
            count = mx[1][0].to_i

            if self.hasOntologyLanguage.skos?
              count += mx[1][1].to_i
            end
            count_set = true
          end
        end

        unless count_set
          logger.error("No calculated metrics or metrics file was found for #{self.id.to_s}. Unable to return total class count.")
          logger.flush
        end
        count
      end

      def metrics_from_file(logger=nil)
        logger ||= LinkedData::Parser.logger || Logger.new($stderr)
        metrics = []
        m_path = self.metrics_path

        begin
          metrics = CSV.read(m_path)
        rescue Exception => e
          logger.error("Unable to find metrics file: #{m_path}")
          logger.flush
        end
        metrics
      end

      def generate_metrics_file(class_count, indiv_count, prop_count)
        CSV.open(self.metrics_path, "wb") do |csv|
          csv << ["Class Count", "Individual Count", "Property Count"]
          csv << [class_count, indiv_count, prop_count]
        end
      end

      def generate_umls_metrics_file(tr_file_path=nil)
        tr_file_path ||= self.triples_file_path
        class_count = 0
        indiv_count = 0
        prop_count = 0

        File.foreach(tr_file_path) do |line|
          class_count += 1 if line =~ /owl:Class/
          indiv_count += 1 if line =~ /owl:NamedIndividual/
          prop_count += 1 if line =~ /owl:ObjectProperty/
          prop_count += 1 if line =~ /owl:DatatypeProperty/
        end
        self.generate_metrics_file(class_count, indiv_count, prop_count)
      end

      def generate_rdf(logger, file_path, reasoning=true, user_params={})

        mime_type = nil
        user_params = {} if user_params.nil?

        if self.hasOntologyLanguage.umls?
          triples_file_path = self.triples_file_path
          logger.info("Using UMLS turtle file found, skipping OWLAPI parse")
          logger.flush
          mime_type = LinkedData::MediaTypes.media_type_from_base(LinkedData::MediaTypes::TURTLE)
          generate_umls_metrics_file(triples_file_path)
        else
          output_rdf = self.rdf_path

          if File.exist?(output_rdf)
            logger.info("deleting old owlapi.xrdf ..")
            deleted = FileUtils.rm(output_rdf)

            if deleted.length > 0
              logger.info("deleted")
            else
              logger.info("error deleting owlapi.rdf")
            end
          end
          owlapi = LinkedData::Parser::OWLAPICommand.new(
              File.expand_path(file_path),
              File.expand_path(self.data_folder.to_s),
              master_file: self.masterFileName)

          if !reasoning
            owlapi.disable_reasoner
          end
          triples_file_path, missing_imports = owlapi.parse

          if missing_imports && missing_imports.length > 0
            self.missingImports = missing_imports

            missing_imports.each do |imp|
              logger.info("OWL_IMPORT_MISSING: #{imp}")
            end
          else
            self.missingImports = nil
          end
          logger.flush
        end
        delete_and_append(triples_file_path, logger, mime_type)
        version_info = extract_version()

        if version_info
          self.version = version_info          
        end

        begin
          # Extract metadata directly from the ontology
          extract_ontology_metadata(logger, user_params)
          logger.info("Additional metadata extracted.")
        rescue => e
          logger.error("Error while extracting additional metadata: #{e}")
        end
        begin
          # Set default metadata
          set_default_metadata(logger)
          logger.info("Default metadata set.")
        rescue => e
          logger.error("Error while setting default metadata: #{e}")
        end
      end
      
      # Extract additional metadata about the ontology
      # First it extracts the main metadata, then the mapped metadata
      def extract_ontology_metadata(logger, user_params)
        ontology_uri = extract_ontology_uri()
        logger.info("Extraction metadata from ontology #{ontology_uri}")
        #logger.info("User params: #{user_params}")

        # go through all OntologySubmission attributes. Returns symbols
        LinkedData::Models::OntologySubmission.attributes(:all).each do |attr|
          # for attribute with the :extractedMetadata setting on, and that have not been defined by the user
          if (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:extractedMetadata]) && !(user_params.has_key?(attr) && !user_params[attr].nil? && !user_params[attr].empty?)
            # a boolean to check if a value that should be single have already been extracted
            single_extracted = false

            if !LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].nil?
              property_to_extract = LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].to_s + ":" + attr.to_s
              hash_results = extract_each_metadata(ontology_uri, attr, property_to_extract, logger)

              if (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:list))
                # Add the retrieved value(s) to the attribute if the attribute take a list of objects
                if self.send(attr.to_s).nil?
                  metadata_values = []
                else
                  metadata_values = self.send(attr.to_s).dup
                end
                hash_results.each do |k,v|
                  metadata_values.push(v)
                end
                self.send("#{attr.to_s}=", metadata_values)
              elsif (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:concatenate))
                # don't keep value from previous submissions for concats
                metadata_concat = []
                # if multiple value for this attribute, then we concatenate it. And it's send to the attr after getting all metadataMappings
                hash_results.each do |k,v|
                  metadata_concat << v.to_s
                end
              else
                # If multiple value for a metadata that should have a single value: taking one value randomly (the first in the hash)
                hash_results.each do |k,v|
                  single_extracted = true
                  self.send("#{attr.to_s}=", v)
                  break
                end
              end
            end

            # extracts attribute value from metadata mappings
            if !LinkedData::Models::OntologySubmission.attribute_settings(attr)[:metadataMappings].nil?

              LinkedData::Models::OntologySubmission.attribute_settings(attr)[:metadataMappings].each do |mapping|
                if single_extracted == true
                  # if an attribute with only one possible object as already been extracted
                  break
                end
                hash_mapping_results = extract_each_metadata(ontology_uri, attr, mapping.to_s, logger)

                if (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:list))
                  # Add the retrieved value(s) to the attribute if the attribute take a list of objects
                  if self.send(attr.to_s).nil?
                    metadata_values = []
                  else
                    metadata_values = self.send(attr.to_s).dup
                  end
                  hash_mapping_results.each do |k,v|
                    metadata_values.push(v)
                  end
                  self.send("#{attr.to_s}=", metadata_values)
                elsif (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:concatenate))
                  # if multiple value for this attribute, then we concatenate it
                  hash_mapping_results.each do |k,v|
                    metadata_concat << v.to_s
                  end
                else
                  # If multiple value for a metadata that should have a single value: taking one value randomly (the first in the hash)
                  hash_mapping_results.each do |k,v|
                    self.send("#{attr.to_s}=", v)
                    break
                  end
                end
              end
            end

            # Add the concat at the very end, to easily join the content of the array
            if (LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:concatenate))
              if !metadata_concat.empty?
                self.send("#{attr.to_s}=", metadata_concat.join(", "))
              end
            end
          end
        end

        # Retrieve ontology URI attribute directly with OWLAPI
        self.URI = ontology_uri
      end

      # Set some metadata to default values if nothing extracted
      def set_default_metadata(logger)
        if self.identifier.nil?
          self.identifier = self.URI.to_s
        end

        if self.deprecated.nil?
          if self.status.eql?("retired")
            self.deprecated = true
          else
            self.deprecated = false
          end
        end

        # Add the ontology hasDomain to the submission hasDomain metadata value
        ontology_domain_list = []
        self.ontology.bring(:hasDomain).hasDomain.each do |domain|
          ontology_domain_list << domain.id
        end
        if (ontology_domain_list.length > 0 && self.hasDomain.nil?)
          self.hasDomain = ""
        end
        if !self.hasDomain.nil?
          self.hasDomain << ontology_domain_list.join(", ")
        end

        # Only get the first view because the attribute is not a list
        ontology_view = self.ontology.bring(:views).views.first
        if (self.hasPart.nil? && !ontology_view.nil?)
          self.hasPart = ontology_view.id
        end

        # If no example identifier extracted: take the first class
        if self.exampleIdentifier.nil?
          self.exampleIdentifier = LinkedData::Models::Class.in(self).first.id
        end

        # Metadata specific to BioPortal that have been removed:
        #if self.hostedBy.nil?
        #  self.hostedBy = [ RDF::URI.new("http://#{LinkedData.settings.ui_host}") ]
        #end

        # Add the search endpoint URL
        if self.openSearchDescription.nil?
          self.openSearchDescription = RDF::URI.new("#{LinkedData.settings.rest_url_prefix}search?ontologies=#{self.ontology.acronym}&q=")
        end

        # Search allow to search by URI too
        if self.uriLookupEndpoint.nil?
          self.uriLookupEndpoint = RDF::URI.new("#{LinkedData.settings.rest_url_prefix}search?ontologies=#{self.ontology.acronym}&require_exact_match=true&q=")
        end

        # Add the dataDump URL
        if self.dataDump.nil?
          self.dataDump = RDF::URI.new("#{LinkedData.settings.rest_url_prefix}ontologies/#{self.ontology.acronym}/download?download_format=rdf")
        end

        if self.csvDump.nil?
          self.csvDump = RDF::URI.new("#{LinkedData.settings.rest_url_prefix}ontologies/#{self.ontology.acronym}/download?download_format=csv")
        end

        # Add the previous submission as a prior version
        if self.submissionId > 1
=begin
          if prior_versions.nil?
            prior_versions = []
          else
            prior_versions = self.hasPriorVersion.dup
          end
          prior_versions.push(RDF::URI.new("#{LinkedData.settings.rest_url_prefix}ontologies/#{self.ontology.acronym}/submissions/#{self.submissionId - 1}"))
          self.hasPriorVersion = prior_versions
=end
          self.hasPriorVersion = RDF::URI.new("#{LinkedData.settings.rest_url_prefix}ontologies/#{self.ontology.acronym}/submissions/#{self.submissionId - 1}")
        end

        if self.hasOntologyLanguage.umls?
          self.hasOntologySyntax = "http://www.w3.org/ns/formats/Turtle"
        elsif self.hasOntologyLanguage.obo?
          self.hasOntologySyntax = "http://purl.obolibrary.org/obo/oboformat/spec.html"
        end

        # Define default properties for prefLabel, synonyms, definition, author:
        if self.hasOntologyLanguage.owl?
          if self.prefLabelProperty.nil?
            self.prefLabelProperty = Goo.vocabulary(:skos)[:prefLabel]
          end
          if self.synonymProperty.nil?
            self.synonymProperty = Goo.vocabulary(:skos)[:altLabel]
          end
          if self.definitionProperty.nil?
            self.definitionProperty = Goo.vocabulary(:rdfs)[:comment]
          end
          if self.authorProperty.nil?
            self.authorProperty = Goo.vocabulary(:dc)[:creator]
          end
          # Add also hierarchyProperty? Could not find any use of it
        end

        # Add the sparql endpoint URL
        if self.endpoint.nil?
          self.endpoint = RDF::URI.new(LinkedData.settings.sparql_endpoint_url)
        end

      end

      # Return a hash with the best literal value for an URI
      # it selects the literal according to their language: no language > english > french > other languages
      def select_metadata_literal(metadata_uri, metadata_literal, hash)
        if metadata_literal.is_a?(RDF::Literal)
          if hash.has_key?(metadata_uri)
            if metadata_literal.has_language?
              if !hash[metadata_uri].has_language?
                return hash
              else
                if metadata_literal.language == :en || metadata_literal.language == :eng
                  # Take the value with english language over other languages
                  hash[metadata_uri] = metadata_literal
                  return hash
                elsif metadata_literal.language == :fr || metadata_literal.language == :fre
                  # If no english, take french
                  if hash[metadata_uri].language == :en || hash[metadata_uri].language == :eng
                    return hash
                  else
                    hash[metadata_uri] = metadata_literal
                    return hash
                  end
                else
                  return hash
                end
              end
            else
              # Take the value with no language in priority (considered as a default)
              hash[metadata_uri] = metadata_literal
              return hash
            end
          else
            hash[metadata_uri] = metadata_literal
            return hash
          end
        end
      end


      # A function to extract additional metadata
      # Take the literal data if the property is pointing to a literal
      # If pointing to an URI: first it takes the "omv:name" of the object pointed by the property, if nil it takes the "rdfs:label".
      # If not found it check for "omv:firstName + omv:lastName" (for "omv:Person") of this object. And to finish it takes the "URI"
      # The hash_results contains the metadataUri (objet pointed on by the metadata property) with the value we are using from it
      def extract_each_metadata(ontology_uri, attr, prop_to_extract, logger)

        query_metadata = <<eos 

SELECT DISTINCT ?extractedObject ?omvname ?omvfirstname ?omvlastname ?rdfslabel
FROM #{self.id.to_ntriples}
WHERE {
  <#{ontology_uri}> #{prop_to_extract} ?extractedObject .
  OPTIONAL { ?extractedObject omv:name ?omvname } .
  OPTIONAL { ?extractedObject omv:firstName ?omvfirstname } .
  OPTIONAL { ?extractedObject omv:lastName ?omvlastname } .
  OPTIONAL { ?extractedObject rdfs:label ?rdfslabel } .
}
eos
        Goo.namespaces.each do |prefix,uri|
          query_metadata = "PREFIX #{prefix}: <#{uri}>\n" + query_metadata
        end

        #logger.info(query_metadata)
        # This hash will contain the "literal" metadata for each object (uri or literal) pointed by the metadata predicate
        hash_results = {}
        Goo.sparql_query_client.query(query_metadata).each_solution do |sol|

          if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:uri)
            # If the attr is enforced as URI then it directly takes the URI
            if sol[:extractedObject].is_a?(RDF::URI)
              hash_results[sol[:extractedObject]] = sol[:extractedObject]
            end

          elsif LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:date_time)
            begin
              hash_results[sol[:extractedObject]] = DateTime.iso8601(sol[:extractedObject].to_s)
            rescue => e
              logger.error("Impossible to extract DateTime metadata for #{attr.to_s}: #{sol[:extractedObject].to_s}. It should follow iso8601 standards. Error message: #{e}")
            end

          elsif LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:integer)
            begin
              hash_results[sol[:extractedObject]] = sol[:extractedObject].to_s.to_i
            rescue => e
              logger.error("Impossible to extract integer metadata for #{attr.to_s}: #{sol[:extractedObject].to_s}. Error message: #{e}")
            end

          elsif LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].include?(:boolean)
            begin
              if (sol[:extractedObject].to_s.downcase.eql?("true"))
                hash_results[sol[:extractedObject]] = true
              elsif (sol[:extractedObject].to_s.downcase.eql?("false"))
                hash_results[sol[:extractedObject]] = false
              end
            rescue => e
              logger.error("Impossible to extract boolean metadata for #{attr.to_s}: #{sol[:extractedObject].to_s}. Error message: #{e}")
            end

          else
            if sol[:extractedObject].is_a?(RDF::URI)
              # if the object is an URI but we are requesting a String
              # TODO: ATTENTION on veut pas forcément TOUT le temps recump omvname, etc... Voir si on change ce comportement
              if !sol[:omvname].nil?
                hash_results = select_metadata_literal(sol[:extractedObject],sol[:omvname], hash_results)
              elsif !sol[:rdfslabel].nil?
                hash_results = select_metadata_literal(sol[:extractedObject],sol[:rdfslabel], hash_results)
              elsif !sol[:omvfirstname].nil?
                hash_results = select_metadata_literal(sol[:extractedObject],sol[:omvfirstname], hash_results)
                # if first and last name are defined (for omv:Person)
                if !sol[:omvlastname].nil?
                  hash_results[sol[:extractedObject]] = hash_results[sol[:extractedObject]].to_s + " " + sol[:omvlastname].to_s
                end
              elsif !sol[:omvlastname].nil?
                # if only last name is defined
                hash_results = select_metadata_literal(sol[:extractedObject],sol[:omvlastname], hash_results)
              else
                hash_results[sol[:extractedObject]] = sol[:extractedObject].to_s
              end

            else
              # If this is directly a literal
              hash_results = select_metadata_literal(sol[:extractedObject],sol[:extractedObject], hash_results)
            end
          end
        end

        return hash_results
      end
      

      # Extract the ontology URI to use it to extract ontology metadata
      def extract_ontology_uri
        query_get_onto_uri = <<eos
SELECT DISTINCT ?uri
FROM #{self.id.to_ntriples}
WHERE {
<http://bioportal.bioontology.org/ontologies/URI> <http://www.w3.org/2002/07/owl#versionInfo> ?uri .
}
eos
        Goo.sparql_query_client.query(query_get_onto_uri).each_solution do |sol|
          return sol[:uri].to_s
        end
        return nil
      end

      def extract_version

        query_version_info = <<eos
SELECT ?versionInfo
FROM #{self.id.to_ntriples}
WHERE {
<http://bioportal.bioontology.org/ontologies/versionSubject>
 <http://www.w3.org/2002/07/owl#versionInfo> ?versionInfo .
}
eos
        Goo.sparql_query_client.query(query_version_info).each_solution do |sol|
          return sol[:versionInfo].to_s
        end
        return nil
      end

      def process_callbacks(logger, callbacks, action_name, &block)
        callbacks.delete_if do |_, callback|
          begin
            if callback[action_name]
              callable = self.method(callback[action_name])
              yield(callable, callback)
            end
            false
          rescue Exception => e
            logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
            logger.flush

            if callback[:status]
              add_submission_status(callback[:status].get_error_status)
              self.save
            end

            # halt the entire processing if :required is set to true
            raise e if callback[:required]
            # continue processing of other callbacks, but not this one
            true
          end
        end
      end

      def loop_classes(logger, callbacks)
        page = 1
        size = 2500
        paging = LinkedData::Models::Class.in(self).include(:prefLabel, :synonym, :label, :unmapped).page(page, size)
        cls_count_set = false
        cls_count = class_count(logger)

        if cls_count > -1
          # prevent a COUNT SPARQL query if possible
          paging.page_count_set(cls_count)
          cls_count_set = true
        else
          cls_count = 0
        end

        iterate_classes = false
        # 1. init artifacts hash if not explicitly passed in the callback
        # 2. determine if class-level iteration is required
        callbacks.each { |_, callback| callback[:artifacts] ||= {}; iterate_classes = true if callback[:caller_on_each] }

        process_callbacks(logger, callbacks, :caller_on_pre) {
            |callable, callback| callable.call(callback[:artifacts], logger, paging) }

        begin
          t0 = Time.now
          page_classes = paging.page(page, size).all
          t1 = Time.now
          logger.info("#{page_classes.length} in page #{page} classes for " +
                  "#{self.id.to_ntriples} (#{t1 - t0} sec)." +
                  " Total pages #{page_classes.total_pages}.")
          logger.flush

          process_callbacks(logger, callbacks, :caller_on_pre_page) {
              |callable, callback| callable.call(callback[:artifacts], logger, paging, page_classes, page) }

          page_classes.each { |c|
            process_callbacks(logger, callbacks, :caller_on_each) {
                |callable, callback| callable.call(callback[:artifacts], logger, paging, page_classes, page, c) }
          } if iterate_classes

          process_callbacks(logger, callbacks, :caller_on_post_page) {
              |callable, callback| callable.call(callback[:artifacts], logger, paging, page_classes, page) }
          cls_count += page_classes.length unless cls_count_set

          page = page_classes.next? ? page + 1 : nil
        end while !page.nil?

        callbacks.each { |_, callback| callback[:artifacts][:count_classes] = cls_count }
        process_callbacks(logger, callbacks, :caller_on_post) {
            |callable, callback| callable.call(callback[:artifacts], logger, paging) }
        # set the status on actions that have completed successfully
        callbacks.each do |_, callback|
          if callback[:status]
            add_submission_status(callback[:status])
            self.save
          end
        end
      end

      def generate_missing_labels_pre(artifacts={}, logger, paging)
        file_path = artifacts[:file_path]
        artifacts[:save_in_file] = File.join(File.dirname(file_path), "labels.ttl")
        artifacts[:save_in_file_mappings] = File.join(File.dirname(file_path), "mappings.ttl")
        property_triples = LinkedData::Utils::Triples.rdf_for_custom_properties(self)
        Goo.sparql_data_client.append_triples(self.id, property_triples, mime_type="application/x-turtle")
        fsave = File.open(artifacts[:save_in_file], "w")
        fsave.write(property_triples)
        fsave_mappings = File.open(artifacts[:save_in_file_mappings], "w")
        artifacts[:fsave] = fsave
        artifacts[:fsave_mappings] = fsave_mappings
      end

      def generate_missing_labels_pre_page(artifacts={}, logger, paging, page_classes, page)
        artifacts[:label_triples] = []
        artifacts[:mapping_triples] = []
      end

      def generate_missing_labels_each(artifacts={}, logger, paging, page_classes, page, c)
        prefLabel = nil

        if c.prefLabel.nil?
          rdfs_labels = c.label

          if rdfs_labels && rdfs_labels.length > 1 && c.synonym.length > 0
            rdfs_labels = (Set.new(c.label) -  Set.new(c.synonym)).to_a.first

            if rdfs_labels.nil? || rdfs_labels.length == 0
              rdfs_labels = c.label
            end
          end

          if rdfs_labels and not (rdfs_labels.instance_of? Array)
            rdfs_labels = [rdfs_labels]
          end
          label = nil

          if rdfs_labels && rdfs_labels.length > 0
            label = rdfs_labels[0]
          else
            label = LinkedData::Utils::Triples.last_iri_fragment c.id.to_s
          end
          artifacts[:label_triples] << LinkedData::Utils::Triples.label_for_class_triple(
              c.id, Goo.vocabulary(:metadata_def)[:prefLabel], label)
          prefLabel = label
        else
          prefLabel = c.prefLabel
        end

        if self.ontology.viewOf.nil?
          loomLabel = OntologySubmission.loom_transform_literal(prefLabel.to_s)

          if loomLabel.length > 2
            artifacts[:mapping_triples] << LinkedData::Utils::Triples.loom_mapping_triple(
                c.id, Goo.vocabulary(:metadata_def)[:mappingLoom], loomLabel)
          end
          artifacts[:mapping_triples] << LinkedData::Utils::Triples.uri_mapping_triple(
              c.id, Goo.vocabulary(:metadata_def)[:mappingSameURI], c.id)
        end
      end

      def generate_missing_labels_post_page(artifacts={}, logger, paging, page_classes, page)
        rest_mappings = LinkedData::Mappings.migrate_rest_mappings(self.ontology.acronym)
        artifacts[:mapping_triples].concat(rest_mappings)

        if artifacts[:label_triples].length > 0
          logger.info("Asserting #{artifacts[:label_triples].length} labels in " +
                          "#{self.id.to_ntriples}")
          logger.flush
          artifacts[:label_triples] = artifacts[:label_triples].join("\n")
          artifacts[:fsave].write(artifacts[:label_triples])
          t0 = Time.now
          Goo.sparql_data_client.append_triples(self.id, artifacts[:label_triples], mime_type="application/x-turtle")
          t1 = Time.now
          logger.info("Labels asserted in #{t1 - t0} sec.")
          logger.flush
        else
          logger.info("No labels generated in page #{page}.")
          logger.flush
        end

        if artifacts[:mapping_triples].length > 0
          logger.info("Asserting #{artifacts[:mapping_triples].length} mappings in " +
                          "#{self.id.to_ntriples}")
          logger.flush
          artifacts[:mapping_triples] = artifacts[:mapping_triples].join("\n")
          artifacts[:fsave_mappings].write(artifacts[:mapping_triples])

          t0 = Time.now
          Goo.sparql_data_client.append_triples(self.id, artifacts[:mapping_triples], mime_type="application/x-turtle")
          t1 = Time.now
          logger.info("Mapping labels asserted in #{t1 - t0} sec.")
          logger.flush
        end
      end

      def generate_missing_labels_post(artifacts={}, logger, paging)
        logger.info("end generate_missing_labels traversed #{artifacts[:count_classes]} classes")
        logger.info("Saved generated labels in #{artifacts[:save_in_file]}")
        artifacts[:fsave].close()
        artifacts[:fsave_mappings].close()
        logger.flush
      end

      def generate_obsolete_classes(logger, file_path)
        self.bring(:obsoleteProperty) if self.bring?(:obsoleteProperty)
        self.bring(:obsoleteParent) if self.bring?(:obsoleteParent)
        classes_deprecated = []
        if self.obsoleteProperty &&
          self.obsoleteProperty.to_s != "http://www.w3.org/2002/07/owl#deprecated"

          predicate_obsolete = RDF::URI.new(self.obsoleteProperty.to_s)
          query_obsolete_predicate = <<eos
SELECT ?class_id ?deprecated
FROM #{self.id.to_ntriples}
WHERE { ?class_id #{predicate_obsolete.to_ntriples} ?deprecated . }
eos
          Goo.sparql_query_client.query(query_obsolete_predicate).each_solution do |sol|
            unless ["0", "false"].include? sol[:deprecated].to_s
              classes_deprecated << sol[:class_id].to_s
            end
          end
          logger.info("Obsolete found #{classes_deprecated.length} for property #{self.obsoleteProperty.to_s}")
        end
        if self.obsoleteParent.nil?
          #try to find oboInOWL obsolete.
          obo_in_owl_obsolete_class = LinkedData::Models::Class
                                  .find(LinkedData::Utils::Triples.obo_in_owl_obsolete_uri)
                                  .in(self).first
          if obo_in_owl_obsolete_class
            self.obsoleteParent = LinkedData::Utils::Triples.obo_in_owl_obsolete_uri
          end
        end
        if self.obsoleteParent
          class_obsolete_parent = LinkedData::Models::Class
                                  .find(self.obsoleteParent)
                                  .in(self).first
          if class_obsolete_parent
            descendents_obsolete = class_obsolete_parent.descendants
            logger.info("Found #{descendents_obsolete.length} descendents of obsolete root #{self.obsoleteParent.to_s}")
            descendents_obsolete.each do |obs|
              classes_deprecated << obs.id
            end
          else
            logger.error("Submission #{self.id.to_s} obsoleteParent #{self.obsoleteParent.to_s} not found")
          end
        end
        if classes_deprecated.length > 0
          classes_deprecated.uniq!
          logger.info("Asserting owl:deprecated statement for #{classes_deprecated} classes")
          save_in_file = File.join(File.dirname(file_path), "obsolete.ttl")
          fsave = File.open(save_in_file,"w")
          classes_deprecated.each do |class_id|
            fsave.write(LinkedData::Utils::Triples.obselete_class_triple(class_id) + "\n")
          end
          fsave.close()
          result = Goo.sparql_data_client.append_triples_from_file(
                          self.id,
                          save_in_file,
                          mime_type="application/x-turtle")
        end
      end

      def add_submission_status(status)
        valid = status.is_a?(LinkedData::Models::SubmissionStatus)
        raise ArgumentError, "The status being added is not SubmissionStatus object" unless valid

        #archive removes the other status
        if status.archived?
          self.submissionStatus = [status]
          return self.submissionStatus
        end

        self.submissionStatus ||= []
        s = self.submissionStatus.dup

        if (status.error?)
          # remove the corresponding non_error status (if exists)
          non_error_status = status.get_non_error_status()
          s.reject! { |stat| stat.get_code_from_id() == non_error_status.get_code_from_id() } unless non_error_status.nil?
        else
          # remove the corresponding non_error status (if exists)
          error_status = status.get_error_status()
          s.reject! { |stat| stat.get_code_from_id() == error_status.get_code_from_id() } unless error_status.nil?
        end

        has_status = s.any? { |s| s.get_code_from_id() == status.get_code_from_id() }
        s << status unless has_status
        self.submissionStatus = s

      end

      def remove_submission_status(status)
        if (self.submissionStatus)
          valid = status.is_a?(LinkedData::Models::SubmissionStatus)
          raise ArgumentError, "The status being removed is not SubmissionStatus object" unless valid
          s = self.submissionStatus.dup

          # remove that status as well as the error status for the same status
          s.reject! { |stat|
            stat_code = stat.get_code_from_id()
            stat_code == status.get_code_from_id() ||
                stat_code == status.get_error_status().get_code_from_id()
          }
          self.submissionStatus = s
        end
      end

      def set_ready()
        ready_status = LinkedData::Models::SubmissionStatus.get_ready_status

        ready_status.each do |code|
          status = LinkedData::Models::SubmissionStatus.find(code).include(:code).first
          add_submission_status(status)
        end
      end

      # allows to optionally submit a list of statuses
      # that would define the "ready" state of this
      # submission in this context
      def ready?(options={})
        self.bring(:submissionStatus) if self.bring?(:submissionStatus)
        status = options[:status] || :ready
        status = status.is_a?(Array) ? status : [status]
        return true if status.include?(:any)
        return false unless self.submissionStatus

        if status.include? :ready
          return LinkedData::Models::SubmissionStatus.status_ready?(self.submissionStatus)
        else
          status.each do |x|
            return false if self.submissionStatus.select { |x1|
              x1.get_code_from_id() == x.to_s.upcase
            }.length == 0
          end
          return true
        end
      end

      def archived?
        return ready?(status: [:archived])
      end

      ################################################################
      # Possible options with their defaults:
      #   process_rdf       = false
      #   index_search      = false
      #   index_properties  = false
      #   index_commit      = false
      #   run_metrics       = false
      #   reasoning         = false
      #   diff              = false
      #   archive           = false
      #   if no options passed, ALL actions, except for archive = true
      ################################################################
      def process_submission(logger, options={})
        # Wrap the whole process so we can email results
        begin
          process_rdf = false
          index_search = false
          index_properties = false
          index_commit = false
          run_metrics = false
          reasoning = false
          diff = false
          archive = false

          if options.empty?
            process_rdf = true
            index_search = true
            index_properties = true
            index_commit = true
            run_metrics = true
            reasoning = true
            diff = true
            archive = false
          else
            process_rdf = options[:process_rdf] == true ? true : false
            index_search = options[:index_search] == true ? true : false
            index_properties = options[:index_properties] == true ? true : false
            index_commit = options[:index_commit] == true ? true : false
            run_metrics = options[:run_metrics] == true ? true : false

            if !process_rdf || options[:reasoning] == false
              reasoning = false
            else
              reasoning = true
            end

            if (!index_search && !index_properties) || options[:index_commit] == false
              index_commit = false
            else
              index_commit = true
            end

            diff = options[:diff] == true ? true : false
            archive = options[:archive] == true ? true : false
          end

          self.bring_remaining
          self.ontology.bring_remaining

          logger.info("Starting to process #{self.ontology.acronym}/submissions/#{self.submissionId}")
          logger.flush
          LinkedData::Parser.logger = logger
          status = nil

          if archive
            self.submissionStatus = nil
            status = LinkedData::Models::SubmissionStatus.find("ARCHIVED").first
            add_submission_status(status)

            # Delete everything except for original ontology file.
            ontology.bring(:submissions)
            submissions = ontology.submissions
            unless submissions.nil?
              submissions.each { |s| s.bring(:submissionId) }
              submission = submissions.sort { |a,b| b.submissionId <=> a.submissionId }[0]
              # Don't perform deletion if this is the most recent submission.
              if (self.submissionId < submission.submissionId)
                delete_old_submission_files
              end
            end
          else
            if process_rdf
              # Remove processing status types before starting RDF parsing etc.
              self.submissionStatus = nil
              status = LinkedData::Models::SubmissionStatus.find("UPLOADED").first
              add_submission_status(status)
              self.save

              # Parse RDF
              file_path = nil
              begin
                if not self.valid?
                  error = "Submission is not valid, it cannot be processed. Check errors."
                  raise ArgumentError, error
                end
                if not self.uploadFilePath
                  error = "Submission is missing an ontology file, cannot parse."
                  raise ArgumentError, error
                end
                status = LinkedData::Models::SubmissionStatus.find("RDF").first
                remove_submission_status(status) #remove RDF status before starting
                zip_dst = unzip_submission(logger)
                file_path = zip_dst ? zip_dst.to_s : self.uploadFilePath.to_s
                generate_rdf(logger, file_path, reasoning=reasoning, options[:params])
                add_submission_status(status)
                self.save
              rescue Exception => e
                logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                logger.flush
                add_submission_status(status.get_error_status)
                self.save
                # If RDF generation fails, no point of continuing
                raise e
              end

              callbacks = {
                  missing_labels: {
                      required: true,
                      status: LinkedData::Models::SubmissionStatus.find("RDF_LABELS").first,
                      artifacts: {
                          file_path: file_path
                      },
                      caller_on_pre: :generate_missing_labels_pre,
                      caller_on_pre_page: :generate_missing_labels_pre_page,
                      caller_on_each: :generate_missing_labels_each,
                      caller_on_post_page: :generate_missing_labels_post_page,
                      caller_on_post: :generate_missing_labels_post
                  }
              }

              loop_classes(logger, callbacks)

              status = LinkedData::Models::SubmissionStatus.find("OBSOLETE").first
              begin
                generate_obsolete_classes(logger, file_path)
                add_submission_status(status)
                self.save
              rescue Exception => e
                logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                logger.flush
                add_submission_status(status.get_error_status)
                self.save
                # if obsolete fails the parsing fails
                raise e
              end
            end

            parsed = ready?(status: [:rdf, :rdf_labels])

            if index_search
              raise Exception, "The submission #{self.ontology.acronym}/submissions/#{self.submissionId} cannot be indexed because it has not been successfully parsed" unless parsed
              status = LinkedData::Models::SubmissionStatus.find("INDEXED").first
              begin
                index(logger, index_commit, false)
                add_submission_status(status)
              rescue Exception => e
                logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                logger.flush
                add_submission_status(status.get_error_status)
                if File.file?(self.csv_path)
                  FileUtils.rm(self.csv_path)
                end
              ensure
                self.save
              end
            end

            if index_properties
              raise Exception, "The properties for the submission #{self.ontology.acronym}/submissions/#{self.submissionId} cannot be indexed because it has not been successfully parsed" unless parsed
              status = LinkedData::Models::SubmissionStatus.find("INDEXED_PROPERTIES").first
              begin
                index_properties(logger, index_commit, false)
                add_submission_status(status)
              rescue Exception => e
                logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                logger.flush
                add_submission_status(status.get_error_status)
              ensure
                self.save
              end
            end

            if run_metrics
              raise Exception, "Metrics cannot be generated on the submission #{self.ontology.acronym}/submissions/#{self.submissionId} because it has not been successfully parsed" unless parsed
              status = LinkedData::Models::SubmissionStatus.find("METRICS").first
              begin
                process_metrics(logger)
                add_submission_status(status)
              rescue Exception => e
                logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                logger.flush
                self.metrics = nil
                add_submission_status(status.get_error_status)
              ensure
                self.save
              end
            end

            if diff
              status = LinkedData::Models::SubmissionStatus.find("DIFF").first
              # Get previous submission from ontology.submissions
              self.ontology.bring(:submissions)
              submissions = self.ontology.submissions

              unless submissions.nil?
                submissions.each {|s| s.bring(:submissionId, :diffFilePath)}
                # Sort submissions in descending order of submissionId, extract last two submissions
                recent_submissions = submissions.sort {|a, b| b.submissionId <=> a.submissionId}[0..1]

                if recent_submissions.length > 1
                  # validate that the most recent submission is the current submission
                  if self.submissionId == recent_submissions.first.submissionId
                    prev = recent_submissions.last

                    # Ensure that prev is older than the current submission
                    if self.submissionId > prev.submissionId
                      # generate a diff
                      begin
                        self.diff(logger, prev)
                        add_submission_status(status)
                      rescue Exception => e
                        logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
                        logger.flush
                        add_submission_status(status.get_error_status)
                      ensure
                        self.save
                      end
                    end
                  end
                else
                  logger.info("Bubastis diff: no older submissions available for #{self.id}.")
                end
              else
                logger.info("Bubastis diff: no submissions available for #{self.id}.")
              end
            end
          end

          self.save
          logger.info("Submission processing of #{self.id} completed successfully")
          logger.flush
        ensure
          # make sure results get emailed
          begin
            LinkedData::Utils::Notifications.submission_processed(self)
          rescue Exception => e
            logger.error("Email sending failed: #{e.message}\n#{e.backtrace.join("\n\t")}"); logger.flush
          end
        end
        self
      end

      def process_metrics(logger)
        metrics = LinkedData::Metrics.metrics_for_submission(self, logger)
        metrics.id = RDF::URI.new(self.id.to_s + "/metrics")
        exist_metrics = LinkedData::Models::Metric.find(metrics.id).first
        exist_metrics.delete if exist_metrics
        metrics.save
        self.metrics = metrics
        self
      end

      # callbacks = {
      #     index: {
      #         required: false,
      #         status: LinkedData::Models::SubmissionStatus.find("INDEXED").first,
      #         artifacts: {
      #             commit: index_commit,
      #             optimize: false
      #         },
      #         caller_on_pre: :index_pre,
      #         caller_on_pre_page: :index_pre_page,
      #         caller_on_each: :index_each,
      #         caller_on_post_page: :index_post_page,
      #         caller_on_post: :index_post
      #     }
      # }
      #
      #
      #
      # def index_pre(artifacts={}, logger, paging)
      #   self.bring(:ontology) if self.bring?(:ontology)
      #   self.ontology.bring(:provisionalClasses) if self.ontology.bring?(:provisionalClasses)
      #   logger.info("Indexing ontology: #{self.ontology.acronym}...")
      #   t0 = Time.now
      #   self.ontology.unindex(artifacts[:commit])
      #   logger.info("Removing ontology index (#{Time.now - t0}s)"); logger.flush
      # end
      #
      #
      #
      # def index_pre_page(artifacts={}, logger, paging, page_classes, page)
      #
      # end
      #
      # def index_each(artifacts={}, logger, paging, page_classes, page, c)
      #
      # end
      #
      # def index_post_page(artifacts={}, logger, paging, page_classes, page)
      #
      # end
      #
      # def index_post(artifacts={}, logger, paging)
      #
      # end

      def index(logger, commit = true, optimize = true)
        page = 1
        size = 1000

        count_classes = 0
        time = Benchmark.realtime do
          self.bring(:ontology) if self.bring?(:ontology)
          self.ontology.bring(:acronym) if self.ontology.bring?(:acronym)
          self.ontology.bring(:provisionalClasses) if self.ontology.bring?(:provisionalClasses)
          logger.info("Indexing ontology terms: #{self.ontology.acronym}...")
          t0 = Time.now
          self.ontology.unindex(false)
          logger.info("Removed ontology terms index (#{Time.now - t0}s)"); logger.flush

          paging = LinkedData::Models::Class.in(self).include(:unmapped).page(page, size)
          cls_count = class_count(logger)
          paging.page_count_set(cls_count) unless cls_count < 0

          # TODO: this needs to use its own parameter and moved into a callback
          csv_writer = LinkedData::Utils::OntologyCSVWriter.new
          csv_writer.open(self.ontology, self.csv_path)
          page_len = -1
          prev_page_len = -1

          begin #per page
            t0 = Time.now
            page_classes = paging.page(page, size).all
            total_pages = page_classes.total_pages
            page_len = page_classes.length

            # nothing retrieved even though we're expecting more records
            if total_pages > 0 && page_classes.empty? && (prev_page_len == -1 || prev_page_len == size)
              j = 0
              num_calls = 3

              while page_classes.empty? && j < num_calls do
                j += 1
                logger.error("Empty page encountered. Retrying #{j} times...")
                sleep(2)
                page_classes = paging.page(page, size).all
                logger.info("Success retrieving a page of #{page_classes.length} classes after retrying #{j} times...") unless page_classes.empty?
              end

              if page_classes.empty?
                msg = "Empty page #{page} of #{total_pages} persisted after retrying #{j} times. Indexing of #{self.id.to_s} aborted..."
                logger.error(msg)
                raise msg
              end
            end

            if page_classes.empty?
              if total_pages > 0
                logger.info("The number of pages reported for #{self.id.to_s} - #{total_pages} is higher than expected #{page - 1}. Completing indexing...")
              else
                logger.info("Ontology #{self.id.to_s} contains #{total_pages} pages...")
              end

              break
            end

            prev_page_len = page_len
            logger.info("Page #{page} of #{total_pages} - #{page_len} ontology terms retrieved in #{Time.now - t0} sec.")
            t0 = Time.now

            # TODO: CSV writing needs to be moved to its own callback
            page_classes.each do |c|
              begin
                # this cal is needed for indexing of properties
                LinkedData::Models::Class.map_attributes(c, paging.equivalent_predicates)
              rescue Exception => e
                i = 0
                num_calls = 3
                success = nil

                while success.nil? && i < num_calls do
                  i += 1
                  logger.error("Exception while mapping attributes for #{c.id.to_s}. Retrying #{i} times...")
                  sleep(2)

                  begin
                    LinkedData::Models::Class.map_attributes(c, paging.equivalent_predicates)
                    logger.info("Success mapping attributes for #{c.id.to_s} after retrying #{i} times...")
                    success = true
                  rescue Exception => e1
                    success = nil

                    if i == num_calls
                      logger.error("Error mapping attributes for #{c.id.to_s}:")
                      logger.error("#{e1.class}: #{e1.message} after retrying #{i} times...\n#{e1.backtrace.join("\n\t")}")
                      logger.flush
                    end
                  end
                end
              end
              csv_writer.write_class(c)
            end

            logger.info("Page #{page} of #{total_pages} attributes mapped in #{Time.now - t0} sec.")
            count_classes += page_classes.length
            t0 = Time.now

            LinkedData::Models::Class.indexBatch(page_classes)
            logger.info("Page #{page} of #{total_pages} ontology terms indexed in #{Time.now - t0} sec.")
            logger.flush
            page = page_classes.next? ? page + 1 : nil
          end while !page.nil?

          # TODO: move this into its own callback
          csv_writer.close

          begin
            # index provisional classes
            self.ontology.provisionalClasses.each { |pc| pc.index }
          rescue Exception => e
            logger.error("Error while indexing provisional classes for ontology #{self.ontology.acronym}:")
            logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
            logger.flush
          end

          if commit
            t0 = Time.now
            LinkedData::Models::Class.indexCommit()
            logger.info("Ontology terms index commit in #{Time.now - t0} sec.")
          end
        end
        logger.info("Completed indexing ontology terms: #{self.ontology.acronym} in #{time} sec. #{count_classes} classes.")
        logger.flush

        if optimize
          logger.info("Optimizing ontology terms index...")
          time = Benchmark.realtime do
            LinkedData::Models::Class.indexOptimize()
          end
          logger.info("Completed optimizing ontology terms index in #{time} sec.")
        end
      end

      def index_properties(logger, commit = true, optimize = true)
        page = 1
        size = 2500
        count_props = 0

        time = Benchmark.realtime do
          self.bring(:ontology) if self.bring?(:ontology)
          self.ontology.bring(:acronym) if self.ontology.bring?(:acronym)
          logger.info("Indexing ontology properties: #{self.ontology.acronym}...")
          t0 = Time.now
          self.ontology.unindex_properties(commit)
          logger.info("Removed ontology properties index in #{Time.now - t0} seconds."); logger.flush

          props = self.ontology.properties
          count_props = props.length
          total_pages = (count_props/size.to_f).ceil
          logger.info("Indexing a total of #{total_pages} pages of #{size} properties each.")

          props.each_slice(size) do |prop_batch|
            t = Time.now
            LinkedData::Models::Class.indexBatch(prop_batch, :property)
            logger.info("Page #{page} of ontology properties indexed in #{Time.now - t} seconds."); logger.flush
            page += 1
          end

          if commit
            t0 = Time.now
            LinkedData::Models::Class.indexCommit(nil, :property)
            logger.info("Ontology properties index commit in #{Time.now - t0} seconds.")
          end
        end
        logger.info("Completed indexing ontology properties of #{self.ontology.acronym} in #{time} sec. Total of #{count_props} properties indexed.")
        logger.flush

        if optimize
          logger.info("Optimizing ontology properties index...")
          time = Benchmark.realtime do
            LinkedData::Models::Class.indexOptimize(nil, :property)
          end
          logger.info("Completed optimizing ontology properties index in #{time} seconds.")
        end
      end

      # Override delete to add removal from the search index
      #TODO: revise this with a better process
      def delete(*args)
        options = {}
        args.each {|e| options.merge!(e) if e.is_a?(Hash)}
        remove_index = options[:remove_index] ? true : false
        index_commit = options[:index_commit] == false ? false : true

        super(*args)
        self.ontology.unindex(index_commit)
        self.ontology.unindex_properties(index_commit)

        self.bring(:metrics) if self.bring?(:metrics)
        self.metrics.delete if self.metrics

        if remove_index
          # need to re-index the previous submission (if exists)
          self.ontology.bring(:submissions)

          if self.ontology.submissions.length > 0
            prev_sub = self.ontology.latest_submission()

            if prev_sub
              prev_sub.index(LinkedData::Parser.logger || Logger.new($stderr))
              prev_sub.index_properties(LinkedData::Parser.logger || Logger.new($stderr))
            end
          end
        end
      end

      def roots(extra_include=nil, page=nil, pagesize=nil)
        self.bring(:ontology) unless self.loaded_attributes.include?(:ontology)
        self.bring(:hasOntologyLanguage) unless self.loaded_attributes.include?(:hasOntologyLanguage)
        paged = false

        if page || pagesize
          page ||= 1
          pagesize ||= 50
          paged = true
        end

        skos = self.hasOntologyLanguage&.skos?
        classes = []

        if skos
          root_skos = <<eos
SELECT DISTINCT ?root WHERE {
GRAPH #{self.id.to_ntriples} {
  ?x #{RDF::SKOS[:hasTopConcept].to_ntriples} ?root .
}}
eos
          count = 0

          if paged
            query = <<eos
SELECT (COUNT(?x) as ?count) WHERE {
GRAPH #{self.id.to_ntriples} {
  ?x #{RDF::SKOS[:hasTopConcept].to_ntriples} ?root .
}}
eos
            rs = Goo.sparql_query_client.query(query)
            rs.each do |sol|
              count = sol[:count].object
            end

            offset = (page - 1) * pagesize
            root_skos = "#{root_skos} LIMIT #{pagesize} OFFSET #{offset}"
          end

          #needs to get cached
          class_ids = []

          Goo.sparql_query_client.query(root_skos, { :graphs => [self.id] }).each_solution do |s|
            class_ids << s[:root]
          end

          class_ids.each do |id|
            classes << LinkedData::Models::Class.find(id).in(self).disable_rules.first
          end

          classes = Goo::Base::Page.new(page, pagesize, count, classes) if paged
        else
          self.ontology.bring(:flat)
          data_query = nil

          if self.ontology.flat
            data_query = LinkedData::Models::Class.in(self)
          else
            owl_thing = Goo.vocabulary(:owl)["Thing"]
            data_query = LinkedData::Models::Class.where(parents: owl_thing).in(self)
          end

          if paged
            page_data_query = data_query.page(page, pagesize)
            classes = page_data_query.page(page, pagesize).disable_rules.all
          else
            classes = data_query.disable_rules.all
          end
        end

        where = LinkedData::Models::Class.in(self).models(classes).include(:prefLabel, :definition, :synonym, :obsolete)

        if extra_include
          [:prefLabel, :definition, :synonym, :obsolete, :childrenCount].each do |x|
            extra_include.delete x
          end
        end

        load_children = []

        if extra_include
          load_children = extra_include.delete :children

          if load_children.nil?
            load_children = extra_include.select { |x| x.instance_of?(Hash) && x.include?(:children) }

            if load_children.length > 0
              extra_include = extra_include.select { |x| !(x.instance_of?(Hash) && x.include?(:children)) }
            end
          else
            load_children = [:children]
          end

          if extra_include.length > 0
            where.include(extra_include)
          end
        end
        where.all

        if load_children.length > 0
          LinkedData::Models::Class.partially_load_children(classes, 99, self)
        end

        classes.delete_if { |c|
          obs = !c.obsolete.nil? && c.obsolete == true
          c.load_has_children if extra_include&.include?(:hasChildren) && !obs
          obs
        }



          # LinkedData::Models::Class.sort_classes(classes)




      end

      def download_and_store_ontology_file
        file, filename = download_ontology_file
        file_location = self.class.copy_file_repository(self.ontology.acronym, self.submissionId, file, filename)
        self.uploadFilePath = file_location
        return file, filename
      end

      def remote_file_exists?(url)
        begin
          url = URI.parse(url)
          if url.kind_of?(URI::FTP)
            check = check_ftp_file(url)
          else
            check = check_http_file(url)
          end
        rescue Exception
          check = false
        end
        check
      end

      def download_ontology_file
        file, filename = LinkedData::Utils::FileHelpers.download_file(self.pullLocation.to_s)
        return file, filename
      end

      def delete_classes_graph
        Goo.sparql_data_client.delete_graph(self.id)
      end


      # def to_dataciteHash()
      #   begin
      #     # LOGGER.debug "\n\n ONTOLOGIES_LINKED_DATA - models/ontology_submission-> to_dataciteHash" 
      #     attr_hash = {}
      #     self.class.attributes.each do |key|
      #       value = self.instance_variable_get("@#{key}")
      #       case key.to_sym
      #       when :description,:version
      #         attr_hash[key.to_sym] = value unless value.nil?           
      #       when :creators,:titles
      #         attr_hash[key.to_sym] = [] if attr_hash[key.to_sym].nil?
      #         if !value.nil? && value.length>0
      #           value.each do |e|
      #             attr_hash[key.to_sym] << e.to_dataciteHash()
      #           end
      #         end
      #       end                
      #     end
      #     return attr_hash
      #   rescue => e
      #     LOGGER.debug "\n\nONTOLOGIES_LINKED_DATA - models/ontology_submission-> to_dataciteHash - ECCEZIONE: #{e.message}\n#{e.backtrace.join("\n")}"
      #     raise e        
      #   end
      # end

      private

      def delete_and_append(triples_file_path, logger, mime_type = nil)
        Goo.sparql_data_client.delete_graph(self.id)
        Goo.sparql_data_client.put_triples(self.id, triples_file_path, mime_type)
        logger.info("Triples #{triples_file_path} appended in #{self.id.to_ntriples}")
        logger.flush
      end

      def check_http_file(url)
        session = Net::HTTP.new(url.host, url.port)
        session.use_ssl = true if url.port == 443
        session.start do |http|
          response_valid = http.head(url.request_uri).code.to_i < 400
          return response_valid
        end
      end

      def check_ftp_file(uri)
        ftp = Net::FTP.new(uri.host, uri.user, uri.password)
        ftp.login
        begin
          file_exists = ftp.size(uri.path) > 0
        rescue Exception => e
          # Check using another method
          path = uri.path.split("/")
          filename = path.pop
          path = path.join("/")
          ftp.chdir(path)
          files = ftp.dir
          # Dumb check, just see if the filename is somewhere in the list
          files.each { |file| return true if file.include?(filename) }
        end
        file_exists
      end

      def self.loom_transform_literal(lit)
        res = []
        lit.each_char do |c|
          if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            res << c.downcase
          end
        end
        return res.join ''
      end

    end
  end
end
