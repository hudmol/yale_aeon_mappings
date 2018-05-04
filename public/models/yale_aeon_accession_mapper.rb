class YaleAeonAccessionMapper < AeonAccessionMapper

  register_for_record_type(Accession)

  def system_information
    mapped = super

    # ItemInfo2 (url)
    mapped['ItemInfo2'] = mapped['ReturnLinkURL']

    # Site (repo_code)
    # handled by :site in config

    mapped
  end


  def record_fields
    mapped = super

    # ItemTitle (title)
    # done?

    mapped
  end

  def json_fields
    mapped = super

    json = self.record.json
    if !json
      return mapped
    end

    # CallNumber (collection_id)
    mapped['collection_id'] = [0,1,2,3].map {|n| json["id_#{n}"]}.join(' ')
    if json.has_key?('user_defined')
      mapped['collection_id'] += '; ' + json['user_defined']['text_1'] if json['user_defined']['text_1']
    end

    # ItemInfo6 (access restriction notes)
    mapped['ItemInfo6'] = json['access_restrictions_note']

    # ItemInfo4 (use_restrictions_note)
    mapped['ItemInfo4'] = json['use_restrictions_note']

    # ItemDate (dates)
    # handles in super?

    # ItemInfo5 (extents)
    mapped['ItemInfo5'] = json['extents'].select {|e| !e.has_key?('_inherited')}
                                         .map {|e| "#{e['number']} #{e['extent_type']}"}.join('; ')

    # ItemAuthor (creators)
    # first agent, role='creator'
    creator = json['linked_agents'].select {|a| a['role'] == 'creator'}.first
    mapped['ItemAuthor'] = creator['_resolved']['title'] if creator

    mapped
  end

end
