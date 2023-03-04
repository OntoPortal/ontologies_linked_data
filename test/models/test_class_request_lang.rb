require_relative './test_ontology_common'

class TestClassMainLang < LinkedData::TestOntologyCommon

  def self.after_suite
    Goo.requested_language = nil
  end

  def test_requested_language_found

    parse

    cls = get_class_by_lang('http://opendata.inrae.fr/thesaurusINRAE/c_22817',
                            requested_lang: :FR, portal_languages: %i[EN FR ES])
    assert_equal 'industrialisation', cls.prefLabel
    assert_equal ['développement industriel'], cls.synonym

    properties = cls.properties
    assert_equal ['développement industriel'], properties.select { |x| x.to_s['altLabel'] }.values.first.map(&:to_s)
    assert_equal ['industrialisation'], properties.select { |x| x.to_s['prefLabel'] }.values.first.map(&:to_s)

    cls = get_class_by_lang('http://opendata.inrae.fr/thesaurusINRAE/c_22817',
                            requested_lang: :EN, portal_languages: %i[FR EN ES])
    assert_equal 'industrialization', cls.prefLabel
    assert_equal ['industrial development'], cls.synonym

    properties = cls.properties
    assert_equal ['industrial development'], properties.select { |x| x.to_s['altLabel'] }.values.first.map(&:to_s)
    assert_equal ['industrialization'], properties.select { |x| x.to_s['prefLabel'] }.values.first.map(&:to_s)

  end

  def test_requested_language_not_found
    parse

    cls = get_class_by_lang('http://opendata.inrae.fr/thesaurusINRAE/c_22817',
                            requested_lang: :ES, portal_languages: %i[EN FR ES])
    assert_nil cls.prefLabel
    assert_empty cls.synonym

    properties = cls.properties
    assert_empty properties.select { |x| x.to_s['altLabel'] }.values
    assert_empty properties.select { |x| x.to_s['prefLabel'] }.values

  end

  private

  def parse
    submission_parse('INRAETHES', 'Testing skos',
                     'test/data/ontology_files/thesaurusINRAE_nouv_structure.skos',
                     1,
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: false)
  end

  def lang_set(requested_lang: nil, portal_languages: nil)
    Goo.main_languages = portal_languages if portal_languages
    Goo.requested_language = requested_lang
  end

  def get_class(cls, ont)
    sub = LinkedData::Models::Ontology.find(ont).first.latest_submission
    LinkedData::Models::Class.find(cls).in(sub).first
  end

  def get_class_by_lang(cls, requested_lang:, portal_languages: [])
    lang_set requested_lang: requested_lang, portal_languages: portal_languages
    cls = get_class(cls, 'INRAETHES')
    refute_nil cls
    cls.bring_remaining
    cls.bring :unmapped
    cls
  end
end