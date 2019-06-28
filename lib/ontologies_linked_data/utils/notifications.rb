require 'cgi'
require 'pony'

module LinkedData::Utils
  class Notifications

   def self.notify(options = {})
      DEBUG_LOGGER.debug("Notifications: notify - begin")
      return unless LinkedData.settings.enable_notifications

      DEBUG_LOGGER.debug("LinkedData.settings.email_sender: #{LinkedData.settings.email_sender}")
      headers    = { 'Content-Type' => 'text/html' }
      sender     = options[:sender] || LinkedData.settings.email_sender
      recipients = options[:recipients]
      raise ArgumentError, "Recipient needs to be provided in options[:recipients]" if !recipients || recipients.empty?

      # By default we override all recipients to avoid
      # sending emails from testing environments.
      # Set `email_disable_override` in production
      # to send to the actual user.
      unless LinkedData.settings.email_disable_override
        headers['Overridden-Sender'] = recipients
        recipients = LinkedData.settings.email_override
      end

      begin
      	Pony.mail({
        	to: recipients,
	        from: sender,
	        subject: options[:subject],
	        body: options[:body],
	        headers: headers,
	        via: :smtp,
	        enable_starttls_auto: LinkedData.settings.enable_starttls_auto,
	        via_options: mail_options
	      })
        rescue Exception => e
          DEBUG_LOGGER.error(e.message)
          raise
      end
    end

    def self.new_note(note)
      note.bring_remaining
      note.creator.bring(:username) if note.creator.bring?(:username)
      note.relatedOntology.each {|o| o.bring(:name) if o.bring?(:name); o.bring(:subscriptions) if o.bring?(:subscriptions)}
      ontologies = note.relatedOntology.map {|o| o.name}.join(", ")
      subject = "[EcoPortal Notes] [#{ontologies}] #{note.subject}"
      body = NEW_NOTE.gsub("%username%", note.creator.username)
                     .gsub("%ontologies%", ontologies)
                     .gsub("%note_url%", LinkedData::Hypermedia.generate_links(note)["ui"])
                     .gsub("%note_subject%", note.subject || "")
                     .gsub("%note_body%", note.body || "")

      options = {
        ontologies: note.relatedOntology,
        notification_type: "NOTES",
        subject: subject,
        body: body
      }
      send_ontology_notifications(options)
    end

    def self.submission_processed(submission)
      submission.bring_remaining
      ontology = submission.ontology
      ontology.bring(:name, :acronym)
      result = submission.ready? ? "Success" : "Failure"
      status = LinkedData::Models::SubmissionStatus.readable_statuses(submission.submissionStatus)

      subject = "[EcoPortal] #{ontology.name} Parsing #{result}"
      body = SUBMISSION_PROCESSED.gsub("%ontology_name%", ontology.name)
                                 .gsub("%ontology_acronym%", ontology.acronym)
                                 .gsub("%statuses%", status.join("<br/>"))
                                 .gsub("%admin_email%", LinkedData.settings.email_sender)
                                 .gsub("%ontology_location%", LinkedData::Hypermedia.generate_links(ontology)["ui"])

      options = {
        ontologies: ontology,
        notification_type: "PROCESSING",
        subject: subject,
        body: body
      }
      send_ontology_notifications(options)
    end

    def self.remote_ontology_pull(submission)
      submission.bring_remaining
      ontology = submission.ontology
      ontology.bring(:name, :acronym, :administeredBy)

      subject = "[EcoPortal] Load from URL failure for #{ontology.name}"
      body = REMOTE_PULL_FAILURE.gsub("%ont_pull_location%", submission.pullLocation.to_s)
                                .gsub("%ont_name%", ontology.name)
                                .gsub("%ont_acronym%", ontology.acronym)
                                .gsub("%ontology_location%", LinkedData::Hypermedia.generate_links(ontology)["ui"])
      recipients = []
      ontology.administeredBy.each do |user|
        user.bring(:email) if user.bring?(:email)
        recipients << user.email
      end

      options = {
        subject: subject,
        body: body,
        recipients: recipients
      }
      notify(options)
    end

    def self.reset_password(user, token)
      DEBUG_LOGGER.debug("reset_password: {username: #{user.username}, user_email: #{user.email}}")
      subject = "[EcoPortal] User #{user.username} password reset"
      password_url = "#{LinkedData.settings.ui_host}/reset_password?tk=#{token}&em=#{CGI.escape(user.email)}&un=#{CGI.escape(user.username)}"
      body = <<-EOS
