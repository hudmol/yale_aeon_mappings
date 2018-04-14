class YaleAeonAOMapper < AeonArchivalObjectMapper

    register_for_record_type(ArchivalObject)

    def record_fields
        mappings = super

#        mappings['title'] = 'WEEEEEE'

        mappings
    end
end
