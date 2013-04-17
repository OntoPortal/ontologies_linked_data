module LinkedData
  module SampleData
    class Ontology

      ##
      # Creates a set of Ontology and OntologySubmission objects and stores them in the triplestore
      # @param [Hash] options the options to create ontologies with
      # @option options [Fixnum] :ont_count Number of ontologies to create
      # @option options [Fixnum] :submission_count How many submissions each ontology should have (acts as max number when random submission count is used)
      # @option options [Fixnum] :submissions_to_process Which submission ids to parse
      # @option options [TrueClass, FalseClass] :random_submission_count Use a random number of submissions between 1 and :submission_count
      # @option options [TrueClass, FalseClass] :process_submission Parse the test ontology file
      def self.create_ontologies_and_submissions(options = {})
        # Default options
        ont_count = options[:ont_count] || 5
        submission_count = options[:submission_count] || 5
        random_submission_count = options[:random_submission_count] || false
        process_submission = options[:process_submission] || false
        submissions_to_process = options[:submissions_to_process]
        acronym = options[:acronym] || "TEST-ONT"
        name = options[:name]
        file_path = options[:file_path]

        # If ontology exists and is parsed (when requested), return it here
        if acronym
          ont = LinkedData::Models::Ontology.find(acronym)
          if ont && process_submission
            subs = ont.submissions
            subs.each do |sub|
              return 1, [acronym], [ont] if sub.submissionStatus.parsed?
            end
          elsif ont
            return 1, [acronym], [ont]
          end
        end

        u, of, contact = ontology_objects()

        ont_acronyms = []
        ontologies = []
        ont_count.to_i.times do |count|
          acr_suffix = ont_count > 1 ? "-#{count}" : ""
          acronym = "#{acronym}#{acr_suffix}"
          ont_acronyms << acronym

          o = LinkedData::Models::Ontology.new({
            acronym: acronym,
            name: "Test Ontology ##{count}",
            administeredBy: u
          })

          o.save unless o.exist?

          # Random submissions (between 1 and max)
          max = random_submission_count ? (1..submission_count.to_i).to_a.shuffle.first : submission_count
          max.times do
            os = LinkedData::Models::OntologySubmission.new({
              ontology: o,
              hasOntologyLanguage: of,
              submissionStatus: LinkedData::Models::SubmissionStatus.find("UPLOADED"),
              submissionId: o.next_submission_id,
              definitionProperty: (RDF::IRI.new "http://bioontology.org/ontologies/biositemap.owl#definition"),
              summaryOnly: true,
              contact: contact,
              released: DateTime.now - 3
            })

            if process_submission && (submissions_to_process.nil? || submissions_to_process.include?(os.submissionId))
              file_path ||= "../../../../test/data/ontology_files/BRO_v3.#{os.submissionId}.owl"
              file_path = File.expand_path(file_path, __FILE__)
              raise ArgumentError, "File located at #{file_path} does not exist" unless File.exist?(file_path)
              if os.submissionId > 2
                raise ArgumentError, "create_ontologies_and_submissions does not support process submission with more than 2 versions"
              end
              uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(o.acronym, os.submissionId, file_path)
              os.uploadFilePath = uploadFilePath
            else
              os.summaryOnly = true
            end

            os.save unless os.exist?
          end
        end

        # Get ontology objects if empty
        ont_acronyms.each do |ont_id|
          ontologies << LinkedData::Models::Ontology.find(ont_id)
        end

        if process_submission
          ontologies.each do |o|
            o.submissions.each do |ss|
              next if (!submissions_to_process.nil? && !submissions_to_process.include?(ss.submissionId))
              ss.process_submission Logger.new(STDOUT)
            end
          end
        end

        return ont_count, ont_acronyms, ontologies
      end

      def self.ontology_objects
        LinkedData::Models::SubmissionStatus.init

        u = LinkedData::Models::User.new(username: "tim", email: "tim@example.org", password: "password")
        if u.exist?
          u = LinkedData::Models::User.find("tim")
        else
          u.save
        end

        of = LinkedData::Models::OntologyFormat.new(acronym: "OWL")
        if of.exist?
          of = LinkedData::Models::OntologyFormat.find("OWL")
        else
          of.save
        end

        contact_name = "Sheila"
        contact_email = "sheila@example.org"
        contact = LinkedData::Models::Contact.where(name: contact_name, email: contact_email)
        contact = contact.empty? ? LinkedData::Models::Contact.new(name: contact_name, email: contact_email) : contact.first

        return u, of, contact
      end

      ##
      # Delete all ontologies and their submissions. This will look for all ontologies starting with TST-ONT- and ending in a Fixnum
      def self.delete_ontologies_and_submissions
        LinkedData::Models::Ontology.all.each do |ont|
          ont.delete
        end

        u = LinkedData::Models::User.find("tim")
        u.delete unless u.nil?

        of = LinkedData::Models::OntologyFormat.find("OWL")
        of.delete unless of.nil?
      end

      def self.sample_owl_ontologies
        count, acronyms, bro = create_ontologies_and_submissions({
          process_submission: true,
          acronym: "BROTEST",
          name: "ontTEST Bla",
          file_path: "../../../../test/data/ontology_files/BRO_v3.2.owl",
          ont_count: 1,
          submission_count: 1
        })

        # This one has some nasty looking IRIS with slashes in the anchor
        count, acronyms, mccl = create_ontologies_and_submissions({
          process_submission: true,
          acronym: "MCCLTEST",
          name: "MCCLS TEST",
          file_path: "../../../../test/data/ontology_files/CellLine_OWL_BioPortal_v1.0.owl",
          ont_count: 1,
          submission_count: 1
        })

        # This one has resources wih accents.
        count, acronyms, onto_matest = create_ontologies_and_submissions({
          process_submission: true,
          acronym: "OntoMATEST",
          name: "OntoMA TEST",
          file_path: "../../../../test/data/ontology_files/OntoMA.1.1_vVersion_1.1_Date__11-2011.OWL",
          ont_count: 1,
          submission_count: 1
        })

        return bro.concat(mccl).concat(onto_matest)
      end

    end
  end
end