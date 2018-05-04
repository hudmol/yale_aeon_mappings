class YaleAeonContainerMapper < AeonRecordMapper

    register_for_record_type(Container)

    def initialize(record)
      super

      @record.json['notes'] = @record.json['active_restrictions'].map {|a| a['linked_records']['_resolved']['notes']}.flatten
    end


  def system_information
    mapped = super

    # ItemInfo2 (url)
    mapped['ItemInfo2'] = mapped['ReturnLinkURL']

    # Site (repo_code)
    # handled by :site in config

    mapped
  end


    def record_fields
      mappings = {}

      resolved_repository = self.record.resolved_repository
      if resolved_repository
        mappings['repo_code'] = resolved_repository['repo_code']
        mappings['repo_name'] = resolved_repository['name']
      end

      mappings
    end


    def json_fields
      mappings = {}

      json = self.record.json
      if !json
        return mappings
      end

      if json['collection'][0]
        mappings['collection_id'] = json['collection'][0]['identifier']
        mappings['collection_title'] = json['collection'][0]['display_string']
      end

      # CallNumber (collection.identifiers)
      mappings['CallNumber'] = json['collection'].map {|c| c['identifier']}.join(' ;')

      # EADNumber (collection.refs)
      mappings['EADNumber'] = json['collection'].map {|c| c['ref']}.join(' ;')

      # pulling record data from the first series
      if json['series'][0]
        mappings['identifier'] = json['series'][0]['identifier']
        mappings['publish'] = json['series'][0]['publish']
        mappings['level'] = json['series'][0]['level_display_string']
        mappings['title'] = strip_mixed_content(json['series'][0]['display_string'])
        mappings['uri'] = json['series'][0]['ref']
      end

      mappings['display_string'] = mappings['title']

      request = {}
      request['Request'] = '1'

      request["instance_top_container_ref_1"] = json['uri']
      request["instance_top_container_long_display_string_1"] = json['long_display_string']
      request["instance_top_container_last_modified_by_1"] = json['last_modified_by']
      request["instance_top_container_display_string_1"] = json['display_string']
      request["instance_top_container_restricted_1"] = json['restricted']
      request["instance_top_container_created_by_1"] = json['created_by']
      request["instance_top_container_indicator_1"] = json['indicator']
      request["instance_top_container_barcode_1"] = json['barcode']
      request["instance_top_container_type_1"] = json['type']
      request["instance_top_container_uri_1"] = json['uri']

      collection = json['collection']
      if collection
        request["instance_top_container_collection_identifier_1"] = collection
          .select { |c| c['identifier'].present? }
          .map { |c| c['identifier'] }
          .join("; ")

        request["instance_top_container_collection_display_string_1"] = collection
          .select { |c| c['display_string'].present? }
          .map { |c| c['display_string'] }
          .join("; ")
      end

      series = json['series']
      if series
        request["instance_top_container_series_identifier_1"] = series
          .select { |s| s['identifier'].present? }
          .map { |s| s['identifier'] }
          .join("; ")

        request["instance_top_container_series_display_string_1"] = series
          .select { |s| s['display_string'].present? }
          .map { |s| s['display_string'] }
          .join("; ")
      end


      loc = json['container_locations'].select {|cl| cl['status'] == 'current'}.first
      if (loc)
        # Location (location building)
        request["Location_1"] = loc['_resolved']['building']
        request['instance_top_container_long_display_string_1'] = request['Location_1']
        # ItemInfo11 (location uri)
        request["ItemInfo11"] = loc['ref']
      end

      mappings['requests'] = [request]

      mappings
    end

end