Someone has requested a password reset for user #{user.username}. If this was you, please click on the link below to reset your password. Otherwise, please ignore this email.<br/><br/>
<a href="#{password_url}">#{password_url}</a><br/><br/>
Thanks,<br/>
EcoPortal Team
      EOS
      options = {
        subject: subject,
        body: body,
        recipients: user.email
      }
      notify(options)
    end

    def self.obofoundry_sync(missing_ontologies)
      body = "There are no OBO Library ontologies missing from EcoPortal."

      if missing_ontologies.size > 0
        body = "The following OBO Library ontologies are missing from EcoPortal:<br/><br/>"
        missing_ontologies.each do |ont|
          body << "<a href='#{ont['homepage']}'>#{ont['id']}</a> (#{ont['title']})<br/><br/>"
        end
      end

      options = {
        subject: "[EcoPortal] OBOFoundry synchronization report",
        body: body,
        recipients: LinkedData.settings.email_sender
      }
      notify(options)
    end

    private

    ##
    # This method takes a list of ontologies and a notification type,
    # then looks up all the users who subscribe to that ontology/type pair
    # and sends them an email with the given subject and body.
    def self.send_ontology_notifications(options = {})
      ontologies        = options[:ontologies]
      ontologies        = ontologies.is_a?(Array) ? ontologies : [ontologies]
      notification_type = options[:notification_type]
      subject           = options[:subject]
      body              = options[:body]
      emails            = []
      ontologies.each {|o| o.bring(:subscriptions) if o.bring?(:subscriptions)}
      ontologies.each do |ont|
        ont.subscriptions.each do |subscription|
          subscription.bring(:notification_type) if subscription.bring?(:notification_type)
          subscription.notification_type.bring(:type) if subscription.notification_type.bring?(:notification_type)
          next unless subscription.notification_type.type.eql?(notification_type.to_s.upcase) || subscription.notification_type.type.eql?("ALL")
          subscription.bring(:user) if subscription.bring?(:user)
          subscription.user.each do |user|
            user.bring(:email) if user.bring?(:email)
            emails << notify(recipients: user.email, subject: subject, body: body)
          end
        end
      end
      emails
    end

    def self.mail_options
      options = {
        address: LinkedData.settings.smtp_host,
        port:    LinkedData.settings.smtp_port,
        domain:  LinkedData.settings.smtp_domain # the HELO domain provided by the client to the server
      }

      DEBUG_LOGGER.debug("LinkedData.settings.smtp_auth_type: #{LinkedData.settings.smtp_auth_type}")
      if LinkedData.settings.smtp_auth_type && LinkedData.settings.smtp_auth_type != :none
        DEBUG_LOGGER.debug("LinkedData.settings.smtp_user: #{LinkedData.settings.smtp_user},  LinkedData.settings.smtp_password: #{LinkedData.settings.smtp_password}")
        options = options.merge({
          user_name:      LinkedData.settings.smtp_user,
          password:       LinkedData.settings.smtp_password,
          authentication: LinkedData.settings.smtp_auth_type
        })
      end
      #DEBUG_LOGGER.debug("mail_options: {host: #{options[:address]}, port: #{options[:port]}, authentication: #{options[:authentication]}, username: #{options[:user_name]}}")
      return options
    end

NEW_NOTE = <<EOS
A new note was added to %ontologies% by <b>%username%</b>.<br/><br/>

----------------------------------------------------------------------------------<br/>
<b>Subject:</b> %note_subject%<br/><br/>

%note_body%<br/>
----------------------------------------------------------------------------------<br/><br/>

You can respond by visiting: <a href="%note_url%">LifeWatch Eric EcoPortal</a>.<br/><br/>
EOS

SUBMISSION_PROCESSED = <<EOS
%ontology_name% (%ontology_acronym%) was processed for use in EcoPortal. Here are the results:
<br><br>
%statuses%
<br><br>
Please contact %admin_email% if you have questions.
<br><br>
The ontology can be <a href="%ontology_location%">browsed in EcoPortal</a>.
<br><br>
Thank you,<br>
The EcoPortal Team
EOS

REMOTE_PULL_FAILURE = <<EOS
EcoPortal failed to load %ont_name% (%ont_acronym%) from URL: %ont_pull_location%.
<br><br>
Please verify the URL you provided for daily loading of your ontology:
<ol>
<li>Make sure you are signed in to EcoPortal.</li>
<li>Navigate to your ontology summary page: %ontology_location%.</li>
<li>Click the &quot;Edit submission information&quot; link.</li>
<li>In the Location row, verify that you entered a valid URL for daily loading of your ontology in the URL text area.</li>
</ol>
If you need further assistance, please <a href="mailto:support@bioontology.org">contact us</a> via the EcoPortal support mailing list.
<br><br>
Thank you,<br>
The EcoPortal Team
EOS

  end
end
