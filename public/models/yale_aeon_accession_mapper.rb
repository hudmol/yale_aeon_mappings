class YaleAeonAccessionMapper < AeonAccessionMapper

  register_for_record_type(Accession)

  def record_fields
    mappings = super

    mappings
  end

  def json_fields
    mappings = super

    json = self.record.json
    if !json
      return mappings
    end

    # ItemInfo2 (url)
    # required?

    # Site (repo_code)
    # needs openurl mapping?

    # ItemTitle (title)
    # done?

    # CallNumber (collection_id)
    mappings['collection_id'] = [0,1,2,3].map {|n| json["id_#{n}"]}.join(' ')
    if json.has_key?('user_defined')
      mappings['collection_id'] += ' ' + json['user_defined']['text_1'] if json['user_defined']['text_1']
    end

    # ItemInfo6 (access_restrictions_note)
    # needs openurl mapping?

    # ItemInfo4 (use_restrictions_note)
    # needs openurl mapping?

    # ItemDate (dates)
    # done?

    # ItemInfo5 (extents)
    # needs openurl mapping?

    # ItemAuthor (creators)
    # first agent, role='creator'


    mappings
  end

end
