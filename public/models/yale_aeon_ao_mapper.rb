class YaleAeonAOMapper < AeonArchivalObjectMapper

  register_for_record_type(ArchivalObject)

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
    # handled in super?  maybe not for bulk requests
    #we're now mapping collection title to ItemTitle. Keep an eye out on that mapping, and also see about updating the Aeon merge feature, since the ItemTitle field is the only field retained in a merge.
    mapped['ItemTitle'] = mapped['collection_title']

    # DocumentType - from settings
    mapped['DocumentType'] = YaleAeonUtils.doc_type(self.repo_settings, mapped['collection_id'])

    # WebRequestForm - from settings
    mapped['WebRequestForm'] = YaleAeonUtils.web_request_form(self.repo_settings, mapped['collection_id'])

    # ItemSubTitle (record.request_item.hierarchy)
    #mapped['ItemSubTitle'] = strip_mixed_content(self.record.request_item.hierarchy.join(' / '))
    mapped['ItemSubTitle'] = mapped['title']

    # ItemCitation (record.request_item.cite if blank)
    mapped['ItemCitation'] ||= self.record.request_item.cite

    # ItemDate (record.dates.final_expressions)
    mapped['ItemDate'] = self.record.dates.map {|d| d['final_expression']}.join(', ')

    # no longer mapping collection title here. leaving this as example to show how the hierarchical title was grabbed previously.
    #mapped['ItemInfo12'] = strip_mixed_content(self.record.request_item.hierarchy.join(' / '))

    # ItemInfo13: including the component unique identifier field
    mapped['ItemInfo13'] = mapped['component_id']

    # Append external_ids with source = 'local_surrogate_call_number' to 'collection_id'
    self.record.json['external_ids'].select{|ei| ei['source'] == 'local_surrogate_call_number'}.map do |ei|
      mapped['collection_id'] += '; ' + ei['external_id']
    end

    StatusUpdater.update('Yale Aeon Last Request', :good, "Mapped: #{mapped['uri']}")

    mapped
  end


  def json_fields
    mapped = super

    json = self.record.json
    if !json
      return mapped
    end

    # These apply to all requests because their data comes from the ao

    # EADNumber (resource.ref)
    mapped['EADNumber'] = json['resource']['ref']

    # ItemCitation (preferred citation note)
    mapped['ItemCitation'] = json['notes'].select {|n| n['type'] == 'prefercite'}
                                          .map {|n| n['subnotes'].map {|s| s['content']}.join(' ')}
                                          .join(' ')

    # ItemAuthor (creators)
    # first agent, role='creator'
    creator = json['linked_agents'].select {|a| a['role'] == 'creator'}.first
    mapped['ItemAuthor'] = creator['_resolved']['title'] if creator

    # ItemInfo5 (access restriction notes)
    mapped['ItemInfo5'] = json['notes'].select {|n| n['type'] == 'accessrestrict'}
                                       .map {|n| n['subnotes'].map {|s| s['content']}.join(' ')}
                                       .join(' ')

    # ItemInfo6 (use_restrictions_note)
    mapped['ItemInfo6'] = json['notes'].select {|n| n['type'] == 'userestrict'}
                                       .map {|n| n['subnotes'].map {|s| s['content']}.join(' ')}
                                       .join(' ')

    # ItemInfo7 (extents)
    mapped['ItemInfo7'] = json['extents'].select {|e| !e.has_key?('_inherited')}
                                         .map {|e| "#{e['number']} #{e['extent_type']}"}.join('; ')

    # ItemInfo8 (access restriction types)
    mapped['ItemInfo8'] = json['notes'].select {|n| n['type'] == 'accessrestrict' && n.has_key?('rights_restriction')}
                         .map {|n| n['rights_restriction']['local_access_restriction_type']}
                         .flatten.uniq.join(' ')

    # The remainder are per request fields

    # ItemInfo1 (y/n overview for restrictions; going with the ASpace-defined version of restricted; note, though, that the Aeon plugin didn't need to split these values out for multiple containers.)
    map_request_values(mapped, 'instance_top_container_restricted', 'ItemInfo1') do |r|
      r == true ? 'Y' : 'N'
    end

    # ItemInfo10 (top_container uri)
    map_request_values(mapped, 'instance_top_container_uri', 'ItemInfo10')

    # ItemVolume (top_containers type + indicator)
    # need to add "Box" if missing? we're going to add the data to the source for now. might want to revist that.
    map_request_values(mapped, 'instance_top_container_display_string', 'ItemVolume') {|v| v[0, (v.index(':') || v.length)]}

    #new for folders (only right now).... concat 2 fields.... clean this up.
    map_request_values(mapped, 'instance_container_child_indicator', 'ItemEdition') do |v|
      valid_types = ['Folder', 'folder']
      folder = json['instances'].select {|i| i.has_key?('sub_container') && i['sub_container'].has_key?('top_container')}
                            .map {|i| i['sub_container']}.select {|i| valid_types.include?(i['type_2'])}
                            .map {|i| i['type_2'] << ':::' << i['indicator_2']}
      folder ? folder : ''
    end
    # lame to do this a second time, but it works now that i've changed the strings above...
    # and here, we just take those types that start with "folder:::", and pass on the indicator that's after the "folder:::" bit.
    map_request_values(mapped, 'instance_container_child_type', 'ItemEdition') do |v|
      if v.downcase.include? 'folder:::'
        v.downcase.sub(/folder:::/, '')
      else
        ''
      end
    end

    #ItemIssue
    #(instance_top_container_series_identifier + instance_top_container_series_display_string)
    # also need series_level_display_string ?
    # check and see if we need to convert the identifiers to roman numerals.  e.g. 1 -> I, but keeping other things as is like "accession 2018 etc"
    map_request_values(mapped, 'instance_top_container_uri', 'ItemIssue') do |uri|
      tc = JSON.parse(self.record.raw['_resolved_top_container_uri_u_sstr'][uri].first['json'])

      if tc
        series_info = []
        series_info += tc['series'].select {|i| i['identifier'].present? }
        .map {|i| i['level_display_string'] + ' ' + i['identifier'] + '. ' + i['display_string']}

        series = []
        series = series_info.join('; ')
      else
        ''
      end
    end

    # ReferenceNumber (top_container barcode)
    map_request_values(mapped, 'instance_top_container_barcode', 'ReferenceNumber')

    # Location (location uris)
    # there is an open_url mapping on the aeon side that is blatting this
    # with the value in instance_top_container_long_display_string
    # so below, we blat the blatter!
    #
    # now:
    # Location
    # ItemInfo11 (location uri)
    map_request_values(mapped, 'instance_top_container_uri', 'ItemInfo11') do |v|
      tc = json['instances'].select {|i| i.has_key?('sub_container') && i['sub_container'].has_key?('top_container')}
                            .map {|i| i['sub_container']['top_container']['_resolved']}
                            .select {|t| t['uri'] == v}.first

      if tc
        loc = tc['container_locations'].select {|l| l['status'] == 'current'}.first
        loc ? loc['ref'] : ''
      else
        ''
      end
    end
    map_request_values(mapped, 'instance_top_container_uri', 'Location') do |v|
      tc = JSON.parse(self.record.raw['_resolved_top_container_uri_u_sstr'][v].first['json'])

      if tc
        loc = tc['container_locations'].select {|l| l['status'] == 'current'}.first
        if loc
          loc['_resolved']['title']
        else
          ''
        end
      else
        ''
      end
    end

    #mdc: and now we map SubLocations to accomodate previously-instituted mappings for container profiles.
    map_request_values(mapped, 'instance_top_container_uri', 'SubLocation') do |v|
      tc = json['instances'].select {|i| i.has_key?('sub_container') && i['sub_container'].has_key?('top_container')}
                            .map {|i| i['sub_container']['top_container']['_resolved']}
                            .select {|t| t['uri'] == v}.first
      if tc
        cp = tc.dig('container_profile', '_resolved', 'name') || ''
      else
        ''
      end
    end

    # blat the blatter
    map_request_values(mapped, 'Location', 'instance_top_container_long_display_string')

    mapped
  end


  def map_request_values(mapped, from, to, &block)
    mapped['requests'].each do |r|
      ix = r['Request']
      new_val = yield r["#{from}_#{ix}"] if block_given?
      r["#{to}_#{ix}"] = new_val || r["#{from}_#{ix}"]
    end
  end

end
