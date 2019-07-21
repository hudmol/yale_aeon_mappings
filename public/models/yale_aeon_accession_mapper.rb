class YaleAeonAccessionMapper < AeonAccessionMapper

  register_for_record_type(Accession)

  def system_information
    mapped = super

    # Should ask that AUG update the Aeon database at the time this mapping goes into place.
    # If so, they'd just need to move over data from ItemInfo2 to EADNumber for the ArchivesSpace requests up until that date.
    mapped['EADNumber'] = mapped['ReturnLinkURL']

    # Site (repo_code)
    # handled by :site in config

    mapped
  end


  def record_fields
    mapped = super

    # DocumentType - from settings
    mapped['DocumentType'] = YaleAeonUtils.doc_type(self.repo_settings, mapped['collection_id'])

    # WebRequestForm - from settings
    mapped['WebRequestForm'] = YaleAeonUtils.web_request_form(self.repo_settings, mapped['collection_id'])

    # ItemDate (record.dates.final_expressions)
    mapped['ItemDate'] = self.record.dates.map {|d| d['final_expression']}.join(', ')

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

    # ItemInfo5 (access restriction notes)
    mapped['ItemInfo5'] = json['access_restrictions_note']

    # ItemInfo6 (use_restrictions_note)
    mapped['ItemInfo6'] = json['use_restrictions_note']

    # ItemInfo7 (extents)
    mapped['ItemInfo7'] = json['extents'].select {|e| !e.has_key?('_inherited')}
                                         .map {|e| "#{e['number']} #{e['extent_type']}"}.join('; ')

    # ItemAuthor (creators)
    # first agent, role='creator'
    creator = json['linked_agents'].select {|a| a['role'] == 'creator'}.first
    mapped['ItemAuthor'] = creator['_resolved']['title'] if creator

    mapped
  end

end
