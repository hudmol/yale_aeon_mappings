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
    # handled in super?

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

    # ItemSubTitle (request hierarchy?)
    # not sure how this should look

    # ItemInfo6 (access restriction notes)
    mapped['ItemInfo6'] = json['notes'].select {|n| n['type'] == 'accessrestrict'}
                                       .map {|n| n['subnotes'].map {|s| s['content']}.join(' ')}
                                       .join(' ')

    # ItemInfo4 (use_restrictions_note)
    mapped['ItemInfo4'] = json['notes'].select {|n| n['type'] == 'userestrict'}
                                       .map {|n| n['subnotes'].map {|s| s['content']}.join(' ')}
                                       .join(' ')

    # ItemAuthor (creators)
    # first agent, role='creator'
    creator = json['linked_agents'].select {|a| a['role'] == 'creator'}.first
    mapped['ItemAuthor'] = creator['_resolved']['title'] if creator

    # ItemInfo8 (access restriction types)
    mapped['ItemInfo8'] = json['notes'].select {|n| n['type'] == 'accessrestrict' && n.has_key?('rights_restriction')}
                         .map {|n| n['rights_restriction']['local_access_restriction_type']}
                         .flatten.uniq.join(' ')

    # ItemInfo5 (extents)
    mapped['ItemInfo5'] = json['extents'].select {|e| !e.has_key?('_inherited')}
                                         .map {|e| "#{e['number']} #{e['extent_type']}"}.join('; ')



    # The remainder are per request fields

    # ItemInfo10 (top_container uri)
    map_request_values(mapped, 'instance_top_container_uri', 'ItemInfo10')

    # ItemVolume (top_containers type + indicator)
    map_request_values(mapped, 'instance_top_container_display_string', 'ItemVolume') {|v| v[0, v.index(':')]}

    # ReferenceNumber (top_container barcode)
    map_request_values(mapped, 'instance_top_container_barcode', 'ReferenceNumber')

    # Location (location uris)
    # there is an open_url mapping on the aeon side that is blatting this
    # with the value in instance_top_container_long_display_string
    # so below, we blat the blatter!
    #
    # now:
    # Location (location building)
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
      tc = json['instances'].select {|i| i.has_key?('sub_container') && i['sub_container'].has_key?('top_container')}
                            .map {|i| i['sub_container']['top_container']['_resolved']}
                            .select {|t| t['uri'] == v}.first

      if tc
        loc = tc['container_locations'].select {|l| l['status'] == 'current'}.first
        if loc
          self.record.resolved_top_container['container_locations'].select {|cl| cl['ref'] == loc['ref']}
                                                                   .map {|cl| cl['_resolved']['building']}.first
        else
          ''
        end
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
